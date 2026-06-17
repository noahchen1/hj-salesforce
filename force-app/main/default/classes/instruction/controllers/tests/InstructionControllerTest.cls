@isTest
private class InstructionControllerTest {
  @isTest
  static void saveInstruction_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"9988","owner":{"internalId":"145","name":"Integration User"},"customFieldList":{"customField":[{"scriptId":"custrecord1","valueLookup":{"internalId":"SO-991","name":"Sales Order #SO-991"}},{"scriptId":"custrecord_instruction_comment","value":"Tighten and test all connection points before delivery."}]}}]}'
    };

    String internalId = InstructionController.saveInstruction(
      '145',
      'SO-991',
      'Tighten and test all connection points before delivery.'
    );

    System.assertEquals('9988', internalId);
  }

  @isTest
  static void saveInstruction_missingRequiredField_throws() {
    try {
      InstructionController.saveInstruction(
        null,
        'SO-991',
        'Inspection required'
      );
      System.assert(
        false,
        'Expected AuraHandledException for missing employee id'
      );
    } catch (AuraHandledException ex) {
      System.assert(ex.getMessage().contains('employee id is required'));
    }
  }
}
