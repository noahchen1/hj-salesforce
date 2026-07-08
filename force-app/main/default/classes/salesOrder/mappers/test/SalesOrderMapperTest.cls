@isTest
private class SalesOrderMapperTest {
  @testSetup
  static void setupData() {
    Account testAccount = new Account(Name = 'Mapper Test Account');
    insert testAccount;

    breadwinner_ns__BW_Company__c company = new breadwinner_ns__BW_Company__c(
      Name = 'Test Customer Company',
      breadwinner_ns__Entity_Type__c = 'Customer',
      breadwinner_ns__InternalId__c = 'CUST123',
      breadwinner_ns__Salesforce_Account__c = testAccount.Id
    );
    insert company;

    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item',
      breadwinner_ns__InternalId__c = 'ITEM123',
      imageId__c = 'IMG123'
    );
    insert item;
  }

  @isTest
  static void deserializeLineItems_success() {
    List<SalesOrderDataModel.LineItem> items = new List<SalesOrderDataModel.LineItem>();
    SalesOrderDataModel.LineItem li = new SalesOrderDataModel.LineItem();
    li.id = 1;
    li.item = 'ITEM123';
    li.isRepairNeeded = '2';
    items.add(li);
    String json = JSON.serialize(items);

    List<SalesOrderDataModel.LineItem> result = SalesOrderMapper.deserializeLineItems(
      json
    );

    System.assertEquals(1, result.size());
    System.assertEquals('ITEM123', result[0].item);
    System.assertEquals('2', result[0].isRepairNeeded);
  }

  @isTest
  static void deserializeLineItems_invalidJson() {
    try {
      SalesOrderMapper.deserializeLineItems('not a json');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Invalid line item payload'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void testDeserializeAddress_success() {
    SalesOrderDataModel.Address addr = new SalesOrderDataModel.Address();
    addr.city = 'Test City';
    String json = JSON.serialize(addr);
    SalesOrderDataModel.Address result = SalesOrderMapper.deserializeAddress(
      json
    );
    System.assertEquals('Test City', result.city);
  }

  @isTest
  static void testDeserializeAddress_invalidJson() {
    try {
      SalesOrderMapper.deserializeAddress('not a json');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Invalid address payload'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void testDeserializeAddress_emptyParam() {
    System.assertEquals(null, SalesOrderMapper.deserializeAddress(''));
  }

  @isTest
  static void mapSalesOrder_success() {
    // Build SalesOrderResModel.SalesOrder
    SalesOrderResModel.SalesOrder so = new SalesOrderResModel.SalesOrder();
    so.internalId = 'SO123';
    so.tranDate = 1715558400L; // 2024-05-13
    so.memo = 'Test Memo';

    SalesOrderResModel.RecordRef entity = new SalesOrderResModel.RecordRef();
    entity.name = 'Test Customer';
    entity.internalId = 'CUST123';
    so.entity = entity;

    System.assertEquals('Test Customer', entity.getName());
    System.assertEquals('CUST123', entity.getInternalId());

    SalesOrderResModel.RecordRef salesRep = new SalesOrderResModel.RecordRef();
    salesRep.name = 'Rep Name';
    salesRep.internalId = 'SR123';
    so.salesRep = salesRep;

    // Subsidiary, Location, Terms
    SalesOrderResModel.RecordRef subsidiary = new SalesOrderResModel.RecordRef();
    subsidiary.internalId = 'SUBS1';
    so.subsidiary = subsidiary;
    SalesOrderResModel.RecordRef location = new SalesOrderResModel.RecordRef();
    location.internalId = 'LOC1';
    so.location = location;
    SalesOrderResModel.RecordRef terms = new SalesOrderResModel.RecordRef();
    terms.internalId = 'TERM1';
    so.terms = terms;

    // Custom Fields
    SalesOrderResModel.CustomField isSpecialOrder = new SalesOrderResModel.CustomField();
    isSpecialOrder.scriptId = 'custbody_is_special_order';
    isSpecialOrder.value = 'true';

    SalesOrderResModel.CustomField specialOrderDate = new SalesOrderResModel.CustomField();
    specialOrderDate.scriptId = 'custbody_special_date';
    specialOrderDate.value = String.valueOf(1715558400L);

    SalesOrderResModel.CustomField needByDate = new SalesOrderResModel.CustomField();
    needByDate.scriptId = 'custbody_special_order_date';
    needByDate.value = String.valueOf(1715644800L);

    SalesOrderResModel.CustomField specialItemType = new SalesOrderResModel.CustomField();
    specialItemType.scriptId = 'custbody_special_item_type';
    specialItemType.valueLookup = new SalesOrderResModel.RecordRef();
    specialItemType.valueLookup.internalId = 'TYPE01';

    SalesOrderResModel.CustomField specialOrderVendor = new SalesOrderResModel.CustomField();
    specialOrderVendor.scriptId = 'custbody_special_order_vendor';
    specialOrderVendor.valueLookup = new SalesOrderResModel.RecordRef();
    specialOrderVendor.valueLookup.name = 'Vendor ABC';
    specialOrderVendor.valueLookup.internalId = 'VENDOR01';

    SalesOrderResModel.CustomField specialPrefVendor = new SalesOrderResModel.CustomField();
    specialPrefVendor.scriptId = 'custbody_special_pref_vendor';
    specialPrefVendor.value = 'Preferred Vendor Text';

    SalesOrderResModel.CustomField specialComments = new SalesOrderResModel.CustomField();
    specialComments.scriptId = 'custbody_special_comments';
    specialComments.value = 'Special comments';

    SalesOrderResModel.CustomField specialMerchNote = new SalesOrderResModel.CustomField();
    specialMerchNote.scriptId = 'custbody_special_merch_note';
    specialMerchNote.value = 'Merch note';

    SalesOrderResModel.CustomField specialMemoSold = new SalesOrderResModel.CustomField();
    specialMemoSold.scriptId = 'custbody_special_memo_sold';
    specialMemoSold.valueLookup = new SalesOrderResModel.RecordRef();
    specialMemoSold.valueLookup.internalId = 'MEMO_OR_SOLD';

    SalesOrderResModel.CustomField specialStatuses = new SalesOrderResModel.CustomField();
    specialStatuses.scriptId = 'custbody_special_statuses';
    specialStatuses.valueLookup = new SalesOrderResModel.RecordRef();
    specialStatuses.valueLookup.internalId = 'STATUS01';

    SalesOrderResModel.CustomField salesRep2 = new SalesOrderResModel.CustomField();
    salesRep2.scriptId = 'custbody_salesrep2';
    salesRep2.valueLookup = new SalesOrderResModel.RecordRef();
    salesRep2.valueLookup.name = 'Sales Rep 2';
    salesRep2.valueLookup.internalId = 'SR456';

    SalesOrderResModel.CustomFieldList customFieldList = new SalesOrderResModel.CustomFieldList();
    customFieldList.customField = new List<SalesOrderResModel.CustomField>{
      isSpecialOrder,
      specialOrderDate,
      salesRep2,
      needByDate,
      specialItemType,
      specialOrderVendor,
      specialPrefVendor,
      specialComments,
      specialMerchNote,
      specialMemoSold,
      specialStatuses
    };
    so.customFieldList = customFieldList;

    // Addresses
    SalesOrderResModel.Address shipAddr = new SalesOrderResModel.Address();
    shipAddr.city = 'Ship City';
    so.shippingAddress = shipAddr;
    SalesOrderResModel.Address billAddr = new SalesOrderResModel.Address();
    billAddr.city = 'Bill City';
    so.billingAddress = billAddr;

    // Line Items
    SalesOrderResModel.SalesOrderItem item = new SalesOrderResModel.SalesOrderItem();
    SalesOrderResModel.RecordRef itemRef = new SalesOrderResModel.RecordRef();
    itemRef.internalId = 'ITEM123';
    item.item = itemRef;
    item.quantity = 2;
    item.amount = 100;
    item.rate = '50';
    item.line = '1';
    SalesOrderResModel.CustomField licf = new SalesOrderResModel.CustomField();
    licf.scriptId = 'custcol_special_sku';
    licf.value = 'SKU123';

    SalesOrderResModel.CustomField specialOrderNumber = new SalesOrderResModel.CustomField();
    specialOrderNumber.scriptId = 'custcol_special_order_number';
    specialOrderNumber.value = 'PO-7788';

    SalesOrderResModel.CustomField specialQuotedPrice = new SalesOrderResModel.CustomField();
    specialQuotedPrice.scriptId = 'custcol_special_quoted_price';
    specialQuotedPrice.value = '123.45';

    SalesOrderResModel.CustomField itemDisplayName = new SalesOrderResModel.CustomField();
    itemDisplayName.scriptId = 'custcol_itemdisname';
    itemDisplayName.value = 'Custom Display Name';

    SalesOrderResModel.CustomField repairNeeded = new SalesOrderResModel.CustomField();
    repairNeeded.scriptId = 'custcol_repair_needed';
    SalesOrderResModel.RecordRef repairNeededValue = new SalesOrderResModel.RecordRef();
    repairNeededValue.internalId = '2';
    repairNeeded.valueLookup = repairNeededValue;

    SalesOrderResModel.CustomFieldList licfl = new SalesOrderResModel.CustomFieldList();
    licfl.customField = new List<SalesOrderResModel.CustomField>{
      licf,
      specialOrderNumber,
      specialQuotedPrice,
      itemDisplayName,
      repairNeeded
    };
    item.customFieldList = licfl;
    SalesOrderResModel.ItemList itemList = new SalesOrderResModel.ItemList();
    itemList.item = new List<SalesOrderResModel.SalesOrderItem>{ item };
    so.itemList = itemList;

    Test.startTest();
    SalesOrderDataModel.SalesOrderData mapped = SalesOrderMapper.mapSalesOrder(
      so
    );
    Test.stopTest();

    System.assertEquals('SO123', mapped.soNsInternalId);
    System.assertEquals('2024-05-13', mapped.orderDate);
    System.assertEquals('Test Memo', mapped.memo);
    System.assertEquals('Rep Name', mapped.salesRep1Name);
    System.assertEquals('SR123', mapped.salesRep1NsId);
    System.assertEquals('SUBS1', mapped.subsidiaryNsId);
    System.assertEquals('LOC1', mapped.locationNsId);
    System.assertEquals('TERM1', mapped.termNsId);
    System.assertEquals('Test Customer', mapped.customerName);
    System.assertEquals('CUST123', mapped.customerNsId);
    System.assertNotEquals(null, mapped.nsCompanyId);
    System.assertNotEquals(null, mapped.accountId);
    System.assertEquals('special', mapped.orderType);
    System.assertEquals('2024-05-13', mapped.specialDate);
    System.assertEquals('2024-05-14', mapped.needByDate);
    System.assertEquals('TYPE01', mapped.specialOrderItemType);
    System.assertEquals('Vendor ABC', mapped.specialOrderVendorName);
    System.assertEquals('VENDOR01', mapped.specialOrderVendorNsId);
    System.assertEquals(
      'Preferred Vendor Text',
      mapped.specialOrderRequestedVendor
    );
    System.assertEquals('Special comments', mapped.specialOrderComments);
    System.assertEquals('Merch note', mapped.specialOrderNotes);
    System.assertEquals('MEMO_OR_SOLD', mapped.specialOrderMemoOrSold);
    System.assertEquals('STATUS01', mapped.specialOrderStatus);
    System.assertEquals('Sales Rep 2', mapped.salesRep2Name);
    System.assertEquals('SR456', mapped.salesRep2NsId);
    System.assertEquals('Ship City', mapped.shippingAddress.city);
    System.assertEquals('Bill City', mapped.billingAddress.city);
    System.assertEquals(1, mapped.lineItems.size());
    System.assertEquals('ITEM123', mapped.lineItems[0].item);
    System.assertEquals('Test Item', mapped.lineItems[0].itemName);
    System.assertEquals('2', mapped.lineItems[0].quantity);
    System.assertEquals('100', mapped.lineItems[0].amount);
    System.assertEquals('SKU123', mapped.lineItems[0].specialOrderItem);
    System.assertEquals('PO-7788', mapped.lineItems[0].specialOrderVendorNum);
    System.assertEquals('123.45', mapped.lineItems[0].quotedPrice);
    System.assertEquals('2', mapped.lineItems[0].isRepairNeeded);
    System.assertEquals('Custom Display Name', mapped.lineItems[0].displayName);
  }
}
