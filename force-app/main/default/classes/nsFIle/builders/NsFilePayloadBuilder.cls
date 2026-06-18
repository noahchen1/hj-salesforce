public with sharing class NsFilePayloadBuilder {
  public static Map<String, Object> buildUploadRequest(
    String caption,
    String content,
    String folderInternalId,
    String name
  ) {
    Map<String, Object> nsFile = new Map<String, Object>();

    nsFile.put('caption', caption);
    nsFile.put('content', content);
    nsFile.put('folder', new Map<String, Object>{ 'internalId' => folderInternalId });
    nsFile.put('name', name);

    return nsFile;
  }

  public static Map<String, Object> buildUploadPayload(
    Map<String, Object> nsFileRequest
  ) {
    Map<String, Object> requestJSONMap = new Map<String, Object>();
    requestJSONMap.put('files', new List<Object>{ nsFileRequest });

    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'uploadFile',
      'requestJSON' => JSON.serialize(requestJSONMap)
    };
  }
}
