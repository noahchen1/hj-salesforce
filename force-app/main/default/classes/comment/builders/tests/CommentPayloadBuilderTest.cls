@isTest
private class CommentPayloadBuilderTest {
  @isTest
  static void buildCreateRequest_setsExpectedCustomObjectFields() {
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

    System.assertEquals(2, customFields.size());

    Map<String, Object> soField = (Map<String, Object>) customFields[0];
    Map<String, Object> commentField = (Map<String, Object>) customFields[1];

    System.assertEquals('string', (String) soField.get('fieldType'));
    System.assertEquals('custrecord1', (String) soField.get('scriptId'));
    System.assertEquals('SO-991', (String) soField.get('value'));

    System.assertEquals('string', (String) commentField.get('fieldType'));
    System.assertEquals(
      'custrecord_repair_comments',
      (String) commentField.get('scriptId')
    );
    System.assertEquals('Repair comment text', (String) commentField.get('value'));
  }

  @isTest
  static void buildCreatePayload_setsExpectedActionAndRequestKey() {
    Map<String, Object> request = CommentPayloadBuilder.buildCreateRequest(
      '145',
      'SO-991',
      'Repair comment text'
    );

    Map<String, Object> payload = CommentPayloadBuilder.buildCreatePayload(
      request
    );

    System.assertEquals('1.0', payload.get('version'));
    System.assertEquals('createCustomObjectRecord', payload.get('action'));
    System.assert(payload.get('requestJSON') != null);

    Map<String, Object> requestJSONMap = (Map<String, Object>) JSON.deserializeUntyped(
      (String) payload.get('requestJSON')
    );

    System.assertEquals(
      '110',
      (String) requestJSONMap.get('customObjectID')
    );
    System.assertEquals(
      1,
      ((List<Object>) requestJSONMap.get('customObjectRecords')).size()
    );
  }

  @isTest
  static void buildReadPayload_setsExpectedActionAndFilter() {
    Map<String, Object> request = CommentPayloadBuilder.buildReadRequest(
      '9988'
    );

    Map<String, Object> payload = CommentPayloadBuilder.buildReadPayload(
      request
    );

    System.assertEquals('1.0', payload.get('version'));
    System.assertEquals('readCustomObjectRecord', payload.get('action'));
    System.assert(payload.get('requestJSON') != null);

    Map<String, Object> requestJSONMap = (Map<String, Object>) JSON.deserializeUntyped(
      (String) payload.get('requestJSON')
    );

    System.assertEquals('110', (String) requestJSONMap.get('customObjectID'));

    Map<String, Object> customParameters = (Map<String, Object>) requestJSONMap.get(
      'customParameters'
    );
    Map<String, Object> whereMap = (Map<String, Object>) customParameters.get(
      'where'
    );
    Map<String, Object> keyValueMap = (Map<String, Object>) whereMap.get(
      'keyValueMap'
    );

    System.assertEquals('9988', (String) keyValueMap.get('custrecord1'));
  }
}
