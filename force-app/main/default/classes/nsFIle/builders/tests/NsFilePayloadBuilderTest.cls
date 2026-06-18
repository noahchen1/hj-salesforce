@isTest
private class NsFilePayloadBuilderTest {
  @isTest
  static void buildUploadRequest_setsExpectedFields() {
    String base64Content = EncodingUtil.base64Encode(Blob.valueOf('test-bytes'));

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
  static void buildUploadPayload_setsExpectedActionAndFiles() {
    String base64Content = EncodingUtil.base64Encode(Blob.valueOf('test-bytes'));

    Map<String, Object> fileRequest = NsFilePayloadBuilder.buildUploadRequest(
      'Test',
      base64Content,
      '800',
      'Test.pdf'
    );

    Map<String, Object> payload = NsFilePayloadBuilder.buildUploadPayload(
      fileRequest
    );

    System.assertEquals('1.0', payload.get('version'));
    System.assertEquals('uploadFile', payload.get('action'));
    System.assert(payload.get('requestJSON') != null);

    Map<String, Object> requestJSONMap = (Map<String, Object>) JSON.deserializeUntyped(
      (String) payload.get('requestJSON')
    );

    List<Object> files = (List<Object>) requestJSONMap.get('files');
    System.assertEquals(1, files.size());

    Map<String, Object> filePayload = (Map<String, Object>) files[0];
    System.assertEquals('Test', (String) filePayload.get('caption'));
    System.assertEquals(base64Content, (String) filePayload.get('content'));
    System.assertEquals('Test.pdf', (String) filePayload.get('name'));
  }
}
