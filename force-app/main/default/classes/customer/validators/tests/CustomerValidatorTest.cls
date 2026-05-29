@isTest
private class CustomerValidatorTest {
  @isTest
  static void validateRawResponse_nullResponse() {
    try {
      CustomerValidator.validateRawResponse(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No response returned from NetSuite'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_invalidRequest() {
    try {
      CustomerValidator.validateRawResponse(
        new Map<String, Object>{
          'validRequest' => false,
          'responseJSON' => '{"status":"200"}'
        }
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage()
          .contains('Invalid request: NetSuite rejected the payload.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_emptyBody() {
    try {
      CustomerValidator.validateRawResponse(
        new Map<String, Object>{ 'validRequest' => true, 'responseJSON' => '' }
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned an empty response body.'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_success() {
    CustomerResModel.ResponseJson body = new CustomerResModel.ResponseJson();

    body.status = '200';
    body.customers = new List<CustomerResModel.customer>{
      new CustomerResModel.customer()
    };

    CustomerValidator.validateTypedBody(body);
  }

  @isTest
  static void validateTypedBody_nullResponse() {
    try {
      CustomerValidator.validateTypedBody(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to parse NetSuite response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errors() {
    CustomerResModel.ResponseJson body = new CustomerResModel.ResponseJson();

    body.status = '200';
    body.errors = new List<CustomerResModel.ErrorDetail>{
      new CustomerResModel.ErrorDetail()
    };

    try {
      CustomerValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned errors'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errorStatus() {
    CustomerResModel.ResponseJson body = new CustomerResModel.ResponseJson();

    body.status = '500';
    body.customers = new List<CustomerResModel.customer>{
      new CustomerResModel.customer()
    };

    try {
      CustomerValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('nexpected response status'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_missingCustomers() {
    CustomerResModel.ResponseJson body = new CustomerResModel.ResponseJson();

    body.status = '200';
    body.customers = new List<CustomerResModel.customer>();

    try {
      CustomerValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No customer returned in response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
