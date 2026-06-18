@isTest
private class CommentValidatorTest {
  @isTest
  static void validateSaveRequest_success() {
    CommentValidator.validateSaveRequest('123', 'SO123', 'some text');
  }

  @isTest
  static void validateSaveRequest_missingEmployeeId() {
    try {
      CommentValidator.validateSaveRequest(null, 'SO123', 'some text');
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
      CommentValidator.validateSaveRequest('123', null, 'some text');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite sales order id is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateSaveRequest_missingComment() {
    try {
      CommentValidator.validateSaveRequest('123', 'SO123', '');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Comment is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_nullResponse() {
    try {
      CommentValidator.validateRawResponse(null);
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
      CommentValidator.validateRawResponse(
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
    CommentResModel.ResponseJson body = new CommentResModel.ResponseJson();
    CommentResModel.CommentRecord comment = new CommentResModel.CommentRecord();
    comment.internalId = '123';

    body.status = '200';
    body.customObjectRecords = new List<CommentResModel.CommentRecord>{
      comment
    };

    CommentValidator.validateTypedBody(body);
  }

  @isTest
  static void validateTypedBody_nullResponse() {
    try {
      CommentValidator.validateTypedBody(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to parse NetSuite response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errors() {
    CommentResModel.ResponseJson body = new CommentResModel.ResponseJson();

    body.status = '200';
    body.errors = new List<CommentResModel.ErrorDetail>{
      new CommentResModel.ErrorDetail()
    };

    try {
      CommentValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned errors'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errorStatus() {
    CommentResModel.ResponseJson body = new CommentResModel.ResponseJson();

    body.status = '500';
    body.customObjectRecords = new List<CommentResModel.CommentRecord>{
      new CommentResModel.CommentRecord()
    };

    try {
      CommentValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unexpected response status'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_missingComment() {
    CommentResModel.ResponseJson body = new CommentResModel.ResponseJson();

    body.status = '200';
    body.customObjectRecords = new List<CommentResModel.CommentRecord>();

    try {
      CommentValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('No comment record returned in response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
