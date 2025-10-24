@isTest
private class CampaignMemberServiceTest {
  @isTest
  static void testOnAfterInsert_success() {
    Campaign camp = new Campaign(Name = 'Test Campaign');
    insert camp;

    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < 2; i++) {
      contacts.add(
        new Contact(
          FirstName = 'First' + i,
          LastName = 'Last' + i,
          Email = 'test' + i + '@test.com'
        )
      );
    }
    insert contacts;

    List<CampaignMember> members = new List<CampaignMember>();
    for (Contact c : contacts) {
      members.add(
        new CampaignMember(
          CampaignId = camp.Id,
          ContactId = c.Id,
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
    Campaign camp1 = new Campaign(Name = 'Test Campaign 1');
    Campaign camp2 = new Campaign(Name = 'Test Campaign 2');
    insert new List<Campaign>{ camp1, camp2 };

    Contact c1 = new Contact(
      FirstName = 'First1',
      LastName = 'Last1',
      Email = 'test1@test.com'
    );
    Contact c2 = new Contact(
      FirstName = 'First2',
      LastName = 'Last2',
      Email = 'test2@test.com'
    );
    insert new List<Contact>{ c1, c2 };

    List<CampaignMember> members = new List<CampaignMember>{
      new CampaignMember(
        CampaignId = camp1.Id,
        ContactId = c1.Id,
        Status = 'Sent'
      ),
      new CampaignMember(
        CampaignId = camp2.Id,
        ContactId = c2.Id,
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
    Contact c = new Contact(
      FirstName = 'No',
      LastName = 'Campaign',
      Email = 'no-campaign@example.com'
    );
    insert c;

    CampaignMember cm = new CampaignMember(ContactId = c.Id, Status = 'Sent');

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
    Contact c = new Contact(
      FirstName = 'Ghost',
      LastName = 'Campaign',
      Email = 'ghost@example.com'
    );
    insert c;

    Id fakeCampaignId = '701000000000000AAA';

    CampaignMember cm = new CampaignMember(
      CampaignId = fakeCampaignId,
      ContactId = c.Id,
      Status = 'Sent'
    );

    List<CampaignMember> members = new List<CampaignMember>{ cm };

    Test.startTest();
    CampaignMemberService.onAfterInsert(members);
    Test.stopTest();

    System.assertEquals(
      1,
      [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
      'Should enqueue one job even if campaign is missing'
    );
  }
}
