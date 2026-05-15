@isTest
private class SalesOrderControllerTest {
  @testSetup
  static void setupData() {
    Account acct = new Account(Name = 'Sales Order Controller Account');
    insert acct;

    breadwinner_ns__BW_Company__c company = new breadwinner_ns__BW_Company__c(
      Name = 'Sales Order Controller Company',
      breadwinner_ns__Entity_Type__c = 'Customer',
      breadwinner_ns__InternalId__c = 'CUST-SO-001',
      breadwinner_ns__Salesforce_Account__c = acct.Id
    );
    insert company;

    breadwinner_ns__BW_Sales_Order__c orderRow = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Sales Order Controller Order',
      breadwinner_ns__InternalId__c = 'SO-INT-001'
    );
    insert orderRow;
  }

  @isTest
  static void saveSalesOrder_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"salesOrders":[{"internalId":"SO-TEST-1","tranDate":1715558400,"memo":"ok","entity":{"name":"Test Cust","internalId":"123456"},"salesRep":{"name":"Sales Rep1","internalId":"SR1"},"subsidiary":{"internalId":"2"},"location":{"internalId":"2"},"itemList":{"item":[]}}]}'
    };

    Test.startTest();
    SalesOrderDataModel.LineItem item = new SalesOrderDataModel.LineItem();

    item.item = '1234';
    item.quantity = '1';
    item.rate = '20';
    item.amount = '20';

    String soInternalId = SalesOrderController.saveSalesOrder(
      'sales',
      null,
      '123456',
      Date.today(),
      'Sales Rep1',
      null,
      '2',
      '2',
      '2',
      'some memo',
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
      null,
      null,
      null,
      null,
      null,
      JSON.serialize(new List<SalesOrderDataModel.LineItem>{ item })
    );
    Test.stopTest();

    System.assertEquals('SO-TEST-1', soInternalId);
    NetSuiteClient.testResponse = null;
  }

  @isTest
  static void getObjectName_success() {
    Account acct = [
      SELECT Id
      FROM Account
      WHERE Name = 'Sales Order Controller Account'
      LIMIT 1
    ];

    Test.startTest();
    String objectName = SalesOrderController.getObjectName(acct.Id);
    Test.stopTest();

    System.assertEquals('Account', objectName);
  }

  @isTest
  static void getNsCompanyFromAccount_success() {
    Account acct = [
      SELECT Id
      FROM Account
      WHERE Name = 'Sales Order Controller Account'
      LIMIT 1
    ];

    breadwinner_ns__BW_Company__c company = [
      SELECT Id, breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Company__c
      WHERE breadwinner_ns__Salesforce_Account__c = :acct.Id
      LIMIT 1
    ];

    Account accountWithoutCompany = new Account(Name = 'No Company Account');
    insert accountWithoutCompany;

    Test.startTest();
    Map<String, Object> found = SalesOrderController.getNsCompanyFromAccount(
      acct.Id
    );
    Map<String, Object> missing = SalesOrderController.getNsCompanyFromAccount(
      accountWithoutCompany.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, found);
    System.assertEquals(company.Id, (Id) found.get('companyId'));
    System.assertEquals(
      company.breadwinner_ns__InternalId__c,
      (String) found.get('internalId')
    );
    System.assertEquals(null, missing);
  }

  @isTest
  static void getOrderData_success() {
    breadwinner_ns__BW_Sales_Order__c orderRow = [
      SELECT Id
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE breadwinner_ns__InternalId__c = 'SO-INT-001'
      LIMIT 1
    ];

    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"salesOrders":[{"internalId":"SO-READ-001","tranDate":1715558400,"memo":"read memo","entity":{"name":"Test Cust","internalId":"123456"},"itemList":{"item":[]}}]}'
    };

    Test.startTest();
    SalesOrderDataModel.SalesOrderData result = SalesOrderController.getOrderData(
      orderRow.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals('SO-READ-001', result.soNsInternalId);
    System.assertEquals('Test Cust', result.customerName);
    NetSuiteClient.testResponse = null;
  }

  @isTest
  static void notifyOrderSaveStatus_success() {
    Test.startTest();
    SalesOrderController.notifyOrderSaveStatus(true, 'SO-INT-001', null, null);
    Test.stopTest();

    System.assert(true, 'Method should exit without throwing exceptions');
  }
}
