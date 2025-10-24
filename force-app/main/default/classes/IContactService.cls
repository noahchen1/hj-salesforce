public with sharing class IContactService {
  public class IContactQueueJob implements Queueable, Database.AllowsCallouts {
    private final String payload;
    private final String campaignName;
    private final String ACCOUNT_ID = '1783773';
    private final String FOLDER_ID = '16264';
    private final String STATUS = 'normal';

    public IContactQueueJob(String payload, String campaignName) {
      this.payload = payload;
      this.campaignName = campaignName;
    }

    public void execute(QueueableContext ctx) {
      String listId = createList();

      if (listId == null)
        return;

      List<IContactModels.SubPayload> subs = createContacts(listId);

      if (!subs.isEmpty())
        subscribeContacts(subs);
    }

    private void prepareRequest(HttpRequest req, String endpoint, String body) {
      req.setEndpoint(endpoint);
      req.setMethod('POST');
      req.setHeader('Accept', 'application/json');
      req.setHeader('Content-Type', 'application/json');
      req.setHeader('API-Version', '2.2');
      req.setBody(body);

      System.debug(LoggingLevel.INFO, 'Preparing request:');
      System.debug(LoggingLevel.INFO, 'Endpoint: ' + endpoint);
      System.debug(LoggingLevel.INFO, 'Body: ' + body);
    }

    private Object sendRequest(HttpRequest req, Type t) {
      Http http = new Http();
      try {
        System.debug(LoggingLevel.INFO, 'Sending HTTP request...');

        HttpResponse res = http.send(req);

        System.debug(
          LoggingLevel.INFO,
          'Response Status: ' + res.getStatusCode()
        );

        System.debug(LoggingLevel.INFO, 'Response Body: ' + res.getBody());

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
          if (t != null && res.getBody() != null) {
            return JSON.deserialize(res.getBody(), t);
          }
          return res.getBody();
        } else {
          System.debug(
            LoggingLevel.WARN,
            'Non-2xx response: ' +
              res.getStatusCode() +
              ' body=' +
              res.getBody()
          );
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'API Error: ' + e.getMessage());
        System.debug(
          LoggingLevel.ERROR,
          'Stack Trace: ' + e.getStackTraceString()
        );
      }

      return null;
    }

    private String createList() {
      String endpoint =
        'callout:IContact' +
        '/icp/a/' +
        ACCOUNT_ID +
        '/c/' +
        FOLDER_ID +
        '/lists/';

      IContactModels.ListPayload payloadObj = new IContactModels.ListPayload();
      payloadObj.name = campaignName;
      payloadObj.description = 'example description';
      payloadObj.emailOwnerOnChange = 0;

      HttpRequest req = new HttpRequest();
      prepareRequest(
        req,
        endpoint,
        JSON.serialize(new List<IContactModels.ListPayload>{ payloadObj })
      );

      Object rawRes = sendRequest(
        req,
        IContactModels.IContactListResponse.class
      );

      IContactModels.IContactListResponse res = (IContactModels.IContactListResponse) rawRes;

      if (res != null && res.lists != null && !res.lists.isEmpty())
        return res.lists[0].listId;
      return null;
    }

    private List<IContactModels.SubPayload> createContacts(String listId) {
      HttpRequest req = new HttpRequest();
      String endpoint =
        'callout:IContact' +
        '/icp/a/' +
        ACCOUNT_ID +
        '/c/' +
        FOLDER_ID +
        '/contacts/';

      prepareRequest(req, endpoint, payload);

      Object rawRes = sendRequest(req, IContactModels.IContactResponse.class);

      IContactModels.IContactResponse res = (IContactModels.IContactResponse) rawRes;

      List<IContactModels.SubPayload> subs = new List<IContactModels.SubPayload>();

      for (IContactModels.IContactContact c : res?.contacts) {
        IContactModels.SubPayload sp = new IContactModels.SubPayload();
        sp.contactId = c.contactId;
        sp.listId = listId;
        sp.status = STATUS;
        subs.add(sp);
      }

      return subs;
    }

    private void subscribeContacts(List<IContactModels.SubPayload> subArr) {
      HttpRequest req = new HttpRequest();

      String endpoint =
        'callout:IContact' +
        '/icp/a/' +
        ACCOUNT_ID +
        '/c/' +
        FOLDER_ID +
        '/subscriptions/';

      prepareRequest(req, endpoint, JSON.serialize(subArr));

      sendRequest(req, null);
    }
  }
}
