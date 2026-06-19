public with sharing class InstructionMapper {
  public static List<InstructionDataModel.InstructionData> deserializeInstructions(
    String instructionJson
  ) {
    try {
      return (List<InstructionDataModel.InstructionData>) JSON.deserialize(
        instructionJson,
        List<InstructionDataModel.InstructionData>.class
      );
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid instruction payload.'
      );

      e.setMessage('Invalid instruction payload.');

      throw e;
    }
  }
}
