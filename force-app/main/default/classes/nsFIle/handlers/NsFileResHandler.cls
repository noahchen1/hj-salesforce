public with sharing class NsFileResHandler {
  public static NsFileDataModel.UploadFileResult handleUploadResponse(
    Map<String, Object> response
  ) {
    NsFileValidator.validateRawResponse(response);

    String jsonStr = extractJson(response);

    NsFileResModel.ResponseJson parsed = (NsFileResModel.ResponseJson) JSON.deserialize(
      jsonStr,
      NsFileResModel.ResponseJson.class
    );

    NsFileValidator.validateTypedBody(parsed);

    NsFileDataModel.UploadFileResult result = new NsFileDataModel.UploadFileResult();
    result.status = parsed.status;
    result.responseJSON = jsonStr;
    result.internalId = parsed.fileInternalId;

    return result;
  }

  private static String extractJson(Map<String, Object> response) {
    Object raw = response.get('responseJSON');
    if (raw == null) {
      raw = response.get('requestJSON');
    }

    return raw instanceof String ? (String) raw : JSON.serialize(raw);
  }
}
