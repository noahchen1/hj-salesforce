public with sharing class CommentValidator {
  public static void validateSaveRequest(
    String nsEmployeeId,
    String nsSoId,
    String comment
  ) {
    if (String.isBlank(nsEmployeeId)) {
      throw Helpers.buildAuraException('NetSuite employee id is required.');
    }

    if (String.isBlank(nsSoId)) {
      throw Helpers.buildAuraException('NetSuite sales order id is required.');
    }

    if (String.isBlank(comment)) {
      throw Helpers.buildAuraException('Comment is required.');
    }
  }

  public static void validateReadRequest(String nsSoId) {
    if (String.isBlank(nsSoId)) {
      throw Helpers.buildAuraException('SO internal id is required.');
    }
  }

  public static void validateRawResponse(Map<String, Object> response) {
    if (response == null) {
      throw Helpers.buildAuraException('No response returned from NetSuite.');
    }

    Boolean validRequest = (Boolean) response.get('validRequest');

    if (validRequest == null || !validRequest) {
      throw Helpers.buildAuraException(
        'Invalid request: NetSuite rejected the payload.'
      );
    }

    String responseJsonStr = (String) response.get('responseJSON');

    if (String.isBlank(responseJsonStr)) {
      responseJsonStr = (String) response.get('requestJSON');
    }

    if (String.isBlank(responseJsonStr)) {
      throw Helpers.buildAuraException(
        'NetSuite returned an empty response body.'
      );
    }
  }

  public static void validateTypedBody(CommentResModel.ResponseJson response) {
    if (response == null) {
      throw Helpers.buildAuraException('Unable to parse NetSuite response.');
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      throw Helpers.buildAuraException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );
    }

    if (response.status != '200') {
      throw Helpers.buildAuraException(
        'Unexpected response status: ' + response.status
      );
    }

    if (
      response.customObjectRecords == null ||
      response.customObjectRecords.isEmpty()
    ) {
      throw Helpers.buildAuraException(
        'No comment record returned in response.'
      );
    }

    if (String.isBlank(response.customObjectRecords[0].internalId)) {
      throw Helpers.buildAuraException(
        'Comment internal id was not returned.'
      );
    }
  }
}
