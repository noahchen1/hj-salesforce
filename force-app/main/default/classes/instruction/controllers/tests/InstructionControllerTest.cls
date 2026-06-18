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

  @isTest
  static void getInstructionData_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"9988","owner":{"internalId":"145","name":"Integration User"},"customFieldList":{"customField":[{"scriptId":"custrecord1","valueLookup":{"internalId":"SO-991","name":"Sales Order #SO-991"}},{"scriptId":"custrecord_instruction_comment","value":"Read me back."}]}}]}'
    };

    InstructionDataModel.InstructionData data = InstructionController.getInstructionData(
      '9988'
    );

    System.assertNotEquals(null, data);
    System.assertEquals('9988', data.internalId);
    System.assertEquals('145', data.nsEmployeeId);
    System.assertEquals('SO-991', data.nsSoId);
    System.assertEquals('Read me back.', data.instruction);
  }

  @isTest
  static void getInstructionData_missingId_throws() {
    try {
      InstructionController.getInstructionData(null);
      System.assert(false, 'Expected AuraHandledException for missing id');
    } catch (AuraHandledException ex) {
      System.assert(ex.getMessage().contains('internal id is required'));
    }
  }
}
