@isTest
private class InstructionPayloadBuilderTest {
  @isTest
  static void buildSaveRequest_success() {
    Map<String, Object> request = InstructionPayloadBuilder.buildSaveRequest(
      '145',
      '123456',
      'Leave at loading dock'
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

        System.assertEquals(value, '123456');
      }

      if (fieldId == 'custrecord_instruction_comment') {
        String value = (String) field.get('value');

        System.assertEquals(value, 'Leave at loading dock');
      }
    }
  }

  @isTest
  static void buildSavePayload_success() {
    Map<String, Object> request = InstructionPayloadBuilder.buildSaveRequest(
      '12345',
      '67890',
      'This is an instruction!'
    );

    Map<String, Object> payload = InstructionPayloadBuilder.buildSavePayload(
      request
    );

    System.assertEquals(payload.get('action'), 'createCustomObjectRecord');
    System.assert(payload.get('requestJSON') != null);
  }
}
