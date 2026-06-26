public with sharing class InstructionController {
  @AuraEnabled
  public static String saveInstruction(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String instruction
  ) {
    return InstructionService.saveInstruction(
      nsInternalId,
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
