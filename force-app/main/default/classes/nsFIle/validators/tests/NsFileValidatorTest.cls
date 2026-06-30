@isTest
private class NsFileValidatorTest {
  @isTest
  static void validateUploadRequest_success() {
    NsFileDataModel.UploadSourceFile fileData = new NsFileDataModel.UploadSourceFile();
    fileData.contentVersionId = '068WJ00000FyskrYAB';
    fileData.name = 'Test.pdf';
    fileData.fileUrl = 'https://example.com/Test.pdf';

    NsFileValidator.validateUploadRequest('Test', '800', fileData);
  }

  @isTest
  static void validateUploadRequest_missingCaption() {
    try {
      NsFileDataModel.UploadSourceFile fileData = new NsFileDataModel.UploadSourceFile();
      fileData.contentVersionId = '068WJ00000FyskrYAB';
      fileData.name = 'Test.pdf';
      fileData.fileUrl = 'https://example.com/Test.pdf';

      NsFileValidator.validateUploadRequest(null, '800', fileData);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('File caption is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateUploadRequest_missingFolderId() {
    try {
      NsFileDataModel.UploadSourceFile fileData = new NsFileDataModel.UploadSourceFile();
      fileData.contentVersionId = '068WJ00000FyskrYAB';
      fileData.name = 'Test.pdf';
      fileData.fileUrl = 'https://example.com/Test.pdf';

      NsFileValidator.validateUploadRequest('Test', null, fileData);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite folder id is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateUploadRequest_missingFileData() {
    try {
      NsFileValidator.validateUploadRequest('Test', '800', null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Salesforce file metadata is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateUploadRequest_missingFileUrl() {
    try {
      NsFileDataModel.UploadSourceFile fileData = new NsFileDataModel.UploadSourceFile();
      fileData.contentVersionId = '068WJ00000FyskrYAB';
      fileData.name = 'Test.pdf';

      NsFileValidator.validateUploadRequest('Test', '800', fileData);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('File URL is required'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateUploadRequest_relativeFileUrl() {
    try {
      NsFileDataModel.UploadSourceFile fileData = new NsFileDataModel.UploadSourceFile();
      fileData.contentVersionId = '068WJ00000FyskrYAB';
      fileData.name = 'Test.pdf';
      fileData.fileUrl = '/lightning/r/ContentDocument/069/view';

      NsFileValidator.validateUploadRequest('Test', '800', fileData);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('File URL must be absolute'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateRawResponse_nullResponse() {
    try {
      NsFileValidator.validateRawResponse(null);
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
      NsFileValidator.validateRawResponse(
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
    NsFileResModel.ResponseJson body = new NsFileResModel.ResponseJson();
    body.status = '200';
    body.fileInternalId = '1876';

    NsFileValidator.validateTypedBody(body);
  }

  @isTest
  static void validateTypedBody_nullResponse() {
    try {
      NsFileValidator.validateTypedBody(null);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to parse NetSuite response'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errors() {
    NsFileResModel.ResponseJson body = new NsFileResModel.ResponseJson();
    body.status = '200';
    body.errors = new List<NsFileResModel.ErrorDetail>{
      new NsFileResModel.ErrorDetail()
    };

    try {
      NsFileValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('NetSuite returned errors'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void validateTypedBody_errorStatus() {
    NsFileResModel.ResponseJson body = new NsFileResModel.ResponseJson();
    body.status = '500';

    try {
      NsFileValidator.validateTypedBody(body);
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unexpected response status'),
        'Unexpected error: ' + e.getMessage()
      );
    }
  }
}
