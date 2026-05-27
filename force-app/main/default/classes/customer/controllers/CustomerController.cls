public with sharing class CustomerController {
  @AuraEnabled
  public static String saveCustomer(
    String custNsInternalId,
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred
  ) {
    return CustomerService.saveCustomer(
      custNsInternalId,
      isEmailPreferred,
      isPhonePreferred,
      isMessagePreferred
    );
  }
}
