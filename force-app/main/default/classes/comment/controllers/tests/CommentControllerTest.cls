@isTest
private class CommentControllerTest {
  @isTest
  static void saveComment_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"9988","owner":{"internalId":"145","name":"Integration User"},"customFieldList":{"customField":[{"scriptId":"custrecord1","valueLookup":{"internalId":"SO-991","name":"Sales Order #SO-991"}},{"scriptId":"custrecord_repair_comments","value":"Repair completed and verified."}]}}]}'
    };

    String internalId = CommentController.saveComment(
      null,
      '145',
      'SO-991',
      'Repair completed and verified.'
    );

    System.assertEquals('9988', internalId);
  }

  @isTest
  static void getCommentData_nullSalesOrderId() {
    Boolean didThrow = false;
    try {
      CommentController.getCommentData(null);
    } catch (AuraHandledException e) {
      didThrow = true;
    }

    System.assert(didThrow, 'Expected a missing sales order exception');
  }

  @isTest
  static void getCommentData_noComments_returnsEmptyList() {
    breadwinner_ns__BW_Sales_Order__c salesOrder = new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__InternalId__c = 'SO-COMMENT-EMPTY'
    );
    insert salesOrder;

    Test.startTest();
    List<CommentDataModel.CommentData> result = CommentController.getCommentData(
      salesOrder.Id
    );
    Test.stopTest();

    System.assertEquals(0, result.size());
  }

  @isTest
  static void getCommentData_success() {
    breadwinner_ns__BW_Sales_Order__c salesOrder = new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__InternalId__c = 'SO-COMMENT-001'
    );
    insert salesOrder;

    breadwinner_ns__BW_Employee__c employee = new breadwinner_ns__BW_Employee__c(
      breadwinner_ns__InternalId__c = 'EMP-COMMENT-001'
    );
    insert employee;
    employee = [
      SELECT Name
      FROM breadwinner_ns__BW_Employee__c
      WHERE Id = :employee.Id
    ];

    User commentOwner = new User(
      Alias = 'cmtowner',
      Email = 'comment-owner@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = employee.Name,
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = UserInfo.getProfileId(),
      TimeZoneSidKey = 'America/New_York',
      UserName = 'comment-owner-' + DateTime.now().getTime() + '@example.com'
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert commentOwner;
    }

    nco_repair_comments__c comment = new nco_repair_comments__c(
      InternalId__c = 'COMMENT-001',
      OwnerId = commentOwner.Id,
      nid_record_parent_record__c = 'SO-COMMENT-001',
      custrecord_repair_comments__c = 'Repair comment text',
      ncl_record_parent_record__c = salesOrder.Id
    );
    insert comment;

    Test.startTest();
    List<CommentDataModel.CommentData> result = CommentController.getCommentData(
      salesOrder.Id
    );
    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals('COMMENT-001', result[0].internalId);
    System.assertEquals('EMP-COMMENT-001', result[0].nsEmployeeId);
    System.assertEquals(employee.Name, result[0].nsEmployeeName);
    System.assertEquals('SO-COMMENT-001', result[0].nsSoId);
    System.assertEquals('Repair comment text', result[0].comment);
  }
}
