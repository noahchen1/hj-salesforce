@isTest
private class NsFileControllerTest {
  private static String createUploadSourceFileJson(Boolean includeFileUrl) {
    ContentVersion version = new ContentVersion(
      Title = 'STD claim packet',
      PathOnClient = 'STD claim packet.pdf',
      VersionData = Blob.valueOf('fake-pdf-bytes')
    );
    insert version;

    version = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :version.Id
      LIMIT 1
    ];

    Map<String, Object> fileData = new Map<String, Object>{
      'name' => 'STD claim packet.pdf',
      'documentId' => (String) version.ContentDocumentId,
      'contentVersionId' => (String) version.Id
    };

    if (includeFileUrl) {
      fileData.put('fileUrl', 'https://example.com/STD-claim-packet.pdf');
    }

    return JSON.serialize(fileData);
  }

  @isTest
  static void createSalesforceFile_success() {
    NsFileDataModel.UploadSourceFile result = NsFileController.createSalesforceFile(
      'photo.jpg',
      EncodingUtil.base64Encode(Blob.valueOf('fake-image-bytes'))
    );

    System.assertEquals('photo.jpg', result.name);
    System.assertNotEquals(null, result.documentId);
    System.assertNotEquals(null, result.contentVersionId);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM ContentVersion
        WHERE Id = :result.contentVersionId
      ]
    );
  }

  @isTest
  static void uploadFile_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"fileInternalId":"1876"}'
    };

    String fileDataJson = createUploadSourceFileJson(true);

    String result = NsFileController.uploadFile('Test', '800', fileDataJson);

    System.assertNotEquals(null, result);
    System.assertEquals('1876', result);
  }

  @isTest
  static void createContentDistributionUrl_success() {
    ContentVersion version = new ContentVersion(
      Title = 'STD claim packet',
      PathOnClient = 'STD claim packet.pdf',
      VersionData = Blob.valueOf('fake-pdf-bytes')
    );
    insert version;

    String result = NsFileService.createContentDistributionUrl(
      'STD claim packet.pdf',
      version.Id
    );

    System.assertNotEquals(null, result);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM ContentDistribution
      ]
    );
  }
}
