public with sharing class NsFileController {
  @AuraEnabled(cacheable=false)
  public static NsFileDataModel.UploadSourceFile createSalesforceFile(
    String fileName,
    String base64Data
  ) {
    return NsFileService.createSalesforceFile(fileName, base64Data);
  }

  @AuraEnabled(cacheable=false)
  public static String uploadFile(
    String caption,
    String folderInternalId,
    String fileDataJson
  ) {
    return NsFileService.uploadFile(caption, folderInternalId, fileDataJson);
  }
}
