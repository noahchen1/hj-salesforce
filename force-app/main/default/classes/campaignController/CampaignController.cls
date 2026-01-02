public with sharing class CampaignController {
  @AuraEnabled
  public static void runIcontactAction(Id campaignId) {
    List<CampaignMember> members = [
      SELECT AccountId, CampaignId
      FROM CampaignMember
      WHERE CampaignId = :campaignId
    ];

    System.debug('Members: ' + members);
  }
}
