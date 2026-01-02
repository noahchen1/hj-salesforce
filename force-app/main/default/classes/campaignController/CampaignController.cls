public with sharing class CampaignController {
  @AuraEnabled
  public static void uploadCampaignMembers(Id campaignId) {
    List<CampaignMember> members = [
      SELECT AccountId, CampaignId
      FROM CampaignMember
      WHERE CampaignId = :campaignId
    ];

    CampaignMemberService.onAfterInsert(members);
  }
}