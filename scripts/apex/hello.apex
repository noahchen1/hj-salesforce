Custom_Email_Template__c template = new Custom_Email_Template__c();

template.Subject__c = 'Test Template 1';
template.Type__c = 'Campaign';
template.Template__c =
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
  '    <p>Dear,</p>\n' +
  '    <p>I hope this message finds you well. <span id=\"personalization-container\" style=\"display:inline;\"></span> I am reaching out regarding the Rolex timepieces you have selected. Although they are not currently available, I want to confirm your continued interest.</p>\n' +
  '    <p>When you have a chance, please let me know if you\'d like me to keep working toward these models. I\'ll be happy to notify you as soon as one becomes available.</p>\n' +
  '    <p>If you have any questions or if your preferences have changed, don\'t hesitate to reach out. Please know that we\'re closely monitoring your request and doing our best to secure the piece for you as soon as possible. Your patience and enthusiasm are truly appreciated.</p>\n' +
  '    <p>Best,</p>\n' +
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

  insert template;


