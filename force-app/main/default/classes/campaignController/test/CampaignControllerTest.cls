@isTest
private class CampaignControllerTest {
  @isTest
  static void uploadCampaignMembers_enqueuesQueueable_whenEligibleMembersExist() {
    Campaign camp = new Campaign(
      Name = 'Controller Campaign',
      Send_Campaign_Email__c = true
    );
    insert camp;

    Account acc = new Account(
      Name = 'Controller Account',
      Email__c = 'controller@test.com',
      First_Name__c = 'Controller',
      Last_Name__c = 'User'
    );
    insert acc;

    insert new CampaignMember(
      CampaignId = camp.Id,
      AccountId = acc.Id,
      Status = 'Sent'
    );

    Integer beforeCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    Test.startTest();
    CampaignController.uploadCampaignMembers(camp.Id);
    Test.stopTest();

    Integer afterCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    System.assertEquals(
      1,
      afterCount - beforeCount,
      'Expected one queueable job to be enqueued by uploadCampaignMembers'
    );
  }

  @isTest
  static void uploadCampaignMembers_doesNotEnqueue_whenCampaignHasNoMembers() {
    Campaign emptyCamp = new Campaign(
      Name = 'Empty Controller Campaign',
      Send_Campaign_Email__c = true
    );
    insert emptyCamp;

    Integer beforeCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    Test.startTest();
    CampaignController.uploadCampaignMembers(emptyCamp.Id);
    Test.stopTest();

    Integer afterCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    System.assertEquals(
      0,
      afterCount - beforeCount,
      'Expected no queueable jobs when no campaign members exist'
    );
  }
}
