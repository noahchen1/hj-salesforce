public with sharing class NsFileDataModel {
  public class UploadSourceFile {
    @AuraEnabled
    public String name;

    @AuraEnabled
    public String documentId;

    @AuraEnabled
    public String contentVersionId;

    @AuraEnabled
    public String fileUrl;

    public UploadSourceFile() {
    }

    public UploadSourceFile(
      String name,
      String documentId,
      String contentVersionId
    ) {
      this.name = name;
      this.documentId = documentId;
      this.contentVersionId = contentVersionId;
    }
  }

  public class UploadFileResult {
    @AuraEnabled
    public String status;

    @AuraEnabled
    public String internalId;

    @AuraEnabled
    public String fileName;

    @AuraEnabled
    public String responseJSON;

    public UploadFileResult() {
    }
  }
}
