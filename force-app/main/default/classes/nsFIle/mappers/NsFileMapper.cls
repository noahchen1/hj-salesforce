public with sharing class NsFileMapper {
  public static NsFileDataModel.UploadSourceFile deserializeUploadSourceFile(
    String fileDataJson
  ) {
    if (String.isBlank(fileDataJson)) {
      throw Helpers.buildAuraException('Salesforce file metadata JSON is required.');
    }

    try {
      Object raw = JSON.deserializeUntyped(fileDataJson);
      if (!(raw instanceof Map<String, Object>)) {
        throw Helpers.buildAuraException(
          'Salesforce file metadata JSON must be an object.'
        );
      }

      Map<String, Object> payload = (Map<String, Object>) raw;
      NsFileDataModel.UploadSourceFile fileData = new NsFileDataModel.UploadSourceFile();
      fileData.name = (String) payload.get('name');
      fileData.documentId = (String) payload.get('documentId');
      fileData.contentVersionId = (String) payload.get('contentVersionId');
      fileData.contentBodyId = (String) payload.get('contentBodyId');
      fileData.mimeType = (String) payload.get('mimeType');

      return fileData;
    } catch (AuraHandledException ex) {
      throw ex;
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid file metadata payload.'
      );
      e.setMessage('Invalid file metadata payload.');
      throw e;
    }
  }
}
