@isTest
private class NsFileMapperTest {
  @isTest
  static void deserializeUploadSourceFile_success() {
    String json = JSON.serialize(
      new Map<String, Object>{
        'name' => 'STD claim packet.pdf',
        'documentId' => '069WJ00000F8LeXYAV',
        'contentVersionId' => '068WJ00000FyskrYAB',
        'fileUrl' => 'https://example.com/STD-claim-packet.pdf'
      }
    );

    NsFileDataModel.UploadSourceFile result = NsFileMapper.deserializeUploadSourceFile(
      json
    );

    System.assertEquals('STD claim packet.pdf', result.name);
    System.assertEquals('069WJ00000F8LeXYAV', result.documentId);
    System.assertEquals('068WJ00000FyskrYAB', result.contentVersionId);
    System.assertEquals(
      'https://example.com/STD-claim-packet.pdf',
      result.fileUrl
    );
  }

  @isTest
  static void deserializeUploadSourceFile_missingJson() {
    try {
      NsFileMapper.deserializeUploadSourceFile('   ');
      System.assert(false, 'Expected missing file metadata JSON to throw');
    } catch (AuraHandledException e) {
      System.assertEquals(
        'Salesforce file metadata JSON is required.',
        e.getMessage()
      );
    }
  }

  @isTest
  static void deserializeUploadSourceFile_invalidJson() {
    try {
      NsFileMapper.deserializeUploadSourceFile('not valid json');
      System.assert(false, 'Expected invalid file metadata JSON to throw');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().startsWith('Invalid file metadate payload:'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
