public with sharing class CommentService {
  public static String saveComment(
    String nsEmployeeId,
    String nsSoId,
    String comment
  ) {
    CommentValidator.validateSaveRequest(nsEmployeeId, nsSoId, comment);

    Map<String, Object> commentRequest = CommentPayloadBuilder.buildCreateRequest(
      nsEmployeeId,
      nsSoId,
      comment
    );

    Map<String, Object> requestPayload = CommentPayloadBuilder.buildCreatePayload(
      commentRequest
    );

    System.debug(
      LoggingLevel.INFO,
      'CommentService.saveComment request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'CommentService.saveComment response: ' + JSON.serialize(response)
    );

    CommentDataModel.CommentData commentData = CommentResHandler.handleResponse(
      response
    );

    return commentData.internalId;
  }

  public static CommentDataModel.CommentData getCommentData(String nsSoId) {
    CommentValidator.validateReadRequest(nsSoId);

    Map<String, Object> requestJSONMap = CommentPayloadBuilder.buildReadRequest(
      nsSoId
    );

    Map<String, Object> requestPayload = CommentPayloadBuilder.buildReadPayload(
      requestJSONMap
    );

    System.debug(
      LoggingLevel.INFO,
      'CommentService.getCommentData request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'CommentService.getCommentData response: ' + JSON.serialize(response)
    );

    return CommentResHandler.handleResponse(response);
  }
}
