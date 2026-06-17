@isTest
private class InstructionPayloadBuilderTest {
  @isTest
  static void buildCreateRequest_setsExpectedCustomObjectFields() {
    Map<String, Object> request = InstructionPayloadBuilder.buildCreateRequest(
      '145',
      'SO-991',
      'Leave at loading dock'
    );

    System.assertEquals('Repair Instruction', (String) request.get('name'));
    System.assertEquals(false, request.get('isInactive'));

    Map<String, Object> customFieldList = (Map<String, Object>) request.get(
      'customFieldList'
    );
    List<Object> customFields = (List<Object>) customFieldList.get(
      'customField'
    );

    System.assertEquals(3, customFields.size());

    Map<String, Object> ownerField = (Map<String, Object>) customFields[0];
    Map<String, Object> soField = (Map<String, Object>) customFields[1];
    Map<String, Object> instructionField = (Map<String, Object>) customFields[2];

    System.assertEquals('select', (String) ownerField.get('fieldType'));
    System.assertEquals('owner', (String) ownerField.get('scriptId'));
    System.assertEquals('145', (String) ownerField.get('value'));

    System.assertEquals('string', (String) soField.get('fieldType'));
    System.assertEquals('custrecord1', (String) soField.get('scriptId'));
    System.assertEquals('SO-991', (String) soField.get('value'));

    System.assertEquals('string', (String) instructionField.get('fieldType'));
    System.assertEquals(
      'custrecord_instruction_comment',
      (String) instructionField.get('scriptId')
    );
    System.assertEquals(
      'Leave at loading dock',
      (String) instructionField.get('value')
    );
  }

  @isTest
  static void buildCreatePayload_setsExpectedActionAndRequestKey() {
    Map<String, Object> request = InstructionPayloadBuilder.buildCreateRequest(
      '145',
      'SO-991',
      'Leave at loading dock'
    );

    Map<String, Object> payload = InstructionPayloadBuilder.buildCreatePayload(
      request
    );

    System.assertEquals('1.0', payload.get('version'));
    System.assertEquals('createCustomObjectRecord', payload.get('action'));
    System.assert(payload.get('requestJSON') != null);

    Map<String, Object> requestJSONMap = (Map<String, Object>) JSON.deserializeUntyped(
      (String) payload.get('requestJSON')
    );

    System.assertEquals(
      'customrecord_repair_instructions',
      (String) requestJSONMap.get('customObjectID')
    );
    System.assertEquals(
      1,
      ((List<Object>) requestJSONMap.get('customObjectRecords')).size()
    );
  }
}
