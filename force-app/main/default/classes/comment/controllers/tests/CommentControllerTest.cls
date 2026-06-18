@isTest
private class CommentControllerTest {
  @isTest
  static void saveComment_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"9988","owner":{"internalId":"145","name":"Integration User"},"customFieldList":{"customField":[{"scriptId":"custrecord1","valueLookup":{"internalId":"SO-991","name":"Sales Order #SO-991"}},{"scriptId":"custrecord_repair_comments","value":"Repair completed and verified."}]}}]}'
    };

    String internalId = CommentController.saveComment(
      '145',
      'SO-991',
      'Repair completed and verified.'
    );

    System.assertEquals('9988', internalId);
  }

  @isTest
  static void saveComment_missingRequiredField_throws() {
    try {
      CommentController.saveComment(
        null,
        'SO-991',
        'Inspection completed'
      );
      System.assert(
        false,
        'Expected AuraHandledException for missing employee id'
      );
    } catch (AuraHandledException ex) {
      System.assert(ex.getMessage().contains('employee id is required'));
    }
  }

  @isTest
  static void getCommentData_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"9988","owner":{"internalId":"145","name":"Integration User"},"customFieldList":{"customField":[{"scriptId":"custrecord1","valueLookup":{"internalId":"SO-991","name":"Sales Order #SO-991"}},{"scriptId":"custrecord_repair_comments","value":"Read comment back."}]}}]}'
    };

    CommentDataModel.CommentData data = CommentController.getCommentData(
      'SO-991'
    );

    System.assertNotEquals(null, data);
    System.assertEquals('9988', data.internalId);
    System.assertEquals('145', data.nsEmployeeId);
    System.assertEquals('SO-991', data.nsSoId);
    System.assertEquals('Read comment back.', data.comment);
  }

  @isTest
  static void getCommentData_missingId_throws() {
    try {
      CommentController.getCommentData(null);
      System.assert(false, 'Expected AuraHandledException for missing id');
    } catch (AuraHandledException ex) {
      System.assert(ex.getMessage().contains('internal id is required'));
    }
  }
}
