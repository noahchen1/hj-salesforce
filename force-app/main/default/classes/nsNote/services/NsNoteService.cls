public with sharing class NsNoteService {
  public static String saveNote(
    String nsEmployeeId,
    String nsSoId,
    String content
  ) {
    NsNoteValidator.validateSaveRequest(nsEmployeeId, nsSoId, content);

    Map<String, Object> noteReqeust = NsNotePayloadBuilder.buildSaveRequest(
      nsEmployeeId,
      nsSoId,
      content
    );

    Map<String, Object> requestPayload = NsNotePayloadBuilder.buildSavePayload(
      noteReqeust
    );

    System.debug(
      LoggingLevel.INFO,
      'NsNoteService.saveNote request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.saveInstruction response: ' + JSON.serialize(response)
    );

    NsNoteDataModel.NsNoteData noteData = NsNoteResHandler.handleResponse(
      response
    );

    return noteData.internalId;
  }
}
