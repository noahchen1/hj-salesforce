public with sharing class InstructionController {
  @AuraEnabled
  public static String saveInstruction(
    String nsEmployeeId,
    String nsSoId,
    String instruction
  ) {
    return InstructionService.saveInstruction(
      nsEmployeeId,
      nsSoId,
      instruction
    );
  }

  @AuraEnabled(cacheable=false)
  public static List<InstructionDataModel.InstructionData> getInstructionData(
    Id salesOrderId
  ) {
    return InstructionService.getInstructionData(salesOrderId);
  }
}
