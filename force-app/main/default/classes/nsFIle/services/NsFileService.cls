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
