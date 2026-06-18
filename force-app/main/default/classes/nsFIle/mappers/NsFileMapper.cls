public with sharing class NsFileMapper {
  public static NsFileDataModel.UploadSourceFile deserializeUploadSourceFile(
    String fileDataJson
  ) {
    if (String.isBlank(fileDataJson)) {
      throw Helpers.buildAuraException(
        'Salesforce file metadata JSON is required.'
      );
    }

    try {
      return (NsFileDataModel.UploadSourceFile) JSON.deserialize(
        fileDataJson,
        NsFileDataModel.UploadSourceFile.class
      );
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid file metadate payload: ' + err.getMessage()
      );

      e.setMessage('Invalid file metadate payload: ' + err.getMessage());

      throw e;
    }
  }
}
