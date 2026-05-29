@isTest
private class CustomerPayloadBuilderTest {
  @isTest
  static void buildSaveRequest_success() {
    Map<String, Object> request = CustomerPayloadBuilder.buildSaveRequest(
      '12345',
      true,
      true,
      false
    );

    String custNsInternalId = (String) request.get('internalId');
    Map<String, Object> customFieldListMap = (Map<String, Object>) request.get(
      'customFieldList'
    );
    List<Object> customFields = (List<Object>) customFieldListMap.get(
      'customField'
    );

    System.assertEquals('12345', custNsInternalId);

    for (Object obj : customFields) {
      Map<String, Object> item = (Map<String, Object>) obj;

      if ((String) item.get('scriptId') == 'custentity_email_perferred') {
        Boolean value = (Boolean) item.get('value');

        System.assertEquals(value, true);
      }

      if ((String) item.get('scriptId') == 'custentity_call_perferred') {
        Boolean value = (Boolean) item.get('value');

        System.assertEquals(value, true);
      }

      if ((String) item.get('scriptId') == 'custentity_text_msg_perferred') {
        Boolean value = (Boolean) item.get('value');

        System.assertEquals(value, false);
      }
    }
  }

  @isTest
  static void buildSavePayload_success() {
    Map<String, Object> request = CustomerPayloadBuilder.buildSaveRequest(
      '12345',
      true,
      true,
      false
    );

    Map<String, Object> updatePayload = CustomerPayloadBuilder.buildSavePayload(
      request,
      true
    );

    Map<String, Object> createPayload = CustomerPayloadBuilder.buildSavePayload(
      request,
      false
    );

    System.assert(updatePayload.get('RequestJSON') != null);
    System.assertEquals(updatePayload.get('action'), 'updateCustomer');
    System.assertEquals(createPayload.get('action'), 'createCustomer');
  }
}
