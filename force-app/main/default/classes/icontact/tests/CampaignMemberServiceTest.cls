@isTest
private class CampaignMemberServiceTest {
  @isTest
  static void testOnAfterInsert_success() {
    Campaign camp = new Campaign(
      Name = 'Test Campaign',
      Send_Campaign_Email__c = true
    );
    insert camp;

    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 2; i++) {
      accounts.add(
        new Account(
          Name = 'Account' + i,
          Account_Email__c = 'test' + i + '@test.com',
          First_Name__c = 'First' + i,
          Last_Name__c = 'Last' + i
        )
      );
    }
    insert accounts;

    List<CampaignMember> members = new List<CampaignMember>();
    for (Account acc : accounts) {
      members.add(
        new CampaignMember(
          CampaignId = camp.Id,
          AccountId = acc.Id,
          Status = 'Sent'
        )
      );
    }

    Test.startTest();
    CampaignMemberService.onAfterInsert(members);
    Test.stopTest();

    System.assertEquals(
      1,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should enqueue one job'
    );
  }

  @isTest
  static void testOnAfterInsert_multipleCampaign() {
    Campaign camp1 = new Campaign(
      Name = 'Test Campaign 1',
      Send_Campaign_Email__c = true
    );
    Campaign camp2 = new Campaign(
      Name = 'Test Campaign 2',
      Send_Campaign_Email__c = true
    );
    insert new List<Campaign>{ camp1, camp2 };

    Account acc1 = new Account(
      Name = 'Account1',
      Account_Email__c = 'test1@test.com',
      First_Name__c = 'First1',
      Last_Name__c = 'Last1'
    );
    Account acc2 = new Account(
      Name = 'Account2',
      Account_Email__c = 'test2@test.com',
      First_Name__c = 'First2',
      Last_Name__c = 'Last2'
    );
    insert new List<Account>{ acc1, acc2 };

    List<CampaignMember> members = new List<CampaignMember>{
      new CampaignMember(
        CampaignId = camp1.Id,
        AccountId = acc1.Id,
        Status = 'Sent'
      ),
      new CampaignMember(
        CampaignId = camp2.Id,
        AccountId = acc2.Id,
        Status = 'Sent'
      )
    };

    Test.startTest();
    CampaignMemberService.onAfterInsert(members);
    Test.stopTest();

    System.assertEquals(
      2,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should enqueue two jobs'
    );
  }

  @isTest
  static void testOnAfterInsert_doNotSendEmail() {
    Campaign testCampaign = new Campaign(
      Name = 'Test Campaign',
      Send_Campaign_Email__c = false
    );
    insert testCampaign;

    Account testAccount = new Account(
      Name = 'Test Account',
      Account_Email__c = 'test1@test.com',
      First_Name__c = 'First1',
      Last_Name__c = 'Last1'
    );
    insert testAccount;

    List<CampaignMember> members = new List<CampaignMember>{
      new CampaignMember(
        CampaignId = testCampaign.Id,
        AccountId = testAccount.Id,
        Status = 'Sent'
      )
    };

    Test.startTest();
    CampaignMemberService.onAfterInsert(members);
    Test.stopTest();

    Integer numCampaign = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    System.assertEquals(0, numCampaign, 'Should equal 0 job');
  }

  @isTest
  static void testOnAfterInsert_emptyList() {
    Test.startTest();
    CampaignMemberService.onAfterInsert(new List<CampaignMember>());
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should not enqueue any jobs'
    );
  }

  @isTest
  static void testOnAfterInsert_nullList() {
    Test.startTest();
    CampaignMemberService.onAfterInsert(null);
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should not enqueue any jobs'
    );
  }

  @isTest
  static void testOnAfterInsert_missingCampaignId() {
    Account acc = new Account(
      Name = 'No Campaign Account',
      Account_Email__c = 'no-campaign@example.com',
      First_Name__c = 'No',
      Last_Name__c = 'Campaign'
    );
    insert acc;

    CampaignMember cm = new CampaignMember(AccountId = acc.Id, Status = 'Sent');

    List<CampaignMember> members = new List<CampaignMember>{ cm };

    Test.startTest();
    CampaignMemberService.onAfterInsert(members);
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should not enqueue any jobs'
    );
  }

  @isTest
  static void testOnAfterInsert_campaignIdNotInMap() {
    Account acc = new Account(
      Name = 'Ghost Account',
      Account_Email__c = 'ghost@example.com',
      First_Name__c = 'Ghost',
      Last_Name__c = 'Campaign'
    );
    insert acc;

    Id fakeCampaignId = '701000000000000AAA';

    CampaignMember cm = new CampaignMember(
      CampaignId = fakeCampaignId,
      AccountId = acc.Id,
      Status = 'Sent'
    );

    List<CampaignMember> members = new List<CampaignMember>{ cm };

    Test.startTest();
    CampaignMemberService.onAfterInsert(members);
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should enqueue no job when campaign is missing'
    );
  }
}