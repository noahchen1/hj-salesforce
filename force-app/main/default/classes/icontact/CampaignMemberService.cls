public with sharing class CampaignMemberService {
  public static void onAfterInsert(List<CampaignMember> newMembers) {
    if (newMembers == null || newMembers.isEmpty())
      return;

    Set<Id> campaignIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();

    for (Campaignmember cm : newMembers) {
      if (cm.CampaignId != null)
        campaignIds.add(cm.CampaignId);

      if (cm.AccountId != null)
        accountIds.add(cm.AccountId);
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

    Map<Id, Map<String, Object>> accountMap = new Map<Id, Map<String, Object>>();

    if (!accountIds.isEmpty()) {
      for (Account acc : [
        SELECT Id, Account_Email__c, First_Name__c, Last_Name__c
        FROM Account
        WHERE Id IN :accountIds
      ]) {
        Map<String, Object> acctValueMap = new Map<String, Object>();

        acctValueMap.put('email', acc.Account_Email__c);
        acctValueMap.put('firstName', acc.First_Name__c);
        acctValueMap.put('lastName', acc.Last_Name__c);

        accountMap.put(acc.Id, acctValueMap);
      }
    }

    Map<String, List<Map<String, Object>>> groupRows = new Map<String, List<Map<String, Object>>>();
    for (CampaignMember cm : newMembers) {
      if (cm.CampaignId == null)
        continue;

      String campaignName = campaigns.containsKey(cm.campaignId)
        ? campaigns.get(cm.campaignId).Name
        : null;

      Boolean sendEmail = campaigns.containsKey(cm.campaignId)
        ? campaigns.get(cm.campaignId).Send_Campaign_Email__c
        : false;

      if (sendEmail && campaignName != null) {
        Map<String, Object> row = accountMap.get(cm.AccountId);

        if (row != null) {
          if (!groupRows.containsKey(campaignName)) {
            groupRows.put(campaignName, new List<Map<String, Object>>());
          }

          groupRows.get(campaignName).add(row);
        }
      }
    }

    for (String nameKey : groupRows.keySet()) {
      String payload = JSON.serialize(groupRows.get(nameKey));
      System.enqueueJob(new IContactService.IContactQueueJob(payload, nameKey));
    }
  }
}
