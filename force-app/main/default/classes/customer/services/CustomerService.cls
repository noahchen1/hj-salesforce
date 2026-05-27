public with sharing class CustomerService {
  public static String saveCustomer(
    String custNsInternalId,
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred
  ) {
    Map<String, Object> customerRequest = CustomerPayloadBuilder.buildSaveRequest(
      custNsInternalId,
      isEmailPreferred,
      isPhonePreferred,
      isMessagePreferred
    );

    Map<String, OBject> requestPayload = CustomerPayloadBuilder.buildSavePayload(
      customerRequest,
      true
    );

    System.debug(
      LoggingLevel.INFO,
      'CustomerService.saveCustomer request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'CustomerService.saveCustomer response: ' + JSON.serialize(response)
    );

    CustomerDataModel.CustomerData customer = CustomerResHandler.handleResponse(
      response
    );

    return customer.custNsInternalId;
  }
}
