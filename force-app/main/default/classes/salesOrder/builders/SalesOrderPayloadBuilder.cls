public with sharing class SalesOrderPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    String internalId,
    String customer,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String memo,
    SalesOrderDataModel.Address shippingAddress,
    SalesOrderDataModel.Address billingAddress,
    List<SalesOrderDataModel.LineItem> lineItems,
    Boolean isUpdate
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    requestMap.put('customForm', lookupByInternalId('115'));
    requestMap.put('entity', lookupByInternalId(customer));
    requestMap.put('salesRep', lookupByInternalId(salesRep1));
    requestMap.put('subsidiary', lookupByInternalId(subsidiary));
    requestMap.put('location', lookupByInternalId(location));
    requestMap.put('tranDate', Helpers.toUnixSeconds(orderDate));

    if (String.isNotBlank(internalId)) {
      requestMap.put('internalId', internalId);
    }

    if (String.isNotBlank(memo)) {
      requestMap.put('memo', memo);
    }

    // if (shippingAddress != null) {
    //   requestMap.put('shippingAddress', buildAddress(shippingAddress));
    // }

    // if (billingAddress != null) {
    //   requestMap.put('billingAddress', buildAddress(billingAddress));
    // }

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => buildCustomFields(salesRep2) }
    );

    Map<String, Object> itemList = new Map<String, Object>{
      'item' => buildItemList(lineItems, location)
    };

    if (isUpdate) {
      itemList.put('replaceAll', false);
    }

    requestMap.put('itemList', itemList);

    return requestMap;
  }

  public static Map<String, Object> buildSavePayload(
    Map<String, Object> salesOrderRequest,
    Boolean isUpdate
  ) {
    List<Object> salesOrders = new List<Object>{ salesOrderRequest };

    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'salesOrders' => salesOrders
    };

    String requestJson = JSON.serialize(requestJsonMap);

    return isUpdate
      ? new Map<String, Object>{
          'version' => '1.0',
          'action' => 'updateSalesOrder',
          'RequestJSON' => requestJson
        }
      : new Map<String, Object>{
          'version' => '1.0',
          'action' => 'createSalesOrder',
          'RequestJSON' => requestJson
        };
  }

  public static Map<String, Object> buildReadRequest(String internalId) {
    Map<String, Object> filters = new Map<String, Object>{
      'internalId' => internalId
    };

    Map<String, Object> filterMap = new Map<String, Object>{
      'where' => new Map<String, Object>{ 'keyValueMap' => filters }
    };

    Map<String, Object> requestJSONMap = new Map<String, Object>{
      'customParameters' => filterMap
    };

    return requestJSONMap;
  }

  public static Map<String, Object> buildReadPayload(
    Map<String, Object> request
  ) {
    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'readSalesOrder',
      'requestJSON' => JSON.serialize(request)
    };
  }

  private static Map<String, Object> lookupByInternalId(String internalId) {
    return new Map<String, Object>{ 'internalId' => internalId };
  }

  private static List<Object> buildCustomFields(String salesRep2) {
    List<Object> customFields = new List<Object>();

    customFields.add(
      new Map<String, Object>{
        'fieldType' => 'select',
        'scriptId' => 'cseg1',
        'valueLookup' => lookupByInternalId('1')
      }
    );

    if (!String.isBlank(salesRep2)) {
      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'select',
          'scriptId' => 'custbody_salesrep2',
          'valueLookup' => lookupByInternalId(salesRep2)
        }
      );
    }

    return customFields;
  }

  private static List<Object> buildItemList(
    List<SalesOrderDataModel.LineItem> lineItems,
    String location
  ) {
    List<Object> items = new List<Object>();

    for (SalesOrderDataModel.LineItem lineItem : lineItems) {
      if (lineItem == null || String.isBlank(lineItem.item)) {
        continue;
      }

      Map<String, Object> itemMap = new Map<String, Object>{
        'item' => lookupByInternalId(lineItem.item),
        'location' => lookupByInternalId(location),
        'price' => lookupByInternalId('-1'),
        'rate' => lineItem.rate
      };

      if (!String.isBlank(lineItem.quantity)) {
        itemMap.put('quantity', lineItem.quantity);
      }

      if (!String.isBlank(lineItem.line)) {
        itemMap.put('line', lineItem.line);
      }

      items.add(itemMap);
    }

    return items;
  }
}
