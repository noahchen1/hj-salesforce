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
}
