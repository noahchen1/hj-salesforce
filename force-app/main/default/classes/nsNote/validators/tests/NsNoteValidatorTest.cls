@isTest
private class NsNoteValidatorTest {
  @isTest
  static void validateSaveRequest_success() {
    NsNoteValidator.validateSaveRequest('EMP-001', 'SO-001', 'Note content');
  }

  @isTest
  static void validateSaveRequest_missingEmployeeId() {
    try {
      NsNoteValidator.validateSaveRequest(null, 'SO-001', 'Note content');
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
      NsNoteValidator.validateSaveRequest('EMP-001', null, 'Note content');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite sales order id is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateSaveRequest_missingContent() {
    try {
      NsNoteValidator.validateSaveRequest('EMP-001', 'SO-001', '');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Note is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_nullResponse() {
    try {
      NsNoteValidator.validateRawResponse(null);
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
      NsNoteValidator.validateRawResponse(
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
  static void validateRawResponse_requestJsonFallback() {
    NsNoteValidator.validateRawResponse(
      new Map<String, Object>{
        'validRequest' => true,
        'requestJSON' => '{"status":"200"}'
      }
    );
  }

  @isTest
  static void validateRawResponse_emptyResponse() {
    try {
      NsNoteValidator.validateRawResponse(
        new Map<String, Object>{ 'validRequest' => true }
      );
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned an empty response body'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_success() {
    NsNoteResModel.ResponseJson body = new NsNoteResModel.ResponseJson();
    NsNoteResModel.NoteRecord note = new NsNoteResModel.NoteRecord();
    note.internalId = 'NOTE-001';
    body.status = '200';
    body.customObjectRecords = new List<NsNoteResModel.NoteRecord>{ note };

    NsNoteValidator.validateTypedBody(body);
  }

  @isTest
  static void validateTypedBody_nullResponse() {
    try {
      NsNoteValidator.validateTypedBody(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to parse NetSuite response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errors() {
    NsNoteResModel.ResponseJson body = new NsNoteResModel.ResponseJson();
    body.status = '200';
    body.errors = new List<NsNoteResModel.ErrorDetail>{
      new NsNoteResModel.ErrorDetail()
    };

    try {
      NsNoteValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned errors'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errorStatus() {
    NsNoteResModel.ResponseJson body = new NsNoteResModel.ResponseJson();
    body.status = '500';
    body.customObjectRecords = new List<NsNoteResModel.NoteRecord>{
      new NsNoteResModel.NoteRecord()
    };

    try {
      NsNoteValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unexpected response status'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_missingNote() {
    NsNoteResModel.ResponseJson body = new NsNoteResModel.ResponseJson();
    body.status = '200';
    body.customObjectRecords = new List<NsNoteResModel.NoteRecord>();

    try {
      NsNoteValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No custom note record returned'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_missingNoteInternalId() {
    NsNoteResModel.ResponseJson body = new NsNoteResModel.ResponseJson();
    body.status = '200';
    body.customObjectRecords = new List<NsNoteResModel.NoteRecord>{
      new NsNoteResModel.NoteRecord()
    };

    try {
      NsNoteValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Custom note internal id was not returned'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
