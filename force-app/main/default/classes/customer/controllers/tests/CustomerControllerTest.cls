@isTest
private class CustomerControllerTest {
  @isTest
  static void saveCustomer_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customers":[{"internalId":"12345"}]}'
    };

    CustomerDataModel.Address address = new CustomerDataModel.Address();
    address.internalId = '29188';
    address.addr1 = '2334 N. Michigan Avenue';
    address.addr2 = 'Suite 1500';
    address.city = 'Chicago';
    address.state = 'IL';
    address.zip = '60601';
    address.country = '_unitedStates';
    address.attention = 'Front Desk';
    address.addressee = 'Grand Hotels & Resorts Ltd';
    address.defaultShipping = true;
    address.defaultBilling = false;
    String addressJson = JSON.serialize(address);

    String custNsInternalId = customerController.saveCustomer(
      '12345',
      true,
      true,
      false,
      addressJson
    );

    System.assertEquals('12345', custNsInternalId);
  }

  @isTest
  static void getCustomerData_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customers":[{"internalId":"12345","addressbookList":{"addressbook":[{"internalId":"29188","defaultShipping":true,"defaultBilling":false,"addressbookAddress":{"zip":"60601","state":"IL","country":"_unitedStates","city":"Chicago","attention":"Front Desk","addressee":"Grand Hotels & Resorts Ltd","addr2":"Suite 1500","addr1":"2334 N. Michigan Avenue"}}]}}]}'
    };

    CustomerDataModel.CustomerData customerData = customerController.getCustomerData(
      '12345'
    );

    System.assertNotEquals(null, customerData);
    System.assertEquals('12345', customerData.custNsInternalId);
    System.assertNotEquals(null, customerData.Addresses);
    System.assertEquals(1, customerData.Addresses.size());

    CustomerDataModel.Address address = customerData.Addresses[0];

    System.assertEquals('29188', address.internalId);
    System.assertEquals('2334 N. Michigan Avenue', address.addr1);
    System.assertEquals('Suite 1500', address.addr2);
    System.assertEquals('Chicago', address.city);
    System.assertEquals('IL', address.state);
    System.assertEquals('60601', address.zip);
    System.assertEquals('_unitedStates', address.country);
    System.assertEquals('Front Desk', address.attention);
    System.assertEquals('Grand Hotels & Resorts Ltd', address.addressee);
    System.assertEquals(true, address.defaultShipping);
    System.assertEquals(false, address.defaultBilling);
  }
}
