@isTest
private class CustomerControllerTest {
  @isTest
  static void saveCustomer_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customers":[{"internalId":"12345"}]}'
    };

    String custNsInternalId = customerController.saveCustomer(
      '12345',
      true,
      true,
      false
    );

    System.assertEquals('12345', custNsInternalId);
  }
}
