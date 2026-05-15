public with sharing class SalesOrderMapper {
  public static List<SalesOrderDataModel.LineItem> deserializeLineItems(
    String lineItemsJson
  ) {
    try {
      return (List<SalesOrderDataModel.LineItem>) JSON.deserialize(
        lineItemsJson,
        List<SalesOrderDataModel.LineItem>.class
      );
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid line item payload.'
      );

      e.setMessage('Invalid line item payload.');

      throw e;
    }
  }

  public static SalesOrderDataModel.Address deserializeAddress(
    String addressJson
  ) {
    if (String.isBlank(addressJson)) {
      return null;
    }

    try {
      return (SalesOrderDataModel.Address) JSON.deserialize(
        addressJson,
        SalesOrderDataModel.Address.class
      );
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid address payload.'
      );

      e.setMessage('Invalid address payload.');

      throw e;
    }
  }

  public static SalesOrderDataModel.SalesOrderData mapSalesOrder(
    SalesOrderResModel.SalesOrder so
  ) {
    SalesOrderDataModel.SalesOrderData result = new SalesOrderDataModel.SalesOrderData();

    result.soNsInternalId = so.internalId;
    result.orderDate = Helpers.toDateOnlyFromUnixSeconds(so.tranDate);
    result.memo = so.memo;

    result.salesRep1Name = so.salesRep?.name;
    result.salesRep1NsId = so.salesRep?.internalId;
    result.subsidiaryNsId = so.subsidiary?.internalId;
    result.locationNsId = so.location?.internalId;
    result.termNsId = so.terms?.internalId;

    mapCustomer(so, result);
    mapOrderCustomFields(so, result);
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
      SELECT Id, breadwinner_ns__Salesforce_Account__c
      FROM breadwinner_ns__BW_Company__c
      WHERE
        breadwinner_ns__InternalId__c = :customer.internalId
        AND breadwinner_ns__Entity_Type__c = 'Customer'
      LIMIT 1
    ];

    if (!companies.isEmpty()) {
      breadwinner_ns__BW_Company__c company = companies[0];
      result.nsCompanyId = company.Id;
      result.accountId = company.breadwinner_ns__Salesforce_Account__c;
    }
  }

  private static void mapOrderCustomFields(
    SalesOrderResModel.SalesOrder so,
    SalesOrderDataModel.SalesOrderData result
  ) {
    if (so.customFieldList == null || so.customFieldList.customField == null) {
      return;
    }

    for (SalesOrderResModel.CustomField cf : so.customFieldList.customField) {
      if (cf == null || String.isBlank(cf.scriptId)) {
        continue;
      }

      if (cf.scriptId == 'custbody_salesrep2') {
        result.salesRep2Name = cf.valueLookup != null
          ? cf.valueLookup.name
          : cf.value;

        result.salesRep2NsId = cf.valueLookup != null
          ? cf.valueLookup.internalId
          : null;

        continue;
      }

      if (cf.scriptId == 'custbody_is_special_order') {
        Boolean isSpecialOrder = Boolean.valueOf(cf.value);

        result.orderType = isSpecialOrder
          ? String.valueOf(SalesOrderType.special)
          : String.valueOf(SalesOrderType.sales);

        continue;
      }

      if (cf.scriptId == 'custbody_inquiry_model') {
        result.inquiryModel = cf.value;
        result.orderType = String.valueOf(SalesOrderType.inquiry);
        continue;
      }

      if (cf.scriptId == 'custbody_inquiry_name') {
        result.inquiryName = cf.value;
        result.orderType = String.valueOf(SalesOrderType.inquiry);
        continue;
      }

      if (cf.scriptId == 'custbody_inquiry_link') {
        result.inquiryLink = cf.value;
        result.orderType = String.valueOf(SalesOrderType.inquiry);
        continue;
      }

      if (cf.scriptId == 'custbody_inquiry_is_priority') {
        result.inquiryIsPrority = Boolean.valueOf(cf.value);
        result.orderType = String.valueOf(SalesOrderType.inquiry);
        continue;
      }

      if (cf.scriptId == 'custbody_inquiry_is_open_dial') {
        result.inquiryIsOpenDial = Boolean.valueOf(cf.value);
        result.orderType = String.valueOf(SalesOrderType.inquiry);
        continue;
      }

      if (cf.scriptId == 'custbody_special_date') {
        result.specialDate = toDateOnlyFromUnixSeconds(cf.value);
        continue;
      }

      if (cf.scriptId == 'custbody_special_order_date') {
        result.needByDate = toDateOnlyFromUnixSeconds(cf.value);
        continue;
      }

      if (cf.scriptId == 'custbody_special_item_type') {
        result.specialOrderItemType = cf.valueLookup != null
          ? cf.valueLookup.internalId
          : cf.value;
        continue;
      }

      if (cf.scriptId == 'custbody_special_order_vendor') {
        result.specialOrderVendorName = cf.valueLookup != null
          ? cf.valueLookup.name
          : cf.value;

        result.specialOrderVendorNsId = cf.valueLookup != null
          ? cf.valueLookup.internalId
          : null;
        continue;
      }

      if (cf.scriptId == 'custbody_special_pref_vendor') {
        result.specialOrderRequestedVendor = cf.value;
        continue;
      }

      if (cf.scriptId == 'custbody_special_comments') {
        result.specialOrderComments = cf.value;
        continue;
      }

      if (cf.scriptId == 'custbody_special_merch_note') {
        result.specialOrderNotes = cf.value;
        continue;
      }

      if (cf.scriptId == 'custbody_special_memo_sold') {
        result.specialOrderMemoOrSold = cf.valueLookup != null
          ? cf.valueLookup.internalId
          : cf.value;
        continue;
      }

      if (cf.scriptId == 'custbody_special_statuses') {
        result.specialOrderStatus = cf.valueLookup != null
          ? cf.valueLookup.internalId
          : cf.value;
      }
    }
  }

  private static String toDateOnlyFromUnixSeconds(String unixSecondsText) {
    if (String.isBlank(unixSecondsText)) {
      return null;
    }

    try {
      return Helpers.toDateOnlyFromUnixSeconds(
        Long.valueOf(unixSecondsText.trim())
      );
    } catch (Exception e) {
      return null;
    }
  }

  private static void mapLineItems(
    SalesOrderResModel.SalesOrder so,
    SalesOrderDataModel.SalesOrderData result
  ) {
    if (so.itemList == null || so.itemList.item == null)
      return;

    Map<String, Map<String, String>> itemNamesAndImageIds = fetchItemNamesAndImages(
      so
    );

    Integer rowNum = 1;

    for (SalesOrderResModel.SalesOrderItem it : so.itemList.item) {
      if (it == null)
        continue;

      SalesOrderDataModel.LineItem dto = new SalesOrderDataModel.LineItem();

      dto.id = rowNum++;
      dto.item = it.item?.internalId;
      Map<String, String> itemDetails = itemNamesAndImageIds.get(dto.item);
      dto.itemName = itemDetails != null ? itemDetails.get('name') : null;
      dto.imageUrl = itemDetails != null ? itemDetails.get('imageUrl') : null;
      dto.quantity = it.quantity != null ? String.valueOf(it.quantity) : null;
      dto.rate = it.rate;
      dto.amount = it.amount != null ? String.valueOf(it.amount) : null;
      dto.line = it.line;
      dto.quantityAvailable = it.quantityAvailable != null
        ? String.valueOf(it.quantityAvailable)
        : null;

      dto.quantityBackOrdered = it.quantityBackOrdered != null
        ? String.valueOf(it.quantityBackOrdered)
        : null;

      mapLineItemCustomFields(it, dto);

      result.lineItems.add(dto);
    }
  }

  private static void mapLineItemCustomFields(
    SalesOrderResModel.SalesOrderItem source,
    SalesOrderDataModel.LineItem target
  ) {
    if (
      source == null ||
      source.customFieldList == null ||
      source.customFieldList.customField == null
    ) {
      return;
    }

    for (
      SalesOrderResModel.CustomField cf : source.customFieldList.customField
    ) {
      if (cf == null || String.isBlank(cf.scriptId)) {
        continue;
      }

      if (cf.scriptId == 'custcol_special_sku') {
        target.specialOrderItem = cf.value;
        continue;
      }

      if (cf.scriptId == 'custcol_special_order_number') {
        target.specialOrderVendorNum = cf.value;
        continue;
      }

      if (cf.scriptId == 'custcol_special_quoted_price') {
        target.quotedPrice = cf.value;
        continue;
      }

      if (cf.scriptId == 'custcol_itemdisname') {
        target.displayName = cf.value;
      }
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
    addr.attention = src.attention;
    addr.addressee = src.addressee;
    addr.addr1 = src.addr1;
    addr.addr2 = src.addr2;
    addr.addr3 = src.addr3;

    return addr;
  }

  private static Map<String, Map<String, String>> fetchItemNamesAndImages(
    SalesOrderResModel.SalesOrder so
  ) {
    Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();

    if (so == null || so.itemList == null || so.itemList.item == null) {
      return result;
    }

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

    if (!ids.isEmpty()) {
      for (breadwinner_ns__BW_Item__c item : [
        SELECT Name, breadwinner_ns__InternalId__c, imageId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE breadwinner_ns__InternalId__c IN :ids
      ]) {
        String imageUrl = item.imageId__c != null
          ? '/sfc/servlet.shepherd/document/download/' + item.imageId__c
          : '';

        result.put(
          item.breadwinner_ns__InternalId__c,
          new Map<String, String>{ 'name' => item.Name, 'imageUrl' => imageUrl }
        );
      }
    }

    return result;
  }
}
