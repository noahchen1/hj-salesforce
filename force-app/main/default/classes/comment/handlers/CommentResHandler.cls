public with sharing class CommentResHandler {
  public static CommentDataModel.CommentData handleResponse(
    Map<String, Object> response
  ) {
    CommentValidator.validateRawResponse(response);

    String jsonStr = extractJson(response);

    CommentResModel.ResponseJson parsed = (CommentResModel.ResponseJson) JSON.deserialize(
      jsonStr,
      CommentResModel.ResponseJson.class
    );

    CommentValidator.validateTypedBody(parsed);

    CommentResModel.CommentRecord record = parsed.customObjectRecords[0];

    CommentDataModel.CommentData result = new CommentDataModel.CommentData();

    result.internalId = record.internalId;
    result.nsEmployeeId = record.owner == null ? null : record.owner.internalId;

    if (
      record.customFieldList != null &&
      record.customFieldList.customField != null
    ) {
      for (CommentResModel.CustomField field : record.customFieldList.customField) {
        if (field == null || String.isBlank(field.scriptId)) {
          continue;
        }

        if (field.scriptId == 'custrecord1') {
          result.nsSoId = field.valueLookup == null
            ? field.value
            : field.valueLookup.internalId;
        }

        if (field.scriptId == 'custrecord_repair_comments') {
          result.comment = field.value;
        }
      }
    }

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
