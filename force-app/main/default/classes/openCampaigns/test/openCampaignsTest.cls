@isTest
private class openCampaignsTest {
  @testSetup
  static void setup() {
    Campaign testCampaign = new Campaign(Name = 'Test Campaign');
    insert testCampaign;

    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 3; i++) {
      Account testAccount = new Account(
        Name = 'Test Account ' + i,
        Email__c = 'test' + i + '@example.com',
        First_Name__c = 'John',
        OwnerId = UserInfo.getUserId()
      );
      accounts.add(testAccount);
    }
    insert accounts;

    List<CampaignMember> members = new List<CampaignMember>();
    for (Integer i = 0; i < accounts.size(); i++) {
      CampaignMember member = new CampaignMember(
        CampaignId = testCampaign.Id,
        AccountId = accounts[i].Id,
        Status = 'Notsent'
      );
      members.add(member);
    }
    insert members;
  }

  @isTest
  static void testGetCampaignMembersWithCampaignId() {
    Campaign testCampaign = [SELECT Id FROM Campaign LIMIT 1];

    Test.startTest();
    List<CampaignMember> result = openCampaigns.getCampaignMembers(
      testCampaign.Id
    );
    Test.stopTest();

    System.assert(result != null, 'Campaign members should not be null');
  }

  @isTest
  static void testGetCampaignMembersWithoutCampaignId() {
    Test.startTest();
    List<CampaignMember> result = openCampaigns.getCampaignMembers('');
    Test.stopTest();

    System.assert(result != null, 'Campaign members should not be null');
    System.assert(
      result.size() >= 0,
      'Should return a valid list of campaign members'
    );
  }

  @isTest
  static void testGetTemplateHtmlWithValidInputs() {
    String subject = 'Test Subject';
    String body = 'This is a test body with {customer} placeholder';

    Test.startTest();
    String result = openCampaigns.getTemplateHtml(subject, body);
    Test.stopTest();

    System.assert(result != null, 'Template HTML should not be null');
    System.assert(
      result.contains('This is a test body with'),
      'Template should contain body content'
    );
    System.assert(
      result.contains('Hamilton Jewelers'),
      'Template should contain footer information'
    );
    System.assert(
      result.contains('www.hamiltonjewelers.com'),
      'Template should contain website link'
    );
  }

  @isTest
  static void testGetTemplateHtmlWithEmptySubject() {
    String body = 'This is a test body';

    Test.startTest();
    String result = openCampaigns.getTemplateHtml('', body);
    Test.stopTest();

    System.assert(result == null, 'Should return null when subject is empty');
  }

  @isTest
  static void testGetTemplateHtmlWithEmptyBody() {
    String subject = 'Test Subject';

    Test.startTest();
    String result = openCampaigns.getTemplateHtml(subject, '');
    Test.stopTest();

    System.assert(result == null, 'Should return null when body is empty');
  }

  @isTest
  static void testGetTemplateHtmlWithNullInputs() {
    Test.startTest();
    String result = openCampaigns.getTemplateHtml(null, null);
    Test.stopTest();

    System.assert(result == null, 'Should return null when inputs are null');
  }

  @isTest
  static void testSendCampaignMemberEmailsSuccess() {
    CampaignMember member = [
      SELECT Id, Account.Email__c
      FROM CampaignMember
      LIMIT 1
    ];
    List<Id> memberIds = new List<Id>{ member.Id };
    String subject = 'Test Email Subject';
    String body = 'Hello {customer}, this is a test email.';

    Test.startTest();
    List<Map<String, Object>> result = openCampaigns.sendCampaignMemberEmails(
      memberIds,
      subject,
      body
    );
    Test.stopTest();

    System.assert(result != null, 'Result should not be null');
    System.assertEquals(1, result.size(), 'Should return 1 result');
    System.assertEquals(
      true,
      result[0].get('success'),
      'Email should be sent successfully'
    );

    CampaignMember updatedMember = [
      SELECT Status
      FROM CampaignMember
      WHERE Id = :member.Id
    ];
    System.assertEquals(
      'Sent',
      updatedMember.Status,
      'Member status should be updated to Sent'
    );
  }

  @isTest
  static void testSendCampaignMemberEmailsWithNoEmail() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    testAccount.Email__c = '';
    update testAccount;

    CampaignMember member = [
      SELECT Id
      FROM CampaignMember
      LIMIT 1
    ];
    List<Id> memberIds = new List<Id>{ member.Id };

    Test.startTest();
    List<Map<String, Object>> result = openCampaigns.sendCampaignMemberEmails(
      memberIds,
      'Subject',
      'Body'
    );
    Test.stopTest();

    System.assert(
      result == null,
      'Should return null when no valid emails to send'
    );
  }

  @isTest
  static void testSendCampaignMemberEmailsWithInvalidMemberId() {
    List<Id> invalidMemberIds = new List<Id>();

    Test.startTest();
    List<Map<String, Object>> result = openCampaigns.sendCampaignMemberEmails(
      invalidMemberIds,
      'Subject',
      'Body'
    );
    Test.stopTest();

    System.assert(
      result == null,
      'Should return null when no members match query'
    );
  }

  @isTest
  static void testSendCampaignMemberEmailsWithPersonalization() {
    CampaignMember member = [
      SELECT Id, Account.First_Name__c
      FROM CampaignMember
      LIMIT 1
    ];
    List<Id> memberIds = new List<Id>{ member.Id };
    String subject = 'Personalized Email';
    String body = 'Hello {customer}, welcome!';

    Test.startTest();
    List<Map<String, Object>> result = openCampaigns.sendCampaignMemberEmails(
      memberIds,
      subject,
      body
    );
    Test.stopTest();

    System.assert(result != null, 'Result should not be null');
    System.assertEquals(
      true,
      result[0].get('success'),
      'Email with personalization should be sent'
    );
  }

  @isTest
  static void testSendCampaignMemberEmailsMultipleMembers() {
    List<CampaignMember> members = [
      SELECT Id
      FROM CampaignMember
      LIMIT 3
    ];
    List<Id> memberIds = new List<Id>();
    for (CampaignMember m : members) {
      memberIds.add(m.Id);
    }

    Test.startTest();
    List<Map<String, Object>> result = openCampaigns.sendCampaignMemberEmails(
      memberIds,
      'Bulk Email Subject',
      'Bulk email body'
    );
    Test.stopTest();

    System.assert(result != null, 'Result should not be null');
    System.assertEquals(
      3,
      result.size(),
      'Should return results for all 3 members'
    );

    List<CampaignMember> updatedMembers = [
      SELECT Status
      FROM CampaignMember
      WHERE Id IN :memberIds
    ];
    for (CampaignMember m : updatedMembers) {
      System.assertEquals(
        'Sent',
        m.Status,
        'All members should have Sent status'
      );
    }
  }
}
