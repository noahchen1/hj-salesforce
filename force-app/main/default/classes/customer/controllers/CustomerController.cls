public with sharing class CustomerController {
  @AuraEnabled
  public static String saveCustomer(
    String custNsInternalId,
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred,
    String addressJson
  ) {
    return CustomerService.saveCustomer(
      custNsInternalId,
      isEmailPreferred,
      isPhonePreferred,
      isMessagePreferred,
      addressJson
    );
  }

  @AuraEnabled(cacheable=false)
  public static CustomerDataModel.CustomerData getCustomerData(
    String custNsInternalId
  ) {
    return CustomerService.getCustomerData(custNsInternalId);
  }
}
