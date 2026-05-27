public with sharing class CustomerValidator {
  public static void validateRawResponse(Map<String, Object> response) {
    if (response == null) {
      throw Helpers.buildAuraException('No response returned from NetSuite.');
    }

    Boolean validRequest = (Boolean) response.get('validRequest');
    if (validRequest == null || !validRequest) {
      throw Helpers.buildAuraException(
        'Invalid request: NetSuite rejected the payload.'
      );
    }

    String responseJsonStr = (String) response.get('responseJSON');
    if (String.isBlank(responseJsonStr)) {
      throw Helpers.buildAuraException(
        'NetSuite returned an empty response body.'
      );
    }
  }

  public static void validateTypedBody(CustomerResModel.ResponseJson response) {
    if (response == null) {
      throw Helpers.buildAuraException('Unable to parse NetSuite response.');
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      throw Helpers.buildAuraException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );
    }

    if (response.status != '200') {
      throw Helpers.buildAuraException(
        'Unexpected response status: ' + response.status
      );
    }

    if (response.customers == null || response.customers.isEmpty()) {
      throw Helpers.buildAuraException('No customer returned in response.');
    }
  }
}
