public with sharing class NsFileService {
  public static String uploadFile(
    String caption,
    String folderInternalId,
    String fileDataJson
  ) {
    NsFileDataModel.UploadSourceFile fileData = NsFileMapper.deserializeUploadSourceFile(
      fileDataJson
    );

    NsFileValidator.validateUploadRequest(caption, folderInternalId, fileData);

    ContentVersion sourceVersion;
    try {
      sourceVersion = [
        SELECT Id, VersionData
        FROM ContentVersion
        WHERE Id = :fileData.contentVersionId
        LIMIT 1
      ];
    } catch (Exception ex) {
      throw Helpers.buildAuraException(
        'Unable to load Salesforce file content from ContentVersion: ' +
        ex.getMessage()
      );
    }

    String encodedContent = EncodingUtil.base64Encode(
      sourceVersion.VersionData
    );

    Map<String, Object> nsFileRequest = NsFilePayloadBuilder.buildUploadRequest(
      caption,
      encodedContent,
      folderInternalId,
      fileData.name
    );

    Map<String, Object> requestPayload = NsFilePayloadBuilder.buildUploadPayload(
      nsFileRequest
    );

    System.debug(
      LoggingLevel.INFO,
      'NsFileService.uploadFile request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'NsFileService.uploadFile response: ' + JSON.serialize(response)
    );

    NsFileDataModel.UploadFileResult file = NsFileResHandler.handleUploadResponse(
      response
    );

    return file.internalId;
  }
}
