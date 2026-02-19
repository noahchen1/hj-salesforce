public with sharing class openCampaigns {
  @AuraEnabled(cacheable=true)
  public static List<CampaignMember> getCampaignMembers(String campaignId) {
    try {
      String query =
        'SELECT ' +
        'Id, ' +
        'Account.Name, ' +
        'Account.Email__c, ' +
        'Campaign.Name ' +
        'FROM ' +
        'CampaignMember ' +
        'WHERE Account.OwnerId = \'' +
        UserInfo.getUserId() +
        '\'';

      if (String.isNotEmpty(campaignId)) {
        query += ' AND Campaign.Id = :campaignId';
      }

      List<CampaignMember> members = Database.query(query);

      return members;
    } catch (Exception err) {
      throw new AuraHandledException(err.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static String getTemplateHtml(String subject, String body) {
    if (String.isEmpty(subject) || String.isEmpty(body))
      return null;

    String templateHtml =
      '<!DOCTYPE html>\n' +
      '<html>\n' +
      '<head>\n' +
      '  <style>\n' +
      '    #container { font-size: 10pt; }\n' +
      '    #personalization-container p { display: inline; margin: 0; padding: 0; }\n' +
      '  </style>\n' +
      '</head>\n' +
      '<body>\n' +
      '  <div id=\"container\">\n' +
      '    {templateContent}' +
      '    <p>\n' +
      '      Hamilton Jewelers<br>\n' +
      '      Princeton, NJ | Palm Beach, FL\n' +
      '    </p>\n' +
      '    <p>\n' +
      '      The Gardens Mall<br>\n' +
      '      3101 P.G.A. Boulevard<br>\n' +
      '      Palm Beach Gardens, FL 33410<br>\n' +
      '      T: 561.775.3600<br>\n' +
      '      E: <br>\n' +
      '      <a href=\"http://www.hamiltonjewelers.com\">www.hamiltonjewelers.com</a>\n' +
      '    </p>\n' +
      '    <p>\n' +
      '      Follow us:<br>\n' +
      '      <a href=\"https://www.facebook.com/HamiltonJeweler\"><img width=\"15\" height=\"17\" src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Facebook_f_logo_%282019%29.svg/1200px-Facebook_f_logo_%282019%29.svg.png\" alt=\"Facebook\"></a>&nbsp;\n' +
      '      <a href=\"https://www.instagram.com/hamiltonjewelers\"><img width=\"15\" height=\"17\" src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Instagram_icon.png/1200px-Instagram_icon.png\" alt=\"Instagram\"></a>&nbsp;\n' +
      '      <a href=\"https://www.linkedin.com/company/102695/admin\"><img width=\"15\" height=\"17\" src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/LinkedIn_logo_initials.png/600px-LinkedIn_logo_initials.png\" alt=\"LinkedIn\"></a>&nbsp;\n' +
      '      <a href=\"https://www.youtube.com/user/HamiltonJewelers\"><img width=\"15\" height=\"17\" src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/YouTube_icon_%282013-2017%29.png/480px-YouTube_icon_%282013-2017%29.png\" alt=\"YouTube\"></a>\n' +
      '    </p>\n' +
      '    <p>&copy; 2026 Hamilton Co., Jewelers. All Rights Reserved</p>\n' +
      '    <p style=\"font-size: small;\">\n' +
      '      The information contained in this e-mail message is confidential - please do not cross-post. This communication is intended for the use of the addressee(s) only. If you are not the intended recipient, you are hereby notified that any review, reliance, disclosure, distribution, or copying of this communication may be prohibited by law and might constitute a breach of confidence. If you have received this communication in error, please notify us immediately and delete it and all copies (including attachments) from your system.\n' +
      '    </p>\n' +
      '  </div>\n' +
      '</body>\n' +
      '</html>';

    return templateHtml.replace('{templateContent}', body);
  }

  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> sendCampaignMemberEmails(
    List<Id> memberIds,
    String subject,
    String body
  ) {
    String template = getTemplateHtml(subject, body);

    try {
      List<CampaignMember> members = [
        SELECT Id, Account.Email__c, Account.Name
        FROM CampaignMember
        WHERE Id IN :memberIds AND Account.OwnerId = :UserInfo.getUserId()
      ];

      List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
      List<String> recipients = new List<String>();

      for (CampaignMember m : members) {
        if (m.Account != null && String.isNotBlank(m.Account.Email__c)) {
          String accountName = m.Account.Name;
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

          mail.setToAddresses(new List<String>{ m.Account.Email__c });
          mail.setSubject(subject == null ? 'Campaign update' : subject);
          mail.setHtmlBody(template == null ? '' : template);
          mails.add(mail);
          recipients.add(accountName);
        }
      }

      if (mails.isEmpty())
        return null;

      List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);

      List<Map<String, Object>> response = new List<Map<String, Object>>();

      Integer n = Math.min(results.size(), recipients.size());
      for (Integer i = 0; i < n; i++) {
        Messaging.SendEmailResult result = results[i];

        List<String> errs = new List<String>();
        if (result != null && result.getErrors() != null) {
          for (Messaging.SendEmailError err : result.getErrors()) {
            errs.add(err.getMessage());
          }
        }

        response.add(
          new Map<String, Object>{
            'recipient' => recipients[i],
            'success' => (result != null && result.isSuccess()),
            'errors' => errs
          }
        );
      }

      return response;
    } catch (Exception err) {
      throw new AuraHandledException(err.getMessage());
    }
  }
}
