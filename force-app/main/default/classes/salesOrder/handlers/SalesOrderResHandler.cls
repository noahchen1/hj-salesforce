public with sharing class SalesOrderResHandler {
  public static String handleApiResponse(Map<String, Object> response) {
    if (response == null) {
      throw new AuraHandledException('No response returned from NetSuite.');
    }

    Boolean validRequest = (Boolean) response.get('validRequest');
    if (validRequest == null || !validRequest) {
      throw new AuraHandledException(
        'Invalid request: NetSuite rejected the payload.'
      );
    }

    String responseJsonStr = (String) response.get('responseJSON');
    if (String.isBlank(responseJsonStr)) {
      throw new AuraHandledException(
        'NetSuite returned an empty response body.'
      );
    }

    Map<String, Object> responseBody;
    try {
      responseBody = (Map<String, Object>) JSON.deserializeUntyped(
        responseJsonStr
      );
    } catch (Exception e) {
      throw new AuraHandledException('Unable to parse NetSuite response.');
    }

    List<Object> errors = (List<Object>) responseBody.get('errors');
    if (errors != null && !errors.isEmpty()) {
      String errorMsg = JSON.serialize(errors);

      System.debug(
        LoggingLevel.ERROR,
        'SoService.saveSalesOrder NetSuite errors: ' + errorMsg
      );

      throw new AuraHandledException('Order creation failed: ' + errorMsg);
    }

    String status = String.valueOf(responseBody.get('status'));
    if (status != '200') {
      throw new AuraHandledException('Unexpected response status: ' + status);
    }

    List<Object> salesOrders = (List<Object>) responseBody.get('salesOrders');
    if (salesOrders != null && !salesOrders.isEmpty()) {
      Map<String, Object> createdOrder = (Map<String, Object>) salesOrders[0];
      String tranId = String.valueOf(createdOrder.get('tranId'));
      String internalId = String.valueOf(createdOrder.get('internalId'));

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder created order: ' +
          tranId +
          ' internalId: ' +
          internalId
      );

      return internalId;
    }

    throw new AuraHandledException('No sales order returned in response.');
  }

  public static SalesOrderDataModel.SalesOrderData handleReadResponse(
    Map<String, Object> resp
  ) {
    if (resp == null) {
      throw new AuraHandledException('No response returned from NetSuite.');
    }

    Object rawResponseJson = resp.get('responseJSON');
    String responseJsonStr = rawResponseJson instanceof String
      ? (String) rawResponseJson
      : JSON.serialize(rawResponseJson);

    SalesOrderResModel.ResponseJson response = (SalesOrderResModel.ResponseJson) JSON.deserialize(
      responseJsonStr,
      SalesOrderResModel.ResponseJson.class
    );

    System.debug('Parsed Response: ' + response);

    if (response == null) {
      throw new AuraHandledException('Unable to parse NetSuite response.');
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      throw new AuraHandledException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );
    }

    if (response.status != '200') {
      throw new AuraHandledException(
        'Unexpected response status: ' + response.status
      );
    }

    if (response.salesOrders == null || response.salesOrders.isEmpty()) {
      throw new AuraHandledException('No sales order returned in response.');
    }

    SalesOrderResModel.SalesOrder so = response.salesOrders[0];
    SalesOrderDataModel.SalesOrderData result = new SalesOrderDataModel.SalesOrderData();

    result.internalId = so.internalId;
    result.customerName = so.entity == null ? null : so.entity.name;
    result.customerNsId = so.entity == null ? null : so.entity.internalId;
    result.orderDate = Helpers.toDateOnlyFromUnixSeconds(so.tranDate);
    result.memo = so.memo;
    result.salesRep1Name = so.salesRep == null ? null : so.salesRep.name;
    result.salesRep1NsId = so.salesRep == null ? null : so.salesRep.internalId;
    result.subsidiaryNsId = so.subsidiary == null
      ? null
      : so.subsidiary.internalId;
    result.locationNsId = so.location == null ? null : so.location.internalId;

    String salesRep2Name;
    String salesRep2NsId;

    if (so.customFieldList != null && so.customFieldList.customField != null) {
      for (SalesOrderResModel.CustomField cf : so.customFieldList.customField) {
        if (cf != null && cf.scriptId == 'custbody_salesrep2') {
          salesRep2Name = cf.valueLookup == null
            ? cf.value
            : cf.valueLookup.name;
          salesRep2NsId = cf.valueLookup == null
            ? null
            : cf.valueLookup.internalId;
          break;
        }
      }
    }

    result.salesRep2Name = salesRep2Name;
    result.salesRep2NsId = salesRep2NsId;

    Map<String, String> itemNamesByInternalId = new Map<String, String>();
    Set<String> itemInternalIds = new Set<String>();
    if (so.itemList != null && so.itemList.item != null) {
      for (SalesOrderResModel.SalesOrderItem it : so.itemList.item) {
        if (
          it != null &&
          it.item != null &&
          String.isNotBlank(it.item.internalId)
        ) {
          itemInternalIds.add(it.item.internalId);
        }
      }
    }

    if (!itemInternalIds.isEmpty()) {
      for (breadwinner_ns__BW_Item__c itemRow : [
        SELECT Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE breadwinner_ns__InternalId__c IN :itemInternalIds
      ]) {
        itemNamesByInternalId.put(
          itemRow.breadwinner_ns__InternalId__c,
          itemRow.Name
        );
      }
    }

    Integer rowNum = 1;
    if (so.itemList != null && so.itemList.item != null) {
      for (SalesOrderResModel.SalesOrderItem it : so.itemList.item) {
        if (it == null) {
          continue;
        }

        SalesOrderDataModel.LineItem dto = new SalesOrderDataModel.LineItem();
        dto.id = rowNum;
        dto.item = it.item == null ? null : it.item.internalId;
        dto.itemName = dto.item == null
          ? null
          : itemNamesByInternalId.get(dto.item);
        dto.quantity = it.quantity == null ? null : String.valueOf(it.quantity);
        dto.rate = it.rate;
        dto.amount = it.amount == null ? null : String.valueOf(it.amount);
        dto.line = it.line == null ? null : it.line;

        result.lineItems.add(dto);
        rowNum++;
      }
    }

    if (so.shippingAddress != null) {
      result.shippingAddress = new SalesOrderDataModel.Address();
      result.shippingAddress.zip = so.shippingAddress.zip;
      result.shippingAddress.state = so.shippingAddress.state;
      result.shippingAddress.internalId = so.shippingAddress.internalId;
      result.shippingAddress.country = so.shippingAddress.country;
      result.shippingAddress.city = so.shippingAddress.city;
      result.shippingAddress.addressee = so.shippingAddress.addressee;
      result.shippingAddress.addr1 = so.shippingAddress.addr1;
      result.shippingAddress.addr2 = so.shippingAddress.addr2;
      result.shippingAddress.addr3 = so.shippingAddress.addr3;
    }

    if (so.billingAddress != null) {
      result.billingAddress = new SalesOrderDataModel.Address();
      result.billingAddress.zip = so.billingAddress.zip;
      result.billingAddress.state = so.billingAddress.state;
      result.billingAddress.internalId = so.billingAddress.internalId;
      result.billingAddress.country = so.billingAddress.country;
      result.billingAddress.city = so.billingAddress.city;
      result.billingAddress.addressee = so.billingAddress.addressee;
      result.billingAddress.addr1 = so.billingAddress.addr1;
      result.billingAddress.addr2 = so.billingAddress.addr2;
      result.billingAddress.addr3 = so.billingAddress.addr3;
    }

    return result;
  }
}