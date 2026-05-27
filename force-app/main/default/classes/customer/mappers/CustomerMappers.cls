public with sharing class CustomerMappers {
  public static CustomerDataModel.CustomerData mapCustomer(
    CustomerResModel.customer customer
  ) {
    CustomerDataModel.CustomerData result = new CustomerDataModel.CustomerData();

    result.custNsInternalId = customer.internalId;

    return result;
  }
}
