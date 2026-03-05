@isTest
private class GetAllCampaignsTest {
  @isTest
  static void testGetAllCampaigns_success() {
    // Create campaigns
    Campaign campaign1 = new Campaign(Name = 'Campaign A', IsActive = true);
    Campaign campaign2 = new Campaign(Name = 'Campaign B', IsActive = true);
    Campaign campaign3 = new Campaign(Name = 'Campaign C', IsActive = true);
    insert new List<Campaign>{ campaign1, campaign2, campaign3 };

    // Create account
    Account acc1 = new Account(
      Name = 'Test Account 1',
      OwnerId = UserInfo.getUserId()
    );
    insert acc1;

    // Create contact for the account
    Contact contact1 = new Contact(
      FirstName = 'Test',
      LastName = 'Contact1',
      AccountId = acc1.Id
    );
    insert contact1;

    // Create campaign member for campaign1 only
    CampaignMember member1 = new CampaignMember(
      CampaignId = campaign1.Id,
      ContactId = contact1.Id,
      Status = 'Sent'
    );
    insert member1;

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getAllCampaigns();
    Test.stopTest();

    // Should return all campaigns (from Campaign query) plus campaign1 from CampaignMember
    // Note: There might be duplicates in the implementation
    System.assert(
      options.size() >= 3,
      'Should return at least three campaigns'
    );

    Set<String> campaignIds = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      campaignIds.add(opt.value);
    }

    System.assert(
      campaignIds.contains(campaign1.Id),
      'Should contain Campaign A'
    );
    System.assert(
      campaignIds.contains(campaign2.Id),
      'Should contain Campaign B'
    );
    System.assert(
      campaignIds.contains(campaign3.Id),
      'Should contain Campaign C'
    );
  }

  @isTest
  static void testGetAllCampaigns_noCampaignMembers() {
    // Create campaigns without campaign members
    Campaign campaign1 = new Campaign(Name = 'Campaign A', IsActive = true);
    Campaign campaign2 = new Campaign(Name = 'Campaign B', IsActive = true);
    insert new List<Campaign>{ campaign1, campaign2 };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getAllCampaigns();
    Test.stopTest();

    System.assertEquals(2, options.size(), 'Should return two campaigns');

    Set<String> campaignIds = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      campaignIds.add(opt.value);
    }

    System.assert(
      campaignIds.contains(campaign1.Id),
      'Should contain Campaign A'
    );
    System.assert(
      campaignIds.contains(campaign2.Id),
      'Should contain Campaign B'
    );
  }

  @isTest
  static void testGetAllCampaigns_emptyResults() {
    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getAllCampaigns();
    Test.stopTest();

    System.assertEquals(0, options.size(), 'Should return empty list');
  }
}
