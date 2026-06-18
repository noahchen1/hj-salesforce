@isTest
private class NsFileMapperTest {
  @isTest
  static void deserializeUploadSourceFile_success() {
    String json = JSON.serialize(new Map<String, Object>{
      'name' => 'STD claim packet.pdf',
      'documentId' => '069WJ00000F8LeXYAV',
      'contentVersionId' => '068WJ00000FyskrYAB',
      'contentBodyId' => '05TWJ00000PvrCU2AZ',
      'mimeType' => 'application/pdf'
    });

    NsFileDataModel.UploadSourceFile result = NsFileMapper.deserializeUploadSourceFile(
      json
    );

    System.assertEquals('STD claim packet.pdf', result.name);
    System.assertEquals('069WJ00000F8LeXYAV', result.documentId);
    System.assertEquals('068WJ00000FyskrYAB', result.contentVersionId);
    System.assertEquals('05TWJ00000PvrCU2AZ', result.contentBodyId);
    System.assertEquals('application/pdf', result.mimeType);
  }

  @isTest
  static void deserializeUploadSourceFile_invalidPayload_throws() {
    try {
      NsFileMapper.deserializeUploadSourceFile('[1,2,3]');
      System.assert(false, 'Expected AuraHandledException for invalid payload');
    } catch (AuraHandledException ex) {
      System.assert(
        ex.getMessage().contains('Invalid file metadata payload.') ||
        ex.getMessage().contains('must be an object'),
        'Expected mapper error message'
      );
    }
  }
}
