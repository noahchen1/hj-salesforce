@isTest
private class GetCampaignsTest {
  @isTest
  static void testGetCampaigns_success() {
    Campaign campaign1 = new Campaign(Name = 'Campaign A', IsActive = true);
    Campaign campaign2 = new Campaign(Name = 'Campaign B', IsActive = true);
    insert new List<Campaign>{ campaign1, campaign2 };

    Account acc1 = new Account(
      Name = 'Test Account 1',
      OwnerId = UserInfo.getUserId()
    );
    Account acc2 = new Account(
      Name = 'Test Account 2',
      OwnerId = UserInfo.getUserId()
    );
    insert new List<Account>{ acc1, acc2 };

    CampaignMember member1 = new CampaignMember(
      CampaignId = campaign1.Id,
      AccountId = acc1.Id,
      Status = 'Notsent'
    );

    CampaignMember member2 = new CampaignMember(
      CampaignId = campaign2.Id,
      AccountId = acc2.Id,
      Status = 'Notsent'
    );

    insert new List<CampaignMember>{ member1, member2 };
    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCampaigns();
    Test.stopTest();

    System.assertEquals(
      2,
      options.size(),
      'Should return 2 campaigns for the current user'
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
  }

  @isTest
  static void testGetCampaigns_filtersByOwner() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User otherUser = new User(
      Alias = 'tuser',
      Email = 'testuser@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
    );
    insert otherUser;

    Campaign campaign1 = new Campaign(Name = 'Campaign A', IsActive = true);
    Campaign campaign2 = new Campaign(Name = 'Campaign B', IsActive = true);
    insert new List<Campaign>{ campaign1, campaign2 };

    Account accCurrentUser = new Account(
      Name = 'Test Account Current',
      OwnerId = UserInfo.getUserId()
    );

    Account accOtherUser = new Account(
      Name = 'Test Account Other',
      OwnerId = otherUser.Id
    );
    insert new List<Account>{ accCurrentUser, accOtherUser };

    CampaignMember member1 = new CampaignMember(
      CampaignId = campaign1.Id,
      AccountId = accCurrentUser.Id,
      Status = 'Notsent'
    );

    CampaignMember member2 = new CampaignMember(
      CampaignId = campaign2.Id,
      AccountId = accOtherUser.Id,
      Status = 'Notsent'
    );
    insert new List<CampaignMember>{ member1, member2 };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCampaigns();
    Test.stopTest();

    System.assertEquals(
      1,
      options.size(),
      'Should return only campaigns for accounts owned by current user'
    );
    System.assertEquals(
      campaign1.Id,
      options[0].value,
      'Should return only Campaign A'
    );
  }

  @isTest
  static void testGetCampaigns_emptyResults() {
    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCampaigns();
    Test.stopTest();

    System.assertEquals(0, options.size(), 'Should return empty list');
  }
}
