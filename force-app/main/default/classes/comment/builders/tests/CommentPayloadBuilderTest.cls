@isTest
private class CommentPayloadBuilderTest {
  @isTest
  static void buildSaveRequest_success() {
    Map<String, Object> request = CommentPayloadBuilder.buildCreateRequest(
      '145',
      'SO-991',
      'Repair comment text'
    );

    Map<String, Object> owner = (Map<String, Object>) request.get('owner');
    System.assertEquals('145', (String) owner.get('internalId'));

    Map<String, Object> customFieldList = (Map<String, Object>) request.get(
      'customFieldList'
    );
    List<Object> customFields = (List<Object>) customFieldList.get(
      'customField'
    );

    for (Object obj : customFields) {
      Map<String, Object> field = (Map<String, Object>) obj;

      String fieldId = (String) field.get('scriptId');

      if (fieldId == 'custrecord1') {
        String value = (String) field.get('value');

        System.assertEquals(value, 'SO-991');
      }

      if (fieldId == 'custrecord_repair_comments') {
        String value = (String) field.get('value');

        System.assertEquals(value, 'Repair comment text');
      }
    }
  }

  @isTest
  static void buildSavePayload_success() {
    Map<String, Object> request = CommentPayloadBuilder.buildCreateRequest(
      '145',
      'SO-991',
      'Repair comment text'
    );

    Map<String, Object> payload = CommentPayloadBuilder.buildCreatePayload(
      request
    );

    System.assertEquals(payload.get('action'), 'createCustomObjectRecord');
    System.assert(payload.get('requestJSON') != null);
  }
}
