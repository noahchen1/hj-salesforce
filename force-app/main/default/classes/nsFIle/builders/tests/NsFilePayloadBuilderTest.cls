@isTest
private class NsFilePayloadBuilderTest {
  @isTest
  static void buildSaveRequest_success() {
    String base64Content = EncodingUtil.base64Encode(
      Blob.valueOf('test-bytes')
    );

    Map<String, Object> request = NsFilePayloadBuilder.buildUploadRequest(
      'Test',
      base64Content,
      '800',
      'Test.pdf'
    );

    System.assertEquals('Test', (String) request.get('caption'));
    System.assertEquals(base64Content, (String) request.get('content'));
    System.assertEquals('Test.pdf', (String) request.get('name'));

    Map<String, Object> folder = (Map<String, Object>) request.get('folder');
    System.assertEquals('800', (String) folder.get('internalId'));
  }

  @isTest
  static void buildSavePayload_success() {
    String base64Content = EncodingUtil.base64Encode(
      Blob.valueOf('test-bytes')
    );

    Map<String, Object> request = NsFilePayloadBuilder.buildUploadRequest(
      'Test',
      base64Content,
      '800',
      'Test.pdf'
    );

    Map<String, Object> payload = NsFilePayloadBuilder.buildUploadPayload(
      request
    );

    System.assertEquals(payload.get('action'), 'uploadFile');
    System.assert(payload.get('requestJSON') != null);
  }
}
