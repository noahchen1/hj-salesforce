@isTest
private class NsFileControllerTest {
  private static String createUploadSourceFileJson() {
    ContentVersion version = new ContentVersion(
      Title = 'STD claim packet',
      PathOnClient = 'STD claim packet.pdf',
      VersionData = Blob.valueOf('fake-pdf-bytes')
    );
    insert version;

    version = [
      SELECT Id, ContentDocumentId, ContentBodyId
      FROM ContentVersion
      WHERE Id = :version.Id
      LIMIT 1
    ];

    Map<String, Object> fileData = new Map<String, Object>{
      'name' => 'STD claim packet.pdf',
      'documentId' => (String) version.ContentDocumentId,
      'contentVersionId' => (String) version.Id,
      'contentBodyId' => (String) version.ContentBodyId,
      'mimeType' => 'application/pdf'
    };

    return JSON.serialize(fileData);
  }

  @isTest
  static void uploadFile_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"fileInternalId":"1876"}'
    };

    String fileDataJson = createUploadSourceFileJson();

    NsFileDataModel.UploadFileResult result = NsFileController.uploadFile(
      'Test',
      '800',
      fileDataJson
    );

    System.assertNotEquals(null, result);
    System.assertEquals('200', result.status);
    System.assertEquals('1876', result.internalId);
    System.assertEquals(null, result.fileName);
  }

  @isTest
  static void uploadFile_missingRequiredField_throws() {
    try {
      NsFileController.uploadFile(
        null,
        '800',
        '{}'
      );
      System.assert(false, 'Expected AuraHandledException for missing caption');
    } catch (AuraHandledException ex) {
      System.assert(ex.getMessage().contains('caption is required'));
    }
  }
}
