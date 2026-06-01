public with sharing class CustomerService {
  public static String saveCustomer(
    String custNsInternalId,
    Boolean isEmailPreferred,
    Boolean isPhonePreferred,
    Boolean isMessagePreferred,
    String addressJson
  ) {
    CustomerDataModel.Address address = CustomerMappers.deserializeAddress(
      addressJson
    );

    Map<String, Object> customerRequest = CustomerPayloadBuilder.buildSaveRequest(
      custNsInternalId,
      isEmailPreferred,
      isPhonePreferred,
      isMessagePreferred,
      address
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

  public static CustomerDataModel.CustomerData getCustomerData(
     String custNsInternalId
  ) {
    if (custNsInternalId == null) {
      throw new AuraHandledException('Netsuite internal id is required');
    }

    Map<String, Object> requestJSONMap = CustomerPayloadBuilder.buildReadRequest(
      custNsInternalId
    );

    Map<String, Object> reqObj = CustomerPayloadBuilder.buildReadPayload(
      requestJSONMap
    );

    Map<String, Object> response = NetSuiteClient.call(reqObj);

    return CustomerResHandler.handleResponse(response);
  }
}
