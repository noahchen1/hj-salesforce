@isTest
private class SalesOrderServiceTest {
  private class SaveSalesServiceMockSuccess implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();

      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);
    }
  }
}
