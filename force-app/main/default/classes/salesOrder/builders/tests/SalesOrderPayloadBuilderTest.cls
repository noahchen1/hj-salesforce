@isTest
private class SalesOrderPayloadBuilderTest {
  private static SalesOrderParamModel.SalesOrderSaveParam baseParams(
    String orderType
  ) {
    SalesOrderParamModel.SalesOrderSaveParam params = new SalesOrderParamModel.SalesOrderSaveParam();
    params.orderType = orderType;
    params.soNsInternalId = '15231';
    params.custNsInternalId = '12345';
    params.salesRep1 = 'Sales Rep1';
    params.subsidiary = 'Princeton';
    params.location = 'Princeton';
    params.termsNsInternalId = '115';
    params.memo = 'some memo';
    return params;
  }

  @isTest
  static void buildSaveRequest_success() {
    SalesOrderDataModel.Address shipping = new SalesOrderDataModel.Address();
    shipping.addr1 = '123 Main St';
    shipping.city = 'Metropolis';
    shipping.state = 'NY';
    shipping.zip = '10001';

    SalesOrderDataModel.Address billing = new SalesOrderDataModel.Address();
    billing.addr1 = '456 Elm St';
    billing.city = 'Gotham';
    billing.state = 'NY';
    billing.zip = '10002';

    SalesOrderDataModel.LineItem item = new SalesOrderDataModel.LineItem();
    item.item = '123';
    item.rate = '10.00';
    item.quantity = '2';
    item.line = '1';

    List<SalesOrderDataModel.LineItem> items = new List<SalesOrderDataModel.LineItem>{
      item
    };

    Map<String, Object> req = SalesOrderPayloadBuilder.buildSaveRequest(
      baseParams('sales'),
      shipping,
      billing,
      items,
      null,
      false
    );

    System.assertEquals(
      '12345',
      ((Map<String, Object>) req.get('entity')).get('internalId')
    );
    System.assertEquals(
      'Sales Rep1',
      ((Map<String, Object>) req.get('salesRep')).get('internalId')
    );
    System.assertEquals('some memo', req.get('memo'));
    System.assertEquals(
      '123 Main St',
      ((Map<String, Object>) req.get('shippingAddress')).get('addr1')
    );
    System.assertEquals(
      '456 Elm St',
      ((Map<String, Object>) req.get('billingAddress')).get('addr1')
    );

    List<Object> itemList = (List<Object>) ((Map<String, Object>) req.get(
        'itemList'
      ))
      .get('item');

    System.assertEquals(
      '123',
      ((Map<String, Object>) ((Map<String, Object>) itemList[0]).get('item'))
        .get('internalId')
    );
  }

  @isTest
  static void buildSaveRequest_specialOrder() {
    SalesOrderParamModel.SalesOrderSaveParam params = baseParams('special');
    params.soNsInternalId = 'SO-2';
    params.custNsInternalId = 'CUST-2';
    params.salesRep1 = 'SR2';
    params.salesRep2 = 'SR3';
    params.subsidiary = 'SUB2';
    params.location = 'LOC2';
    params.termsNsInternalId = 'T2';
    params.memo = 'Memo2';
    params.specialDate = Date.today();
    params.needByDate = Date.today();
    params.specialOrderItemType = 'ITYPE';
    params.specialOrderVendor = 'VEND';
    params.specialOrderRequestedVendor = 'REQVEND';
    params.specialOrderComments = 'COMMENTS';
    params.specialOrderNotes = 'NOTES';
    params.specialOrderMemoOrSold = 'MEMO';
    params.inquiryModel = 'Daytona';
    params.inquiryName = 'Black Dial';
    params.inquiryLink = 'https://example.com/daytona';
    params.inquiryIsPrority = true;
    params.inquiryIsOpenDial = true;
    params.inquiryIsSendEmail = false;

    SalesOrderDataModel.LineItem item = new SalesOrderDataModel.LineItem();
    item.item = '456';
    item.specialOrderItem = 'SOI';
    item.specialOrderVendorNum = 'VNUM';
    item.quotedPrice = '99.99';

    List<SalesOrderDataModel.LineItem> items = new List<SalesOrderDataModel.LineItem>{
      item
    };

    Map<String, Object> req = SalesOrderPayloadBuilder.buildSaveRequest(
      params,
      new SalesOrderDataModel.Address(),
      new SalesOrderDataModel.Address(),
      items,
      null,
      true
    );

    System.assertEquals(
      true,
      ((Map<String, Object>) req.get('itemList')).get('replaceAll')
    );
    List<Object> customFields = (List<Object>) ((Map<String, Object>) req.get(
        'customFieldList'
      ))
      .get('customField');
    Boolean foundSpecial = false;
    for (Object cf : customFields) {
      Map<String, Object> cfMap = (Map<String, Object>) cf;
      if ((String) cfMap.get('scriptId') == 'custbody_special_item_type') {
        foundSpecial = true;
      }
    }
    System.assert(foundSpecial, 'Should have special item type custom field');
    List<Object> itemObjs = (List<Object>) ((Map<String, Object>) req.get(
        'itemList'
      ))
      .get('item');
    Map<String, Object> itemMap = (Map<String, Object>) itemObjs[0];
    System.assertEquals(
      '456',
      ((Map<String, Object>) itemMap.get('item')).get('internalId')
    );
    System.assert(
      itemMap.containsKey('customFieldList'),
      'Special order item should have customFieldList'
    );
  }

