public with sharing class NsNoteResHandler {
  public static NsNoteDataModel.NsNoteData handleResponse(
    Map<String, Object> response
  ) {
    NsNoteValidator.validateRawResponse(response);

    String jsonStr = extractJson(response);

    NsNoteResModel.ResponseJson parsed = (NsNoteResModel.ResponseJson) JSON.deserialize(
      jsonStr,
      NsNoteResModel.ResponseJson.class
    );

    NsNoteValidator.validateTypedBody(parsed);

    NsNoteResModel.NoteRecord record = parsed.customObjectRecords[0];

    NsNoteDataModel.NsNoteData result = new NsNoteDataModel.NsNoteData();

    result.internalId = record.internalId;

    // if (
    //   record.customFieldList != null &&
    //   record.customFieldList.customField != null
    // ) {
    //   for (
    //     NsNoteResModel.CustomField field : record.customFieldList.customField
    //   ) {
    //     if (field == null || String.isBlank(field.scriptId)) {
    //       continue;
    //     }
    //   }
    // }

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
