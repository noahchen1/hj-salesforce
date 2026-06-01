@isTest
private class CustomerPayloadBuilderTest {
  @isTest
  static void buildSaveRequest_success() {
    Map<String, Object> request = CustomerPayloadBuilder.buildSaveRequest(
      '12345',
      true,
      true,
      false,
      null
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
      false,
      null
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

  // @isTest
  // static void buildSaveRequest_withAddress_success() {
  //   CustomerDataModel.Address address = new CustomerDataModel.Address();

  //   address.internalId = '298822';
  //   address.address1 = '610 W Custis Ave';
  //   address.address2 = 'APT 50';
  //   address.city = 'Alexandria';
  //   address.country = '_unitedStates';
  //   address.zipcode = '22301';

  //   Map<String, Object> request = CustomerPayloadBuilder.buildSaveRequest(
  //     '12345',
  //     true,
  //     false,
  //     true,
  //     address
  //   );

  //   Map<String, Object> addressbookList = (Map<String, Object>) request.get(
  //     'addressbookList'
  //   );
  //   List<Object> addressbook = (List<Object>) addressbookList.get('addressbook');
  //   Map<String, Object> addressBookItem = (Map<String, Object>) addressbook[0];
  //   Map<String, Object> addressbookAddress = (Map<String, Object>) addressBookItem.get(
  //     'addressbookAddress'
  //   );

  //   System.assertEquals(false, addressbookList.get('replaceAll'));
  //   System.assertEquals('298822', addressBookItem.get('internalId'));
  //   System.assertEquals('610 W Custis Ave', addressbookAddress.get('addr1'));
  //   System.assertEquals('APT 50', addressbookAddress.get('addr2'));
  //   System.assertEquals('Alexandria', addressbookAddress.get('city'));
  //   System.assertEquals('_unitedStates', addressbookAddress.get('country'));
  //   System.assertEquals('22301', addressbookAddress.get('zip'));
  // }
}
