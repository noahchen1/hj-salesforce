public with sharing class openCampaigns {
  @AuraEnabled(cacheable=true)
  public static list<CampaignMember> getCampaignMembers() {
    String query =
      'SELECT ' +
      'Id, ' +
      'Account.Name, ' +
      'Account.Email__c, ' +
      'Campaign.Name ' +
      'FROM ' +
      'CampaignMember ';

    try {
      List<CampaignMember> members = Database.query(query);

      return members;
    } catch (Exception err) {
      throw new AuraHandledException(err.getMessage());
    }
  }
}
