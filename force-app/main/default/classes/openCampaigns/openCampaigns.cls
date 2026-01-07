public with sharing class openCampaigns {
  @AuraEnabled(cacheable=true)
  public static list<CampaignMember> getCampaignMembers() {
    // String query =
    //   'SELECT ' +
    //   'Id, ' +
    //   'Account.Name, ' +
    //   'Account.Email__c, ' +
    //   'Campaign.Name ' +
    //   'FROM ' +
    //   'CampaignMember ';

    // try {
    //   List<CampaignMember> members = Database.query(query);

    //   return members;
    // } catch (Exception err) {
    //   throw new AuraHandledException(err.getMessage());
    // }

    try {
      List<CampaignMember> members = [
        SELECT Id, Account.Name, Account.Email__c, Campaign.Name
        FROM CampaignMember
        WHERE Account.OwnerId = :UserInfo.getUserId()
      ];
      return members;
    } catch (Exception err) {
      throw new AuraHandledException(err.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static void sendCampaignMemberEmails(
    List<Id> memberIds,
    String subject,
    String body
  ) {
    try {
      List<CampaignMember> members = [
        SELECT Id, Account.Email__c
        FROM CampaignMember
        WHERE Id IN :memberIds AND Account.OwnerId = :UserInfo.getUserId()
      ];

      List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

      for (CampaignMember m : members) {
        if (m.Account != null && String.isNotBlank(m.Account.Email__c)) {
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

          mail.setToAddresses(new List<String>{ m.Account.Email__c });
          mail.setSubject(subject == null ? 'Campaign update' : subject);
          mail.setPlainTextBody(body == null ? '' : body);
          mails.add(mail);
        }
      }

      if (!mails.isEmpty())
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);
    } catch (Exception err) {
      throw new AuraHandledException(err.getMessage());
    }
  }
}
