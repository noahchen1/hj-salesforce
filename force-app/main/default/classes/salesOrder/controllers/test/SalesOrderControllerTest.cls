@isTest
private class SalesOrderControllerTest {
  @testSetup
  static void setupData() {
    Account acct = new Account(Name = 'Sales Order Controller Account');
    insert acct;

    insert new breadwinner_ns__BW_Company__c(
      Name = 'Sales Order Controller Company',
      breadwinner_ns__Entity_Type__c = 'Customer',
      breadwinner_ns__InternalId__c = 'CUST-SO-001',
      breadwinner_ns__Salesforce_Account__c = acct.Id
    );
    insert new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Sales Order Controller Order',
      breadwinner_ns__InternalId__c = 'SO-INT-001'
    );
  }

  private static SalesOrderParamModel.SalesOrderSaveParam buildSaveParams(
    String orderType
  ) {
    SalesOrderDataModel.LineItem item = new SalesOrderDataModel.LineItem();
    item.item = '1234';
    item.quantity = '1';
    item.rate = '20';
    item.amount = '20';

    SalesOrderParamModel.SalesOrderSaveParam params = new SalesOrderParamModel.SalesOrderSaveParam();
    params.orderType = orderType;
    params.custNsInternalId = '123456';
    params.orderDate = Date.today();
    params.salesRep1 = 'Sales Rep1';
    params.subsidiary = '2';
    params.location = '2';
    params.termsNsInternalId = '2';
    params.memo = 'some memo';
    params.lineItemsJson = JSON.serialize(
      new List<SalesOrderDataModel.LineItem>{ item }
    );
    return params;
  }

  private static void setSuccessResponse(String internalId, String memo) {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"salesOrders":[{"internalId":"' +
      internalId +
      '","tranDate":1715558400,"memo":"' +
      memo +
      '","entity":{"name":"Test Cust","internalId":"123456"},"salesRep":{"name":"Sales Rep1","internalId":"SR1"},"subsidiary":{"internalId":"2"},"location":{"internalId":"2"},"itemList":{"item":[]}}]}'
    };
  }

  private class DownloadFilesMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();

      if (req.getEndpoint().endsWith('/unavailable')) {
        res.setStatusCode(404);
        res.setBody('Not found');
        return res;
      }

      res.setStatusCode(200);
      res.setBodyAsBlob(Blob.valueOf('test file bytes'));

      if (req.getEndpoint().endsWith('/invoice')) {
        res.setHeader(
          'Content-Disposition',
          'attachment; filename="invoice-123.pdf"'
        );
      }

      return res;
    }
  }

  @isTest
  static void saveSalesOrder_success() {
    setSuccessResponse('SO-TEST-1', 'ok');

    Test.startTest();
    String soInternalId = SalesOrderController.saveSalesOrder(
      JSON.serialize(buildSaveParams('sales'))
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
    System.assertEquals('Account', SalesOrderController.getObjectName(acct.Id));
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

    Map<String, Object> found = SalesOrderController.getNsCompanyFromAccount(
      acct.Id
    );
    System.assertEquals(company.Id, (Id) found.get('companyId'));
    System.assertEquals(
      company.breadwinner_ns__InternalId__c,
      (String) found.get('internalId')
    );
    System.assertEquals(
      null,
      SalesOrderController.getNsCompanyFromAccount(accountWithoutCompany.Id)
    );
  }

  @isTest
  static void getOrderData_success() {
    breadwinner_ns__BW_Sales_Order__c orderRow = [
      SELECT Id
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE breadwinner_ns__InternalId__c = 'SO-INT-001'
      LIMIT 1
    ];
    setSuccessResponse('SO-READ-001', 'read memo');

    Test.startTest();
    SalesOrderDataModel.SalesOrderData result = SalesOrderController.getOrderData(
      orderRow.Id
    );
    Test.stopTest();

    System.assertEquals('SO-READ-001', result.soNsInternalId);
    System.assertEquals('Test Cust', result.customerName);
    NetSuiteClient.testResponse = null;
  }

  @isTest
  static void getOrderAndNotification_success() {
    breadwinner_ns__BW_Sales_Order__c orderRow = [
      SELECT Id
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE breadwinner_ns__InternalId__c = 'SO-INT-001'
      LIMIT 1
    ];
    System.assertEquals(
      orderRow.Id,
      SalesOrderController.getOrder('SO-INT-001')
    );
    SalesOrderController.notifyOrderSaveStatus(true, 'SO-INT-001', null, null);
  }

  @isTest
  static void getInquiryId_returnsExpectedValues() {
    System.assertEquals(null, SalesOrderController.getInquiryId(null));
    System.assertEquals(
      'CUST-NEW-999_1',
      SalesOrderController.getInquiryId('CUST-NEW-999')
    );

    Account acct = [
      SELECT Id, NetSuiteInternalId__c
      FROM Account
      WHERE Name = 'Sales Order Controller Account'
      LIMIT 1
    ];
    acct.NetSuiteInternalId__c = 'CUST-INQ-TEST-001';
    update acct;
    insert new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__Salesforce_Account__c = acct.Id,
      ncf_body_inquiry_id__c = 'CUST-INQ-TEST-001_3'
    );
    System.assertEquals(
      'CUST-INQ-TEST-001_4',
      SalesOrderController.getInquiryId('CUST-INQ-TEST-001')
    );
  }

  @isTest
  static void saveSalesOrder_inquiryOrder_success() {
    setSuccessResponse('SO-INQ-1', 'inquiry');
    SalesOrderParamModel.SalesOrderSaveParam params = buildSaveParams(
      'inquiry'
    );
    params.inquiryType = String.valueOf(InquiryType.ROLEX);
    params.specialDate = Date.today();
    params.needByDate = Date.today();
    params.specialOrderItemType = '3';
    params.specialOrderMemoOrSold = 'sold';
    params.inquiryId = 'INQ-001';
    params.inquiryModel = 'Model X';
    params.inquiryName = 'Inquiry Name';
    params.inquiryLink = 'http://link.com';
    SalesOrderDataModel.LineItem inquiryItem = new SalesOrderDataModel.LineItem();
    inquiryItem.item = '1234';
    inquiryItem.quantity = '1';
    params.lineItemsJson = JSON.serialize(
      new List<SalesOrderDataModel.LineItem>{ inquiryItem }
    );

    Test.startTest();
    String soInternalId = SalesOrderController.saveSalesOrder(
      JSON.serialize(params)
    );
    Test.stopTest();

    System.assertEquals('SO-INQ-1', soInternalId);
    NetSuiteClient.testResponse = null;
  }

  @isTest
  static void getAttachedFiles_blankUrls_returnsEmptyList() {
    Test.startTest();
    List<NsFileDataModel.UploadSourceFile> files = SalesOrderController.getAttachedFiles(
      ' '
    );
    Test.stopTest();

    System.assertEquals(0, files.size());
  }

  @isTest
  static void getAttachedFiles_downloadsFilesAndSkipsFailedResponses() {
    Test.setMock(HttpCalloutMock.class, new DownloadFilesMock());

    Test.startTest();
    List<NsFileDataModel.UploadSourceFile> files = SalesOrderController.getAttachedFiles(
      'https://files.example.com/invoice, https://files.example.com/unavailable, https://files.example.com/no-header'
    );
    Test.stopTest();

    System.assertEquals(2, files.size());
    System.assertEquals('invoice-123.pdf', files[0].name);
    System.assertEquals('downloaded-file', files[1].name);

    Set<Id> contentVersionIds = new Set<Id>();
    for (NsFileDataModel.UploadSourceFile file : files) {
      System.assertNotEquals(null, file.documentId);
      System.assertNotEquals(null, file.contentVersionId);
      contentVersionIds.add((Id) file.contentVersionId);
    }

    Map<Id, ContentVersion> versionsById = new Map<Id, ContentVersion>(
      [
        SELECT Id, Title, PathOnClient
        FROM ContentVersion
        WHERE Id IN :contentVersionIds
      ]
    );
    System.assertEquals(2, versionsById.size());
    System.assertEquals(
      'invoice-123',
      versionsById.get((Id) files[0].contentVersionId).Title
    );
    System.assertEquals(
      'invoice-123.pdf',
      versionsById.get((Id) files[0].contentVersionId).PathOnClient
    );
    System.assertEquals(
      'downloaded-file',
      versionsById.get((Id) files[1].contentVersionId).Title
    );
  }
}
