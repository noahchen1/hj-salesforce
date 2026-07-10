@isTest
private class InstructionMapperTest {
  @isTest
  static void deserializeInstructions_success() {
    InstructionDataModel.InstructionData instruction = new InstructionDataModel.InstructionData();
    instruction.internalId = '9988';
    instruction.nsEmployeeId = '145';
    instruction.nsEmployeeName = 'Integration User';
    instruction.nsSoId = 'SO-991';
    instruction.instruction = 'Leave at loading dock';
    instruction.lastModified = Datetime.newInstanceGmt(2026, 7, 10, 15, 30, 0);

    List<InstructionDataModel.InstructionData> result = InstructionMapper.deserializeInstructions(
      JSON.serialize(
        new List<InstructionDataModel.InstructionData>{ instruction }
      )
    );

    System.assertEquals(1, result.size());
    System.assertEquals('9988', result[0].internalId);
    System.assertEquals('145', result[0].nsEmployeeId);
    System.assertEquals('Integration User', result[0].nsEmployeeName);
    System.assertEquals('SO-991', result[0].nsSoId);
    System.assertEquals('Leave at loading dock', result[0].instruction);
    System.assertEquals(instruction.lastModified, result[0].lastModified);
  }

  @isTest
  static void deserializeInstructions_emptyList() {
    List<InstructionDataModel.InstructionData> result = InstructionMapper.deserializeInstructions(
      JSON.serialize(new List<InstructionDataModel.InstructionData>())
    );

    System.assertEquals(0, result.size());
  }

  @isTest
  static void deserializeInstructions_invalidJson() {
    try {
      InstructionMapper.deserializeInstructions('not a json');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Invalid instruction payload'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
