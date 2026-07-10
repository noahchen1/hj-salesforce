@isTest
private class NsNotePayloadBuilderTest {
  @isTest
  static void buildSaveRequest_success() {
    Map<String, Object> request = NsNotePayloadBuilder.buildSaveRequest(
      'NOTE-9988',
      'EMP-001',
      'SO-001',
      'Note content'
    );

    System.assertEquals('NOTE-9988', request.get('internalId'));
    List<Object> customFields = (List<Object>) ((Map<String, Object>) request.get(
        'customFieldList'
      ))
      .get('customField');
    Map<String, Object> valuesByScriptId = new Map<String, Object>();

    for (Object customField : customFields) {
      Map<String, Object> field = (Map<String, Object>) customField;
      valuesByScriptId.put((String) field.get('scriptId'), field.get('value'));
    }

    System.assertEquals(
      'EMP-001',
      valuesByScriptId.get('custrecord_note_history_author')
    );
    System.assertEquals(
      'SO-001',
      valuesByScriptId.get('custrecord_note_history_transaction')
    );
    System.assertEquals(
      'Note content',
      valuesByScriptId.get('custrecord_note_history_content')
    );
  }

  @isTest
  static void buildSavePayload_success() {
    Map<String, Object> request = NsNotePayloadBuilder.buildSaveRequest(
      null,
      'EMP-001',
      'SO-001',
      'Note content'
    );

    Map<String, Object> createPayload = NsNotePayloadBuilder.buildSavePayload(
      request,
      false
    );
    System.assertEquals(
      'createCustomObjectRecord',
      createPayload.get('action')
    );
    System.assert(createPayload.get('requestJSON') != null);

    Map<String, Object> updatePayload = NsNotePayloadBuilder.buildSavePayload(
      request,
      true
    );
    System.assertEquals(
      'updateCustomObjectRecord',
      updatePayload.get('action')
    );
  }
}
