public with sharing class NsFileService {
  public static NsFileDataModel.UploadSourceFile createSalesforceFile(
    String fileName,
    String base64Data
  ) {
    if (String.isBlank(fileName)) {
      throw Helpers.buildAuraException('File name is required.');
    }

    if (String.isBlank(base64Data)) {
      throw Helpers.buildAuraException('File data is required.');
    }

    Integer extensionIndex = fileName.lastIndexOf('.');
    String title = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;

    ContentVersion version = new ContentVersion(
      Title = title,
      PathOnClient = fileName,
      VersionData = EncodingUtil.base64Decode(base64Data)
    );

    insert version;

    version = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :version.Id
      LIMIT 1
    ];

    return new NsFileDataModel.UploadSourceFile(
      fileName,
      version.ContentDocumentId,
      version.Id
    );
  }

  public static String uploadFile(
    String caption,
    String folderInternalId,
    String fileDataJson
  ) {
    NsFileDataModel.UploadSourceFile fileData = NsFileMapper.deserializeUploadSourceFile(
      fileDataJson
    );

    NsFileValidator.validateUploadRequest(caption, folderInternalId, fileData);

    Map<String, Object> nsFileRequest = NsFilePayloadBuilder.buildUploadRequest(
      caption,
      fileData.fileUrl,
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

  @AuraEnabled(cacheable=false)
  public static String createContentDistributionUrl(
    String fileName,
    Id contentVersionId
  ) {
    ContentDistribution distribution = new ContentDistribution(
      Name = fileName,
      ContentVersionId = contentVersionId,
      PreferencesAllowOriginalDownload = true,
      PreferencesAllowViewInBrowser = true,
      PreferencesLinkLatestVersion = true,
      PreferencesNotifyOnVisit = false
    );

    insert distribution;

    distribution = [
      SELECT ContentDownloadUrl, DistributionPublicUrl
      FROM ContentDistribution
      WHERE Id = :distribution.Id
      LIMIT 1
    ];

    return distribution.ContentDownloadUrl;
  }
}
