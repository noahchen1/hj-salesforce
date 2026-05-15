@isTest
private class SalesOrderValidatorTest {
  private static String buildLineItemsJson(
    String item,
    String quantity,
    String rate,
    String amount,
    String quotedPrice
  ) {
    SalesOrderDataModel.LineItem line = new SalesOrderDataModel.LineItem();

    line.item = item;
    line.quantity = quantity;
    line.rate = rate;
    line.amount = amount;
    line.quotedPrice = quotedPrice;

    return JSON.serialize(new List<SalesOrderDataModel.LineItem>{ line });
  }

  @isTest
  static void validateParams_passes() {
    Test.startTest();

    SalesOrderValidator.validateParams(
      'sales',
      '12345',
      Date.today(),
      'REP-1',
      'SUB-1',
      'LOC-1',
      Date.today(),
      Date.today(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      buildLineItemsJson('186466', null, '20', '20', null)
    );

    Test.stopTest();
  }

  @isTest
  static void validateParams_invalidOrderType() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'other',
        null,
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unsupported orderType:'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_inquiryMissingParams() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'inquiry',
        '12345',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('item', '2', '20', '40', null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Missing required inquiry parameters.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_inquiryPasses() {
    Test.startTest();
    SalesOrderValidator.validateParams(
      'inquiry',
      '12345',
      Date.today(),
      'REP-1',
      'SUB-1',
      'LOC-1',
      null,
      null,
      null,
      null,
      null,
      'INQ-1',
      'Daytona',
      'Black Dial',
      'https://example.com/daytona',
      true,
      buildLineItemsJson('item', '1', '20', '20', null)
    );
    Test.stopTest();
  }

  @isTest
  static void validateParams_missingSalesOrderParams() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'sales',
        null,
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('item', '2', null, null, null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Missing required parameters'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_emptyLineItems() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'special',
        '123565',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        'Watch',
        'Rolex',
        '2',
        null,
        null,
        null,
        null,
        null,
        JSON.serialize(new List<Object>())
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('At least one line item is required.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_missingItem() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'sales',
        '123565',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        'Watch',
        'Rolex',
        '2',
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('', '2', null, null, null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('item is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_missingRate() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'sales',
        '123565',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        'Watch',
        'Rolex',
        '2',
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('item1', '2', null, null, null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('rate is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_missingAmount() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'sales',
        '123565',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        'Watch',
        'Rolex',
        '2',
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('item1', '2', '20', null, null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('amount is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_missingQuantityForNonDiscount() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'sales',
        '123565',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        'Watch',
        'Rolex',
        '2',
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('item1', null, '20', '20', null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('quantity is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateParams_missingQuantityForDiscount() {
    Test.startTest();
    SalesOrderValidator.validateParams(
      'sales',
      '123565',
      Date.today(),
      'REP-1',
      'SUB-1',
      'LOC-1',
      Date.today(),
      Date.today(),
      'Watch',
      'Rolex',
      '2',
      null,
      null,
      null,
      null,
      null,
      buildLineItemsJson('186466', null, '20', '20', null)
    );
    Test.stopTest();
  }

  @isTest
  static void validateParams_missingQuotedPriceForSpecialOrderItem() {
    try {
      Test.startTest();
      SalesOrderValidator.validateParams(
        'special',
        '123565',
        Date.today(),
        'REP-1',
        'SUB-1',
        'LOC-1',
        Date.today(),
        Date.today(),
        'Watch',
        'Rolex',
        '2',
        null,
        null,
        null,
        null,
        null,
        buildLineItemsJson('Special Order Item', '2', '20', '20', null)
      );
      Test.stopTest();
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('quotedPrice is required for special orders'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_nullResponse() {
    try {
      SalesOrderValidator.validateRawResponse(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No response returned from NetSuite.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_invalidRequest() {
    try {
      SalesOrderValidator.validateRawResponse(
        new Map<String, Object>{
          'validRequest' => false,
          'responseJSON' => '{"status":"200"}'
        }
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage()
          .contains('Invalid request: NetSuite rejected the payload.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_emptyBody() {
    try {
      SalesOrderValidator.validateRawResponse(
        new Map<String, Object>{ 'validRequest' => true, 'responseJSON' => '' }
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned an empty response body.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void responseJson_deserializesRepresentativePayload() {
    String responseJson =
      '{' +
      '"status":"200",' +
      '"errors":[{"code":"WARN","message":"none","detail":"detail","field":"memo","type":"validation"}],' +
      '"salesOrders":[{' +
      '"internalId":"SO-1",' +
      '"tranDate":1715558400,' +
      '"memo":"Test Memo",' +
      '"entity":{"name":"Acme","internalId":"CUST123"},' +
      '"salesRep":{"name":"Rep 1","internalId":"REP1"},' +
      '"itemList":{' +
      '"item":[{' +
      '"quantity":2,' +
      '"rate":"50.00",' +
      '"amount":100,' +
      '"line":"1",' +
      '"item":{"name":"Widget","internalId":"ITEM123"},' +
      '"customFieldList":{"customField":[{' +
      '"scriptId":"custcol_special_sku","value":"SKU123"' +
      '}]}' +
      '}]' +
      '},' +
      '"customFieldList":{"customField":[{' +
      '"scriptId":"custbody_is_special_order","value":"true"' +
      '}]},' +
      '"shippingAddress":{"city":"Ship City","country":"US"},' +
      '"billingAddress":{"city":"Bill City","country":"US"}' +
      '}]' +
      '}';

    SalesOrderResModel.ResponseJson body = (SalesOrderResModel.ResponseJson) JSON.deserialize(
      responseJson,
      SalesOrderResModel.ResponseJson.class
    );

    System.assertEquals('200', body.status);
    System.assertEquals(1, body.errors.size());
    System.assertEquals('WARN', body.errors[0].code);
    System.assertEquals(1, body.salesOrders.size());
    System.assertEquals('SO-1', body.salesOrders[0].internalId);
    System.assertEquals('Acme', body.salesOrders[0].entity.getName());
    System.assertEquals('CUST123', body.salesOrders[0].entity.getInternalId());
    System.assertEquals(
      'Widget',
      body.salesOrders[0].itemList.item[0].item.name
    );
    System.assertEquals(
      'SKU123',
      body.salesOrders[0].itemList.item[0].customFieldList.customField[0].value
    );
    System.assertEquals('Ship City', body.salesOrders[0].shippingAddress.city);
    System.assertEquals('Bill City', body.salesOrders[0].billingAddress.city);
  }

  @isTest
  static void validateTypedBody_success() {
    SalesOrderResModel.ResponseJson body = new SalesOrderResModel.ResponseJson();
    body.status = '200';
    body.salesOrders = new List<SalesOrderResModel.SalesOrder>{
      new SalesOrderResModel.SalesOrder()
    };

    Test.startTest();
    SalesOrderValidator.validateTypedBody(body);
    Test.stopTest();
  }

  @isTest
  static void validateTypedBody_null() {
    try {
      SalesOrderValidator.validateTypedBody(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to parse NetSuite response.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_withErrors() {
    SalesOrderResModel.ResponseJson body = new SalesOrderResModel.ResponseJson();
    body.status = '200';
    body.errors = new List<SalesOrderResModel.ErrorDetail>{
      new SalesOrderResModel.ErrorDetail()
    };

    try {
      SalesOrderValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned errors:'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_unexpectedStatus() {
    SalesOrderResModel.ResponseJson body = new SalesOrderResModel.ResponseJson();
    body.status = '500';
    body.salesOrders = new List<SalesOrderResModel.SalesOrder>{
      new SalesOrderResModel.SalesOrder()
    };

    try {
      SalesOrderValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unexpected response status: 500'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_missingSalesOrders() {
    SalesOrderResModel.ResponseJson body = new SalesOrderResModel.ResponseJson();
    body.status = '200';
    body.salesOrders = new List<SalesOrderResModel.SalesOrder>();

    try {
      SalesOrderValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No sales order returned in response.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
