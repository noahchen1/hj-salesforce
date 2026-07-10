@isTest
private class InstructionControllerTest {
  @isTest
  static void saveInstruction_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"9988","owner":{"internalId":"145","name":"Integration User"},"customFieldList":{"customField":[{"scriptId":"custrecord1","valueLookup":{"internalId":"SO-991","name":"Sales Order #SO-991"}},{"scriptId":"custrecord_instruction_comment","value":"Tighten and test all connection points before delivery."}]}}]}'
    };

    String internalId = InstructionController.saveInstruction(
      null,
      '145',
      'SO-991',
      'Tighten and test all connection points before delivery.'
    );

    System.assertEquals('9988', internalId);
  }

  @isTest
  static void getInstructionData_nullSalesOrderId() {
    Boolean didThrow = false;
    try {
      InstructionController.getInstructionData(null);
    } catch (AuraHandledException e) {
      didThrow = true;
    }

    System.assert(didThrow, 'Expected a missing sales order exception');
  }

  @isTest
  static void getInstructionData_noInstructions_returnsEmptyList() {
    breadwinner_ns__BW_Sales_Order__c salesOrder = new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__InternalId__c = 'SO-INSTRUCTION-EMPTY'
    );
    insert salesOrder;

    Test.startTest();
    List<InstructionDataModel.InstructionData> result = InstructionController.getInstructionData(
      salesOrder.Id
    );
    Test.stopTest();

    System.assertEquals(0, result.size());
  }

  @isTest
  static void getInstructionData_success() {
    breadwinner_ns__BW_Sales_Order__c salesOrder = new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__InternalId__c = 'SO-INSTRUCTION-001'
    );
    insert salesOrder;

    insert new breadwinner_ns__BW_Employee__c(
      Name = 'Instruction Employee',
      breadwinner_ns__InternalId__c = 'EMP-INSTRUCTION-001'
    );

    nco_repair_instructions__c instruction = new nco_repair_instructions__c(
      InternalId__c = 'INSTR-INSTRUCTION-001',
      OwnerName__c = 'Instruction Employee',
      nid_record1__c = 'SO-INSTRUCTION-001',
      custrecord_instruction_comment__c = 'Inspect clasp before delivery.',
      ncl_record1__c = salesOrder.Id
    );
    insert instruction;

    Test.startTest();
    List<InstructionDataModel.InstructionData> result = InstructionController.getInstructionData(
      salesOrder.Id
    );
    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals('INSTR-INSTRUCTION-001', result[0].internalId);
    System.assertEquals('EMP-INSTRUCTION-001', result[0].nsEmployeeId);
    System.assertEquals('Instruction Employee', result[0].nsEmployeeName);
    System.assertEquals('SO-INSTRUCTION-001', result[0].nsSoId);
    System.assertEquals(
      'Inspect clasp before delivery.',
      result[0].instruction
    );
  }
}
