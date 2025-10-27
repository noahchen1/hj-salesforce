public with sharing class CampaignMemberService {
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
          SELECT Id, Name, Send_Campaign_Email__c
          FROM Campaign
          WHERE Id IN :campaignIds
        ]
      );
    }

    Map<String, List<Map<String, Object>>> groupRows = new Map<String, List<Map<String, Object>>>();
    for (CampaignMember cm : newMembers) {
      if (cm.CampaignId == null)
        continue;

      Map<String, Object> row = new Map<String, Object>();

      String campaignName = campaigns.containsKey(cm.campaignId)
        ? campaigns.get(cm.campaignId).Name
        : null;

      Boolean sendEmail = campaigns.containsKey(cm.campaignId)
        ? campaigns.get(cm.campaignId).Send_Campaign_Email__c
        : false;

      if (sendEmail) {
        row.put('email', cm.Email);
        row.put('firstName', cm.FirstName);
        row.put('lastName', cm.LastName);

        if (!groupRows.containsKey(campaignName)) {
          groupRows.put(campaignName, new List<Map<String, Object>>());
        }

        groupRows.get(campaignName).add(row);
      }
    }

    for (String nameKey : groupRows.keySet()) {
      String payload = JSON.serialize(groupRows.get(nameKey));
      System.enqueueJob(new IContactService.IContactQueueJob(payload, nameKey));
    }
  }
}
