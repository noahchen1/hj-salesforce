@isTest
private class NpcTaskSchedulerTest {
  static breadwinner_ns__BW_Line_Item__c createLineItem(
    String suffix,
    Decimal amount,
    Date tranDate,
    String salesRepName
  ) {
    Account account = new Account(Name = 'NPC Account ' + suffix);
    insert account;

    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'NPC Item ' + suffix
    );
    insert item;

    breadwinner_ns__BW_Invoice__c invoice = new breadwinner_ns__BW_Invoice__c(
      Name = 'INV-' + suffix,
      breadwinner_ns__Salesforce_Account__c = account.Id,
      breadwinner_ns__SalesRepName__c = salesRepName,
      breadwinner_ns__TranDate__c = tranDate
    );
    insert invoice;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'NPC Line Item ' + suffix,
      breadwinner_ns__Invoice__c = invoice.Id,
      breadwinner_ns__Item__c = item.Id,
      breadwinner_ns__Amount__c = amount,
      Discount_Total__c = 0
    );
    insert lineItem;

    return lineItem;
  }

  static User createUser(String suffix, String firstName, String lastName) {
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];

    User user = new User(
      Alias = ('u' + suffix).substring(0, Math.min(8, ('u' + suffix).length())),
      Email = 'npc-task-' + suffix + '@example.com',
      EmailEncodingKey = 'UTF-8',
      FirstName = firstName,
      LastName = lastName,
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = profile.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'npc-task-' +
        suffix +
        '-' +
        DateTime.now().getTime() +
        '@example.com'
    );
    insert user;

    return user;
  }

  @isTest
  static void usesMatchedSalesRepUserAsTaskOwner() {
    User salesRepUser = createUser('salesrep', 'Matched', 'Rep');
    breadwinner_ns__BW_Line_Item__c eligibleLineItem = createLineItem(
      'MatchedRep',
      5500,
      Date.today().addDays(-7),
      salesRepUser.FirstName + ' Middle ' + salesRepUser.LastName
    );

    Test.startTest();
    new NpcTaskScheduler().execute(null);
    Test.stopTest();

    Task createdTask = [
      SELECT OwnerId, NetSuite_Line_Item__c
      FROM Task
      WHERE NetSuite_Line_Item__c = :eligibleLineItem.Id
      LIMIT 1
    ];

    breadwinner_ns__BW_Line_Item__c insertedLineItem = [
      SELECT Id, breadwinner_ns__Invoice__r.OwnerId
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :eligibleLineItem.Id
      LIMIT 1
    ];

    System.assertEquals(salesRepUser.Id, createdTask.OwnerId);
    System.assertNotEquals(
      insertedLineItem.breadwinner_ns__Invoice__r.OwnerId,
      createdTask.OwnerId,
      'The scheduler should prefer the matched sales rep user over the invoice owner.'
    );
  }

  @isTest
  static void skipsLineWhenSalesRepUserIsNotFound() {
    breadwinner_ns__BW_Line_Item__c eligibleLineItem = createLineItem(
      'Eligible',
      5500,
      Date.today().addDays(-7),
      'Missing Rep'
    );

    createLineItem('BelowThreshold', 4999, Date.today().addDays(-7), null);

    Test.startTest();
    new NpcTaskScheduler().execute(null);
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE NetSuite_Line_Item__c = :eligibleLineItem.Id
    ];

    System.assertEquals(
      0,
      taskCount,
      'The scheduler should skip eligible line items when the sales rep name does not match a User.'
    );
  }

  @isTest
  static void skipsLinesWithTasksCreated() {
    breadwinner_ns__BW_Line_Item__c lineItem = createLineItem(
      'ExistingTask',
      6000,
      Date.today().addDays(-7),
      null
    );

    breadwinner_ns__BW_Line_Item__c existingLineItem = [
      SELECT
        Id,
        breadwinner_ns__Invoice__c,
        breadwinner_ns__Invoice__r.OwnerId,
        breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c,
        breadwinner_ns__Item__c
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :lineItem.Id
      LIMIT 1
    ];

    insert new Task(
      Subject = 'Reminder: Complete NPC',
      Status = 'Not Started',
      Priority = 'Normal',
      ActivityDate = Date.today(),
      OwnerId = existingLineItem.breadwinner_ns__Invoice__r.OwnerId,
      Invoice__c = existingLineItem.breadwinner_ns__Invoice__c,
      Account__c = existingLineItem.breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c,
      NetSuite_Item__c = existingLineItem.breadwinner_ns__Item__c,
      NetSuite_Line_Item__c = existingLineItem.Id
    );

    Test.startTest();
    new NpcTaskScheduler().execute(null);
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE NetSuite_Line_Item__c = :lineItem.Id
    ];

    System.assertEquals(
      1,
      taskCount,
      'The scheduler should not create a duplicate task.'
    );
  }

  @isTest
  static void skipsLinesOutsideTargetTranDate() {
    createLineItem('WrongDate', 6000, Date.today().addDays(-5), null);

    Test.startTest();
    new NpcTaskScheduler().execute(null);
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE Subject = 'Reminder: Complete NPC'
    ];

    System.assertEquals(
      0,
      taskCount,
      'The scheduler should skip line items whose invoice date is not six or seven days ago.'
    );
  }
}