  @isTest
  static void buildSaveRequest_repairOrderIncludesRepairNeededLineField() {
    SalesOrderParamModel.SalesOrderSaveParam params = baseParams('repair');

    SalesOrderDataModel.LineItem item = new SalesOrderDataModel.LineItem();
    item.item = '789';
    item.rate = '10.00';
    item.quantity = '1';
    item.isRepairNeeded = '2';

    Map<String, Object> req = SalesOrderPayloadBuilder.buildSaveRequest(
      params,
      null,
      null,
      new List<SalesOrderDataModel.LineItem>{ item },
      null,
      false
    );

    List<Object> itemObjs = (List<Object>) ((Map<String, Object>) req.get(
        'itemList'
      ))
      .get('item');
    Map<String, Object> itemMap = (Map<String, Object>) itemObjs[0];
    List<Object> customFields = (List<Object>) ((Map<String, Object>) itemMap.get(
        'customFieldList'
      ))
      .get('customField');

    System.assertEquals(1, customFields.size());
    Map<String, Object> repairNeededField = (Map<String, Object>) customFields[0];
    System.assertEquals('select', repairNeededField.get('fieldType'));
    System.assertEquals(
      'custcol_repair_needed',
      repairNeededField.get('scriptId')
    );
    System.assertEquals(
      '2',
      ((Map<String, Object>) repairNeededField.get('valueLookup'))
        .get('internalId')
    );
  }

  @isTest
  static void buildSavePayload_success() {
    Map<String, Object> req = new Map<String, Object>{ 'foo' => 'bar' };

    Map<String, Object> payload = SalesOrderPayloadBuilder.buildSavePayload(
      req,
      false
    );

    System.assertEquals('1.0', payload.get('version'));
    System.assertEquals('createSalesOrder', payload.get('action'));
    System.assert(payload.get('RequestJSON') != null);
    Map<String, Object> payload2 = SalesOrderPayloadBuilder.buildSavePayload(
      req,
      true
    );
    System.assertEquals('updateSalesOrder', payload2.get('action'));
  }

  @isTest
  static void buildReadRequest_success() {
    Map<String, Object> req = SalesOrderPayloadBuilder.buildReadRequest('SO-3');

    System.assertEquals(
      'SO-3',
      ((Map<String, Object>) ((Map<String, Object>) ((Map<String, Object>) req.get(
              'customParameters'
            ))
            .get('where'))
          .get('keyValueMap'))
        .get('internalId')
    );
  }

  @isTest
  static void buildReadPayload_success() {
    Map<String, Object> req = SalesOrderPayloadBuilder.buildReadRequest('SO-3');

    Map<String, Object> payload = SalesOrderPayloadBuilder.buildReadPayload(
      req
    );
    System.assertEquals('1.0', payload.get('version'));
    System.assertEquals('readSalesOrder', payload.get('action'));
    System.assert(payload.get('requestJSON') != null);
  }
}
