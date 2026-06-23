public with sharing class NsFileController {
  @AuraEnabled(cacheable=false)
  public static String uploadFile(
    String caption,
    String folderInternalId,
    String fileDataJson
  ) {
    return NsFileService.uploadFile(caption, folderInternalId, fileDataJson);
  }
}
