@isTest
private class NpcTaskSchedulerTest {
  static breadwinner_ns__BW_Line_Item__c createLineItem(
    String suffix,
    Decimal amount,
    Date tranDate
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

  @isTest
  static void createsTaskForElligibleLine() {
    breadwinner_ns__BW_Line_Item__c eligibleLineItem = createLineItem(
      'Eligible',
      5500,
      Date.today().addDays(-7)
    );

    createLineItem('BelowThreshold', 4999, Date.today().addDays(-7));

    Test.startTest();
    new NpcTaskScheduler().execute(null);
    Test.stopTest();

    List<breadwinner_ns__BW_Line_Item__c> testItems = [
      SELECT Name, breadwinner_ns__Amount__c, Amount_after_Discounts__c
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :eligibleLineItem.Id
    ];

    System.debug('testItems :' + testItems);

    Task createdTask = [
      SELECT
        Subject,
        Status,
        Priority,
        ActivityDate,
        OwnerId,
        Invoice__c,
        Account__c,
        NetSuite_Item__c,
        NetSuite_Line_Item__c
      FROM Task
      WHERE NetSuite_Line_Item__c = :eligibleLineItem.Id
      LIMIT 1
    ];

    System.debug('created tasks: ' + createdTask);

    breadwinner_ns__BW_Line_Item__c insertedLineItem = [
      SELECT
        Id,
        breadwinner_ns__Invoice__c,
        breadwinner_ns__Invoice__r.OwnerId,
        breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c,
        breadwinner_ns__Item__c
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :eligibleLineItem.Id
      LIMIT 1
    ];

    System.assertEquals('Not Started', createdTask.Status);
    System.assertEquals(Date.today(), createdTask.ActivityDate);
    System.assertEquals(
      insertedLineItem.breadwinner_ns__Invoice__r.OwnerId,
      createdTask.OwnerId
    );
    System.assertEquals(
      insertedLineItem.breadwinner_ns__Invoice__c,
      createdTask.Invoice__c
    );
    System.assertEquals(
      insertedLineItem.breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c,
      createdTask.Account__c
    );
    System.assertEquals(
      insertedLineItem.breadwinner_ns__Item__c,
      createdTask.NetSuite_Item__c
    );
    System.assertEquals(eligibleLineItem.Id, createdTask.NetSuite_Line_Item__c);

    Integer createdTaskCount = [
      SELECT COUNT()
      FROM Task
      WHERE Subject = 'Reminder: Complete NPC'
    ];

    System.assertEquals(
      1,
      createdTaskCount,
      'Only the eligible line item should create a task.'
    );
  }

  @isTest
  static void skipsLinesWithTasksCreated() {
    breadwinner_ns__BW_Line_Item__c lineItem = createLineItem(
      'ExistingTask',
      6000,
      Date.today().addDays(-7)
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
    createLineItem('WrongDate', 6000, Date.today().addDays(-6));

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
      'The scheduler should skip line items whose invoice date is not exactly seven days ago.'
    );
  }
}
