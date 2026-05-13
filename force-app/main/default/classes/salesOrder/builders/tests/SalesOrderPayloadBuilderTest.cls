@isTest
private class SalesOrderPayloadBuilderTest {
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

    Date orderDate = Date.today();

    Map<String, Object> req = SalesOrderPayloadBuilder.buildSaveRequest(
      'sales',
      '15231',
      '12345',
      orderDate,
      'Sales Rep1',
      null,
      'Princeton',
      'Princeton',
      '115',
      'some memo',
      Date.today(),
      Date.today(),
      null,
      null,
      null,
      null,
      null,
      null,
      shipping,
      billing,
      items,
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
    SalesOrderDataModel.Address shipping = new SalesOrderDataModel.Address();
    SalesOrderDataModel.Address billing = new SalesOrderDataModel.Address();
    SalesOrderDataModel.LineItem item = new SalesOrderDataModel.LineItem();
    item.item = '456';
    item.specialOrderItem = 'SOI';
    item.specialOrderVendorNum = 'VNUM';
    item.quotedPrice = '99.99';
    List<SalesOrderDataModel.LineItem> items = new List<SalesOrderDataModel.LineItem>{
      item
    };

    Date today = Date.today();
    Map<String, Object> req = SalesOrderPayloadBuilder.buildSaveRequest(
      'special',
      'SO-2',
      'CUST-2',
      today,
      'SR2',
      'SR3',
      'SUB2',
      'LOC2',
      'T2',
      'Memo2',
      today,
      today,
      'ITYPE',
      'VEND',
      'REQVEND',
      'COMMENTS',
      'NOTES',
      'MEMO',
      shipping,
      billing,
      items,
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
