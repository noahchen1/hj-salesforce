public with sharing class SalesOrderMapper {
  public static List<SalesOrderDataModel.LineItem> deserializeLineItems(
    String lineItemsJson
  ) {
    try {
      return (List<SalesOrderDataModel.LineItem>) JSON.deserialize(
        lineItemsJson,
        List<SalesOrderDataModel.LineItem>.class
      );
    } catch (Exception e) {
      throw new AuraHandledException('Invalid line item payload.');
    }
  }

  public static SalesOrderDataModel.Address deserializeAddress(
    String addressJson
  ) {
    if (String.isBlank(addressJson)) {
      return null;
    }

    return (SalesOrderDataModel.Address) JSON.deserialize(
      addressJson,
      SalesOrderDataModel.Address.class
    );
  }

  public static SalesOrderDataModel.SalesOrderData mapSalesOrder(
    SalesOrderResModel.SalesOrder so
  ) {
    SalesOrderDataModel.SalesOrderData result = new SalesOrderDataModel.SalesOrderData();

    result.internalId = so.internalId;
    result.orderDate = Helpers.toDateOnlyFromUnixSeconds(so.tranDate);
    result.memo = so.memo;

    result.salesRep1Name = so.salesRep?.name;
    result.salesRep1NsId = so.salesRep?.internalId;
    result.subsidiaryNsId = so.subsidiary?.internalId;
    result.locationNsId = so.location?.internalId;

    mapCustomer(so, result);
    mapSalesRep2(so, result);
    mapLineItems(so, result);
    mapAddresses(so, result);

    return result;
  }

  private static void mapCustomer(
    SalesOrderResModel.SalesOrder so,
    SalesOrderDataModel.SalesOrderData result
  ) {
    SalesOrderResModel.RecordRef customer = so.entity;

    if (customer == null) {
      return;
    }

    result.customerName = customer.name;
    result.customerNsId = customer.internalId;

    if (String.isBlank(customer.internalId)) {
      return;
    }

    List<breadwinner_ns__BW_Company__c> companies = [
      SELECT Id
      FROM breadwinner_ns__BW_Company__c
      WHERE
        breadwinner_ns__InternalId__c = :customer.internalId
        AND breadwinner_ns__Entity_Type__c = 'Customer'
      LIMIT 1
    ];

    if (!companies.isEmpty()) {
      result.nsCompanyId = companies[0].Id;
    }
  }

  private static void mapSalesRep2(
    SalesOrderResModel.SalesOrder so,
    SalesOrderDataModel.SalesOrderData result
  ) {
    if (so.customFieldList == null || so.customFieldList.customField == null) {
      return;
    }

    for (SalesOrderResModel.CustomField cf : so.customFieldList.customField) {
      if (cf != null && cf.scriptId == 'custbody_salesrep2') {
        result.salesRep2Name = cf.valueLookup != null
          ? cf.valueLookup.name
          : cf.value;

        result.salesRep2NsId = cf.valueLookup != null
          ? cf.valueLookup.internalId
          : null;

        return;
      }
    }
  }

  private static void mapLineItems(
    SalesOrderResModel.SalesOrder so,
    SalesOrderDataModel.SalesOrderData result
  ) {
    if (so.itemList == null || so.itemList.item == null)
      return;

    Map<String, String> itemNames = fetchItemNames(so);

    Integer rowNum = 1;

    for (SalesOrderResModel.SalesOrderItem it : so.itemList.item) {
      if (it == null)
        continue;

      SalesOrderDataModel.LineItem dto = new SalesOrderDataModel.LineItem();

      dto.id = rowNum++;
      dto.item = it.item?.internalId;
      dto.itemName = itemNames.get(dto.item);
      dto.quantity = it.quantity != null ? String.valueOf(it.quantity) : null;
      dto.rate = it.rate;
      dto.amount = it.amount != null ? String.valueOf(it.amount) : null;
      dto.line = it.line;

      result.lineItems.add(dto);
    }
  }

  private static void mapAddresses(
    SalesOrderResModel.SalesOrder so,
    SalesOrderDataModel.SalesOrderData result
  ) {
    result.shippingAddress = mapAddress(so.shippingAddress);
    result.billingAddress = mapAddress(so.billingAddress);
  }

  private static SalesOrderDataModel.Address mapAddress(
    SalesOrderResModel.Address src
  ) {
    if (src == null)
      return null;

    SalesOrderDataModel.Address addr = new SalesOrderDataModel.Address();

    addr.zip = src.zip;
    addr.state = src.state;
    addr.internalId = src.internalId;
    addr.country = src.country;
    addr.city = src.city;
    addr.addressee = src.addressee;
    addr.addr1 = src.addr1;
    addr.addr2 = src.addr2;
    addr.addr3 = src.addr3;

    return addr;
  }

  private static Map<String, String> fetchItemNames(
    SalesOrderResModel.SalesOrder so
  ) {
    Set<String> ids = new Set<String>();

    for (SalesOrderResModel.SalesOrderItem it : so.itemList.item) {
      if (
        it != null &&
        it.item != null &&
        String.isNotBlank(it.item.internalId)
      ) {
        ids.add(it.item.internalId);
      }
    }

    Map<String, String> result = new Map<String, String>();

    if (!ids.isEmpty()) {
      for (breadwinner_ns__BW_Item__c item : [
        SELECT Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE breadwinner_ns__InternalId__c IN :ids
      ]) {
        result.put(item.breadwinner_ns__InternalId__c, item.Name);
      }
    }

    return result;
  }
}
