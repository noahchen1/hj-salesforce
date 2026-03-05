@isTest
private class GetCustomEmailTemplatesTest {
  @isTest
  static void testGetCustomEmailTemplates_success() {
    Custom_Email_Template__c template1 = new Custom_Email_Template__c(
      Label__c = 'Template A',
      Type__c = 'Marketing'
    );
    Custom_Email_Template__c template2 = new Custom_Email_Template__c(
      Label__c = 'Template B',
      Type__c = 'Marketing'
    );
    Custom_Email_Template__c template3 = new Custom_Email_Template__c(
      Label__c = 'Template C',
      Type__c = 'Sales'
    );
    insert new List<Custom_Email_Template__c>{
      template1,
      template2,
      template3
    };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCustomEmailTemplates(
      'Marketing'
    );
    Test.stopTest();

    System.assertEquals(
      2,
      options.size(),
      'Should return two marketing templates'
    );

    Set<String> templateIds = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      templateIds.add(opt.value);
      System.assertNotEquals(null, opt.label, 'Label should not be null');
    }

    System.assert(
      templateIds.contains(template1.Id),
      'Should contain Template A'
    );
    System.assert(
      templateIds.contains(template2.Id),
      'Should contain Template B'
    );
  }

  @isTest
  static void testGetCustomEmailTemplates_filtersByType() {
    Custom_Email_Template__c template1 = new Custom_Email_Template__c(
      Label__c = 'Template A',
      Type__c = 'Marketing'
    );
    Custom_Email_Template__c template2 = new Custom_Email_Template__c(
      Label__c = 'Template B',
      Type__c = 'Sales'
    );
    insert new List<Custom_Email_Template__c>{ template1, template2 };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCustomEmailTemplates(
      'Sales'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      options.size(),
      'Should return only one sales template'
    );
    System.assertEquals(
      template2.Id,
      options[0].value,
      'Should return Template B'
    );
    System.assertEquals(
      'Template B',
      options[0].label,
      'Label should match template label'
    );
  }

  @isTest
  static void testGetCustomEmailTemplates_emptyResults() {
    Custom_Email_Template__c template1 = new Custom_Email_Template__c(
      Label__c = 'Template A',
      Type__c = 'Marketing'
    );
    insert template1;

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCustomEmailTemplates(
      'Sales'
    );
    Test.stopTest();

    System.assertEquals(
      0,
      options.size(),
      'Should return empty list for non-existent type'
    );
  }

  @isTest
  static void testGetCustomEmailTemplates_nullType() {
    Custom_Email_Template__c template1 = new Custom_Email_Template__c(
      Label__c = 'Template A',
      Type__c = null
    );
    insert template1;

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getCustomEmailTemplates(
      null
    );
    Test.stopTest();

    System.assertEquals(
      1,
      options.size(),
      'Should return template with null type when querying for null'
    );
  }
}
