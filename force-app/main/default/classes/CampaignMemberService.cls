public with sharing class CampaignMemberService {
  // private class IContactContact {
  //   private String contactId;
  //   private String firstName;
  //   private String lastName;
  //   private String email;
  // }

  // private class IContactResponse {
  //   public List<IContactContact> contacts;
  // }

  // private class IContactSubscription {
  //   private String contactId;
  //   private String listId;
  //   private String status;
  // }

  // private class ListPayload {
  //   public String name;
  //   public String description;
  //   public Integer emailOwnerOnChange;
  // }

  // private class IContactList {
  //   private String listId;
  //   private String name;
  //   private String description;
  // }

  // private class IContactListResposne {
  //   public List<IContactList> lists;
  // }

  // private class SubPayload {
  //   private String contactId;
  //   private String listId;
  //   private String status;
  // }

  public static void onAfterInsert(List<CampaignMember> newMembers) {
    if (newMembers == null || newMembers.isEmpty())
      return;

    Set<Id> campaignIds = new Set<Id>();

    for (Campaignmember cm : newMembers) {
      if (cm.CampaignId != null)
        campaignIds.add(cm.CampaignId);
    }

    Map<Id, Campaign> campaigns = new Map<Id, Campaign>();

    if (!campaignIds.isEmpty()) {
      campaigns = new Map<Id, Campaign>(
        [
          SELECT Id, Name
          FROM Campaign
          WHERE Id IN :campaignIds
        ]
      );
    }

    Map<String, List<Map<String, Object>>> groupRows = new Map<String, List<Map<String, Object>>>();
    for (CampaignMember cm : newMembers) {
      Map<String, Object> row = new Map<String, Object>();

      String campaignName = campaigns.containsKey(cm.campaignId)
        ? campaigns.get(cm.campaignId).Name
        : null;

      row.put('email', cm.Email);
      row.put('firstName', cm.FirstName);
      row.put('lastName', cm.LastName);

      if (!groupRows.containsKey(campaignName)) {
        groupRows.put(campaignName, new List<Map<String, Object>>());
      }

      groupRows.get(campaignName).add(row);
    }

    for (String nameKey : groupRows.keySet()) {
      String payload = JSON.serialize(groupRows.get(nameKey));
      System.enqueueJob(new IContactService.IContactQueueJob(payload, nameKey));
    }
  }

  //   public class CampaignMemberApiCall implements Queueable, Database.AllowsCallouts {
  //     private String payload;
  //     private String campaignName;

  //     private String ACCOUNT_ID = '1783773';
  //     private String FOLDER_ID = '16264';
  //     private String STATUS = 'normal';

  //     public CampaignMemberApiCall(String payload, String campaignName) {
  //       this.payload = payload;
  //       this.campaignName = campaignName;
  //     }

  //     private String createList() {
  //       HttpRequest req = new HttpRequest();

  //       String endpoint =
  //         'https://app.icontact.com' +
  //         '/icp/a/' +
  //         ACCOUNT_ID +
  //         '/c/' +
  //         FOLDER_ID +
  //         '/lists/';

  //       ListPayload payloadObj = new ListPayload();
  //       payloadObj.name = campaignName;
  //       payloadObj.description = 'example description';
  //       payloadObj.emailOwnerOnChange = 0;

  //       List<ListPayload> listPayload = new List<ListPayload>{ payloadObj };

  //       req.setEndPoint(endpoint);
  //       req.setMethod('POST');
  //       req.setHeader('Accept', 'application/json');
  //       req.setHeader('Content-Type', 'application/json');
  //       req.setHeader('API-Version', '2.2');
  //       req.setHeader('API-AppId', '5e181de6a0c680924b5839c8f32439c2');
  //       req.setHeader('API-Username', 'ajames@hamiltonjewelers.com');
  //       req.setHeader('API-Password', 'HOK26Uf[uLAR)9JxM?#,5w4&IV:]FcrgB!S%Ps7v');
  //       req.setBody(JSON.serialize(listPayload));

  //       Http http = new Http();

  //       try {
  //         HttpResponse res = http.send(req);
  //         Integer statusCode = res.getStatusCode();
  //         String body = res.getBody();

  //         if (statusCode >= 200 && statusCode < 300 && body != null) {
  //           IContactListResposne parsedBody = (IContactListResposne) JSON.deserialize(
  //             body,
  //             IContactListResposne.class
  //           );

  //           if (
  //             parsedBody != null &&
  //             parsedBody.lists != null &&
  //             !parsedBody.lists.isEmpty()
  //           ) {
  //             return parsedBody.lists[0].listId;
  //           }
  //         }
  //       } catch (Exception e) {
  //         System.debug('CampaignMemberApiCall exception: ' + e.getMessage());
  //       }

  //       return null;
  //     }

  //     private List<SubPayload> createContacts(String listId) {
  //       HttpRequest req = new HttpRequest();

  //       String endpoint =
  //         'https://app.icontact.com' +
  //         '/icp/a/' +
  //         ACCOUNT_ID +
  //         '/c/' +
  //         FOLDER_ID +
  //         '/contacts/';

  //       req.setEndPoint(endpoint);
  //       req.setMethod('POST');
  //       req.setHeader('Accept', 'application/json');
  //       req.setHeader('Content-Type', 'application/json');
  //       req.setHeader('API-Version', '2.2');
  //       req.setHeader('API-AppId', '5e181de6a0c680924b5839c8f32439c2');
  //       req.setHeader('API-Username', 'ajames@hamiltonjewelers.com');
  //       req.setHeader('API-Password', 'HOK26Uf[uLAR)9JxM?#,5w4&IV:]FcrgB!S%Ps7v');
  //       req.setBody(payload);

  //       Http http = new Http();

  //       try {
  //         HttpResponse res = http.send(req);
  //         Integer statusCode = res.getStatusCode();
  //         String body = res.getBody();

  //         if (statusCode >= 200 && statusCode < 300 && body != null) {
  //           List<SubPayload> subs = new List<SubPayload>();

  //           IContactResponse parsedBody = (IContactResponse) JSON.deserialize(
  //             body,
  //             IContactResponse.class
  //           );

  //           for (IContactContact c : parsedBody.contacts) {
  //             System.debug(
  //               'contactId=' +
  //                 c.contactId +
  //                 ' email=' +
  //                 c.email +
  //                 ' name=' +
  //                 c.firstName +
  //                 ' ' +
  //                 c.lastName
  //             );

  //             SubPayload newSub = new SubPayload();
  //             newSub.contactId = c.contactId;
  //             newSub.listId = listId;
  //             newSub.status = this.STATUS;

  //             subs.add(newSub);
  //           }

  //           return subs;
  //         }
  //       } catch (Exception e) {
  //         System.debug('CampaignMemberApiCall exception: ' + e.getMessage());
  //       }

  //       return null;
  //     }

  //     private void subscribeContacts(List<SubPayload> subArr) {
  //       HttpRequest req = new HttpRequest();

  //       String endpoint =
  //         'https://app.icontact.com' +
  //         '/icp/a/' +
  //         ACCOUNT_ID +
  //         '/c/' +
  //         FOLDER_ID +
  //         '/subscriptions/';

  //       req.setEndPoint(endpoint);
  //       req.setMethod('POST');
  //       req.setHeader('Accept', 'application/json');
  //       req.setHeader('Content-Type', 'application/json');
  //       req.setHeader('API-Version', '2.2');
  //       req.setHeader('API-AppId', '5e181de6a0c680924b5839c8f32439c2');
  //       req.setHeader('API-Username', 'ajames@hamiltonjewelers.com');
  //       req.setHeader('API-Password', 'HOK26Uf[uLAR)9JxM?#,5w4&IV:]FcrgB!S%Ps7v');
  //       req.setBody(JSON.serialize(subArr));

  //       Http http = new Http();

  //       try {
  //         HttpResponse res = http.send(req);
  //         Integer statusCode = res.getStatusCode();
  //         String body = res.getBody();

  //         System.debug(body);
  //       } catch (Exception e) {
  //         System.debug('CampaignMemberApiCall exception: ' + e.getMessage());
  //       }
  //     }

  //     public void execute(QueueableContext context) {
  //       String listId = createList();

  //       List<SubPayload> subArr = createContacts(listId);

  //       System.debug(subArr);

  //       subscribeContacts(subArr);
  //     }
  //   }
}
