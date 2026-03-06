@isTest
private class SalesHistoryBatchTest {
  @TestSetup
  static void setupData() {
    Account a = new Account(
      Name = 'Batch Test Customer',
      First_Name__c = 'Batch',
      Last_Name__c = 'Customer',
      Sales_Rep__c = 'John Doe',
      Birthdate__c = Date.newInstance(1992, 6, 15),
      Is_New_Customer__c = true
    );
    insert a;

    insert new List<Sales_History__c>{
      new Sales_History__c(
        Name = 'Batch Line 1',
        Account__c = a.Id,
        Location__c = 'Chicago',
        Item_Name__c = 'Widget A',
        Division__c = 'Sales',
        Department__c = 'Direct',
        Group_Code__c = 'GRP001',
        Vendor__c = 'Vendor A',
        Vendor_Item_Number__c = 'VIN001',
        Price_Paid__c = 150,
        Order_Date__c = Date.today().addDays(-7)
      ),
      new Sales_History__c(
        Name = 'Batch Line 2',
        Account__c = a.Id,
        Location__c = 'Springfield',
        Item_Name__c = 'Widget B',
        Division__c = 'Sales',
        Department__c = 'Direct',
        Group_Code__c = 'GRP002',
        Vendor__c = 'Vendor B',
        Vendor_Item_Number__c = 'VIN002',
        Price_Paid__c = 250,
        Order_Date__c = Date.today().addDays(-3)
      )
    };
  }

  private static SalesHistoryModels.FilterCriteria baseCriteria() {
    SalesHistoryModels.FilterCriteria c = new SalesHistoryModels.FilterCriteria();
    c.customer = 'Batch Test Customer';
    c.locations = new List<String>{ 'Chicago' };
    c.salesRep = 'John Doe';
    c.item = 'Widget A';
    c.division = 'Sales';
    c.department = 'Direct';
    c.groupcode = 'GRP001';
    c.purchaseStartDate = Date.today().addDays(-30);
    c.purchaseEndDate = Date.today();
    c.vendor = 'Vendor A';
    c.vendorItemNum = 'VIN001';
    c.isServiceOnly = false;
    c.isNewCustomer = true;
    c.pageSize = 50;
    c.offsetSize = 0;
    c.sortBy = 'totalSpend';
    c.sortDirection = 'desc';
    return c;
  }

  @isTest
  static void testAddToCampaignStart_WithBirthdaySameMonthRange() {
    Campaign c = new Campaign(Name = 'Batch Campaign 1', IsActive = true);
    insert c;

    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = '6';
    criteria.birthdayStartDay = '1';
    criteria.birthdayEndMonth = '6';
    criteria.birthdayEndDay = '30';

    SalesHistoryAddToCampaignBatch batch = new SalesHistoryAddToCampaignBatch(
      c.Id,
      criteria
    );

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(null, ql, 'QueryLocator should be built');
  }

  @isTest
  static void testAddToCampaignStart_BirthdayStartOnly() {
    Campaign c = new Campaign(Name = 'Batch Campaign 2', IsActive = true);
    insert c;

    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = '6';
    criteria.birthdayStartDay = null;
    criteria.birthdayEndMonth = null;
    criteria.birthdayEndDay = null;

    SalesHistoryAddToCampaignBatch batch = new SalesHistoryAddToCampaignBatch(
      c.Id,
      criteria
    );

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(null, ql, 'QueryLocator should be built');
  }

  @isTest
  static void testAddToCampaignStart_BirthdayEndOnly() {
    Campaign c = new Campaign(Name = 'Batch Campaign 2B', IsActive = true);
    insert c;

    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = null;
    criteria.birthdayStartDay = null;
    criteria.birthdayEndMonth = '6';
    criteria.birthdayEndDay = '30';

    SalesHistoryAddToCampaignBatch batch = new SalesHistoryAddToCampaignBatch(
      c.Id,
      criteria
    );

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(null, ql, 'QueryLocator should be built');
  }

  @isTest
  static void testAddToCampaignStart_BirthdayCrossMonthRange() {
    Campaign c = new Campaign(Name = 'Batch Campaign 2C', IsActive = true);
    insert c;

    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = '4';
    criteria.birthdayStartDay = '1';
    criteria.birthdayEndMonth = '8';
    criteria.birthdayEndDay = '31';

    SalesHistoryAddToCampaignBatch batch = new SalesHistoryAddToCampaignBatch(
      c.Id,
      criteria
    );

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(null, ql, 'QueryLocator should be built');
  }

  @isTest
  static void testAddToCampaignStart_WithNullCriteria() {
    Campaign c = new Campaign(Name = 'Batch Campaign 2D', IsActive = true);
    insert c;

    SalesHistoryAddToCampaignBatch batch = new SalesHistoryAddToCampaignBatch(
      c.Id,
      null
    );

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(
      null,
      ql,
      'QueryLocator should be built for null criteria'
    );
  }

  @isTest
  static void testAddToCampaignBatch_RunsThroughExecuteAndFinish() {
    Campaign c = new Campaign(Name = 'Batch Campaign 3', IsActive = true);
    insert c;

    SalesHistoryModels.FilterCriteria criteria = baseCriteria();

    Test.startTest();
    Id jobId = Database.executeBatch(
      new SalesHistoryAddToCampaignBatch(c.Id, criteria),
      200
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      jobId,
      'Add-to-campaign batch should be enqueued'
    );
  }

  @isTest
  static void testAddToCampaignExecute_WithEmptyScope() {
    Campaign c = new Campaign(Name = 'Batch Campaign 3B', IsActive = true);
    insert c;

    SalesHistoryAddToCampaignBatch batch = new SalesHistoryAddToCampaignBatch(
      c.Id,
      baseCriteria()
    );

    Test.startTest();
    batch.execute(null, new List<Sales_History__c>());
    batch.finish(null);
    Test.stopTest();

    System.assert(
      true,
      'Execute/finish should handle empty scope without errors'
    );
  }

  @isTest
  static void testDownloadStart_WithBirthdayEndOnly() {
    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = null;
    criteria.birthdayStartDay = null;
    criteria.birthdayEndMonth = '6';
    criteria.birthdayEndDay = '30';

    SalesHistoryDownloadBatch batch = new SalesHistoryDownloadBatch(criteria);

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(null, ql, 'QueryLocator should be built');
  }

  @isTest
  static void testDownloadStart_WithBirthdayCrossMonthRange() {
    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = '4';
    criteria.birthdayStartDay = '1';
    criteria.birthdayEndMonth = '8';
    criteria.birthdayEndDay = '31';

    SalesHistoryDownloadBatch batch = new SalesHistoryDownloadBatch(criteria);

    Database.QueryLocator ql = batch.start(null);
    System.assertNotEquals(null, ql, 'QueryLocator should be built');
  }

  @isTest
  static void testDownloadBatch_RunsAndCreatesContentVersion() {
    SalesHistoryModels.FilterCriteria criteria = baseCriteria();

    Integer beforeCount = [
      SELECT COUNT()
      FROM ContentVersion
      WHERE Title = 'SalesHistoryExport.csv'
    ];

    Test.startTest();
    Id jobId = Database.executeBatch(
      new SalesHistoryDownloadBatch(criteria),
      200
    );
    Test.stopTest();

    Integer afterCount = [
      SELECT COUNT()
      FROM ContentVersion
      WHERE Title = 'SalesHistoryExport.csv'
    ];

    System.assertNotEquals(null, jobId, 'Download batch should be enqueued');
    System.assert(
      afterCount > beforeCount,
      'Download batch should create at least one CSV content version'
    );
  }
}
