public with sharing class CustomerPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    String custNsInternalId,
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    requestMap.put('internalId', custNsInternalId);

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{
        'customField' => buildCustomFields(
          isEmailPreferred,
          isPhonePreferred,
          isMessagePreferred
        )
      }
    );

    return requestMap;
  }

  public static Map<String, Object> buildSavePayload(
    Map<String, Object> customerRequest,
    Boolean isUpdate
  ) {
    List<Object> customers = new List<Object>{ customerRequest };

    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'customers' => customers
    };

    String requestJson = JSON.serialize(requestJsonMap);

    return isUpdate
      ? new Map<String, Object>{
          'version' => '1.0',
          'action' => 'updateCustomer',
          'RequestJSON' => requestJson
        }
      : new Map<String, Object>{
          'version' => '1.0',
          'action' => 'createCustomer',
          'RequestJSON' => requestJson
        };
  }

  private static List<Object> buildCustomFields(
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred
  ) {
    List<Object> customFields = new List<Object>();

    customFields.add(
      new Map<String, Object>{
        'fieldType' => 'boolean',
        'scriptId' => 'custentity_email_perferred',
        'value' => isEmailPreferred
      }
    );

    customFields.add(
      new Map<String, Object>{
        'fieldType' => 'boolean',
        'scriptId' => 'custentity_call_perferred',
        'value' => isPhonePreferred
      }
    );

    customFields.add(
      new Map<String, Object>{
        'fieldType' => 'boolean',
        'scriptId' => 'custentity_text_msg_perferred',
        'value' => isMessagePreferred
      }
    );

    return customFields;
  }
}
