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
}
