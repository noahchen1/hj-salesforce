@isTest
private class InstructionValidatorTest {
  @isTest
  static void validateSaveRequest_success() {
    InstructionValidator.validateSaveRequest('123', 'SO123', 'some text');
  }

  @isTest
  static void validateSaveRequest_missingEmployeeId() {
    try {
      InstructionValidator.validateSaveRequest(null, 'SO123', 'some text');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite employee id is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateSaveRequest_missingSalesOrderId() {
    try {
      InstructionValidator.validateSaveRequest('123', null, 'some text');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite sales order id is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateSaveRequest_missingInstruction() {
    try {
      InstructionValidator.validateSaveRequest('123', 'SO123', '');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Instruction is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateReadRequest_success() {
    InstructionValidator.validateReadRequest('SO123');
  }

  @isTest
  static void validateReadRequest_missingSalesOrderId() {
    try {
      InstructionValidator.validateReadRequest(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('SO internal id is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_nullResponse() {
    try {
      InstructionValidator.validateRawResponse(null);
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
      InstructionValidator.validateRawResponse(
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
  static void validateTypedBody_success() {
    InstructionResModel.ResponseJson body = new InstructionResModel.ResponseJson();
    InstructionResModel.InstructionRecord instruction = new InstructionResModel.InstructionRecord();
    instruction.internalId = '123';

    body.status = '200';
    body.customObjectRecords = new List<InstructionResModel.InstructionRecord>{
      instruction
    };

    InstructionValidator.validateTypedBody(body);
  }

  @isTest
  static void validateTypedBody_nullResponse() {
    try {
      InstructionValidator.validateTypedBody(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to parse NetSuite response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errors() {
    InstructionResModel.ResponseJson body = new InstructionResModel.ResponseJson();

    body.status = '200';
    body.errors = new List<InstructionResModel.ErrorDetail>{
      new InstructionResModel.ErrorDetail()
    };

    try {
      InstructionValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned errors'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errorStatus() {
    InstructionResModel.ResponseJson body = new InstructionResModel.ResponseJson();

    body.status = '500';
    body.customObjectRecords = new List<InstructionResModel.InstructionRecord>{
      new InstructionResModel.InstructionRecord()
    };

    try {
      InstructionValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unexpected response status'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_missingInstruction() {
    InstructionResModel.ResponseJson body = new InstructionResModel.ResponseJson();

    body.status = '200';
    body.customObjectRecords = new List<InstructionResModel.InstructionRecord>();

    try {
      InstructionValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No instruction record returned in response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
