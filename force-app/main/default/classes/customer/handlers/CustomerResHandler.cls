public with sharing class CustomerResHandler {
  public static CustomerDataModel.CustomerData handleResponse(
    Map<String, Object> response
  ) {
    CustomerValidator.validateRawResponse(response);

    String jsonStr = extractJson(response);

    CustomerResModel.ResponseJson parsed = (CustomerResModel.ResponseJson) JSON.deserialize(
      jsonStr,
      CustomerResModel.ResponseJson.class
    );

    CustomerValidator.validateTypedBody(parsed);

    CustomerResModel.customer customer = parsed.customers[0];

    return CustomerMappers.mapCustomer(customer);
  }

  private static String extractJson(Map<String, Object> response) {
    Object raw = response.get('responseJSON');

    return raw instanceof String ? (String) raw : JSON.serialize(raw);
  }
}
