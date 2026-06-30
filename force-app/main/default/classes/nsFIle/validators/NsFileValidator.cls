public with sharing class NsFileValidator {
  public static void validateUploadRequest(
    String caption,
    String folderInternalId,
    NsFileDataModel.UploadSourceFile fileData
  ) {
    if (String.isBlank(caption)) {
      throw Helpers.buildAuraException('File caption is required.');
    }

    if (String.isBlank(folderInternalId)) {
      throw Helpers.buildAuraException('NetSuite folder id is required.');
    }

    if (fileData == null) {
      throw Helpers.buildAuraException('Salesforce file metadata is required.');
    }

    if (String.isBlank(fileData.contentVersionId)) {
      throw Helpers.buildAuraException('ContentVersion id is required.');
    }

    if (String.isBlank(fileData.name)) {
      throw Helpers.buildAuraException('File name is required.');
    }

    if (String.isBlank(fileData.fileUrl)) {
      throw Helpers.buildAuraException('File URL is required.');
    }

    if (!fileData.fileUrl.toLowerCase().startsWith('http')) {
      throw Helpers.buildAuraException('File URL must be absolute.');
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

  public static void validateTypedBody(NsFileResModel.ResponseJson response) {
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
  }
}
