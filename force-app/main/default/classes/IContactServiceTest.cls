@isTest
private class IContactServiceTest {
  private class IContactServiceMockSuccess implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();

      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);

      Boolean isListReq = req.getEndpoint().endsWith('/lists/');
      Boolean isContactReq = req.getEndpoint().endsWith('/contacts/');
      Boolean isSubReq = req.getEndpoint().endsWith('/subscriptions/');

      if (isListReq) {
        res.setBody(
          '{"lists":[{"listId":"12345","name":"Test List","description":"example description"}]}'
        );
      } else if (isContactReq) {
        res.setBody(
          '{"contacts":[{"contactId":"c1","firstName":"John","lastName":"Doe","email":"john@example.com"}]}'
        );
      } else if (isSubReq) {
        res.setBody(
          '{"contacts":[{"contactId":"c1","firstName":"John","lastName":"Doe","email":"john@example.com"}]}'
        );
      } else {
        res.setBody('{}');
      }

      return res;
    }
  }

  private class IContactServiceMockListCreationFails implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();

      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);

      Boolean isListReq = req.getEndpoint().endsWith('/lists/');

      if (isListReq) {
        res.setBody('{"lists":[]}');
      } else {
        res.setBody('{}');
      }

      return res;
    }
  }

  private class IContactServiceMockNoContactsReturned implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();

      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);

      Boolean isListReq = req.getEndpoint().endsWith('/lists/');
      Boolean isContactReq = req.getEndpoint().endsWith('/contacts/');

      if (isListReq) {
        res.setBody(
          '{"lists":[{"listId":"12345","name":"Test List","description":"example description"}]}'
        );
      } else if (isContactReq) {
        res.setBody('{"contacts":[]}');
      } else {
        res.setBody('{}');
      }

      return res;
    }
  }

  private class IContactServiceMockThrows implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      throw new CalloutException('Simulated callout failure');
    }
  }

  @isTest
  static void testQueueJob_Success() {
    String payload = '[{"firstName":"John","lastName":"Doe","email":"john@example.com"}]';
    String campaignName = 'Test Campaign';
    Boolean didThrow = false;

    Test.setMock(HttpCalloutMock.class, new IContactServiceMockSuccess());

    try {
      Test.startTest();
      System.enqueueJob(
        new IContactService.IContactQueueJob(payload, campaignName)
      );
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job executed without exceptions');
  }

  @isTest
  static void testQueueJob_ListCreationFails() {
    String payload = '[{"firstName":"John","lastName":"Doe","email":"john@example.com"}]';
    String campaignName = 'Test Campaign';
    Boolean didThrow = false;

    Test.setMock(
      HttpCalloutMock.class,
      new IContactServiceMockListCreationFails()
    );

    try {
      Test.startTest();
      System.enqueueJob(
        new IContactService.IContactQueueJob(payload, campaignName)
      );
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job handled missing list gracefully');
  }

  @isTest
  static void testQueueJob_NoContactsReturned() {
    String payload = '[{"firstName":"John","lastName":"Doe","email":"john@example.com"}]';
    String campaignName = 'Test Campaign';
    Boolean didThrow = false;

    Test.setMock(
      HttpCalloutMock.class,
      new IContactServiceMockNoContactsReturned()
    );

    try {
      Test.startTest();
      System.enqueueJob(
        new IContactService.IContactQueueJob(payload, campaignName)
      );
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job handlded no contacts gracefully');
  }

  @isTest
  static void testSendRequest_Exception() {
    String payload = '[{"firstName":"John","lastName":"Doe","email":"john@example.com"}]';
    String campaignName = 'Test Campaign';
    Boolean didThrow = false;

    Test.setMock(HttpCalloutMock.class, new IContactServiceMockThrows());

    try {
      Test.startTest();
      System.enqueueJob(
        new IContactService.IContactQueueJob(payload, campaignName)
      );
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Exception in sendRequest was handled');
  }
}
