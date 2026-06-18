public with sharing class InstructionService {
  public static String saveInstruction(
    String nsEmployeeId,
    String nsSoId,
    String instruction
  ) {
    InstructionValidator.validateSaveRequest(nsEmployeeId, nsSoId, instruction);

    Map<String, Object> instructionRequest = InstructionPayloadBuilder.buildCreateRequest(
      nsEmployeeId,
      nsSoId,
      instruction
    );

    Map<String, Object> requestPayload = InstructionPayloadBuilder.buildCreatePayload(
      instructionRequest
    );

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.saveInstruction request: ' +
      JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.saveInstruction response: ' + JSON.serialize(response)
    );

    InstructionDataModel.InstructionData instructionData = InstructionResHandler.handleResponse(
      response
    );

    return instructionData.internalId;
  }

  public static InstructionDataModel.InstructionData getInstructionData(
    String nsSoId
  ) {
    InstructionValidator.validateReadRequest(nsSoId);

    Map<String, Object> requestJSONMap = InstructionPayloadBuilder.buildReadRequest(
      nsSoId
    );

    Map<String, Object> requestPayload = InstructionPayloadBuilder.buildReadPayload(
      requestJSONMap
    );

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.getInstructionData request: ' +
      JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.getInstructionData response: ' +
      JSON.serialize(response)
    );

    return InstructionResHandler.handleResponse(response);
  }
}
