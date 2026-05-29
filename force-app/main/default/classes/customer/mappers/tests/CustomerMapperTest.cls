@isTest
private class CustomerMapperTest {
  @isTest
  static void mapCustomer_success() {
    CustomerResModel.customer customer = new CustomerResModel.customer();

    customer.internalId = '12345';

    CustomerDataModel.CustomerData mappedCustomer = CustomerMappers.mapCustomer(
      customer
    );

    System.assertEquals(mappedCustomer.custNsInternalId, customer.internalId);
  }
}
