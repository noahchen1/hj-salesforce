public with sharing class CustomerPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    String custNsInternalId,
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred,
    CustomerDataModel.Address address
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

    if (address != null) {
      requestMap.put(
        'addressbookList',
        new Map<String, Object>{
          'addressbook' => buildAddress(address),
          'replaceAll' => false
        }
      );
    }

    return requestMap;
  }

  public static Map<String, Object> buildReadRequest(String custNsInternalId) {
    Map<String, Object> filters = new Map<String, Object>{
      'internalId' => custNsInternalId
    };

    Map<String, Object> filterMap = new Map<String, Object>{
      'where' => new Map<String, Object>{ 'keyValueMap' => filters }
    };

    Map<String, Object> requestJSONMap = new Map<String, Object>{
      'customParameters' => filterMap
    };

    return requestJSONMap;
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

  public static Map<String, Object> buildReadPayload(
    Map<String, Object> request
  ) {
    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'readCustomer',
      'requestJSON' => JSON.serialize(request)
    };
  }

  private static List<Object> buildCustomFields(
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred
  ) {
    List<Object> customFields = new List<Object>();

    if (isEmailPreferred != null) {
      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'boolean',
          'scriptId' => 'custentity_email_perferred',
          'value' => isEmailPreferred
        }
      );
    }

    if (isPhonePreferred != null) {
      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'boolean',
          'scriptId' => 'custentity_call_perferred',
          'value' => isPhonePreferred
        }
      );
    }

    if (isMessagePreferred != null) {
      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'boolean',
          'scriptId' => 'custentity_text_msg_perferred',
          'value' => isMessagePreferred
        }
      );
    }

    return customFields;
  }

  private static List<Object> buildAddress(CustomerDataModel.Address address) {
    List<Object> addressBookList = new List<Object>();
    Map<String, Object> addressBook = new Map<String, Object>();
    Map<String, Object> addressbookAddress = new Map<String, Object>();

    if (String.isNotBlank(address.attention)) {
      addressbookAddress.put('attention', address.attention);
    }

    if (String.isNotBlank(address.addressee)) {
      addressbookAddress.put('addressee', address.addressee);
    }

    if (String.isNotBlank(address.addr1)) {
      addressbookAddress.put('addr1', address.addr1);
    }

    if (String.isNotBlank(address.addr2)) {
      addressbookAddress.put('addr2', address.addr2);
    }

    if (String.isNotBlank(address.city)) {
      addressbookAddress.put('city', address.city);
    }

    if (String.isNotBlank(address.country)) {
      addressbookAddress.put('country', address.country);
    }

    if (String.isNotBlank(address.zip)) {
      addressbookAddress.put('zip', address.zip);
    }

    if (String.isNotBlank(address.state)) {
      addressbookAddress.put('state', address.state);
    }

    if (String.isNotBlank(address.internalId)) {
      addressBook.put('internalId', address.internalId);
    }

    if (address.defaultBilling != null) {
      addressBook.put('defaultBilling', address.defaultBilling);
    }

    if (address.defaultShipping != null) {
      addressBook.put('defaultShipping', address.defaultShipping);
    }

    addressBook.put('addressbookAddress', addressbookAddress);
    addressBookList.add(addressBook);

    return addressBookList;
  }
}
