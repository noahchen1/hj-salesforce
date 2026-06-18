public with sharing class NsFileController {
    @AuraEnabled(cacheable=false)
    public static NsFileDataModel.UploadFileResult uploadFile(
        String caption,
        String folderInternalId,
        String fileDataJson
    ) {
        return NsFileService.uploadFile(caption, folderInternalId, fileDataJson);
    }
}