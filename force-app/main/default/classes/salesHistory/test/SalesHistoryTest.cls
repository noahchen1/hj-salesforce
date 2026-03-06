@isTest
private class SalesHistoryTest {
  @TestSetup
  static void setupData() {
    Account testAccount = new Account(
      Name = 'Test Customer',
      First_Name__c = 'Test',
      Last_Name__c = 'Customer',
      Email__c = 'test@example.com',
      Phone = '555-0001',
      Mobile_Phone__c = '555-0002',
      BillingStreet = '123 Main St',
      BillingCity = 'Springfield',
      BillingState = 'New Jersey',
      BillingPostalCode = '62701',
      BillingCountry = 'United States',
      Sales_Rep__c = 'John Doe',
      Birthdate__c = Date.newInstance(1990, 6, 15),
      Anniversary__c = Date.newInstance(2020, 1, 1),
      Ranking__c = 'A',
      Is_Service_Only__c = false,
      Is_New_Customer__c = true,
      AccountSource = 'Web'
    );
    insert testAccount;

    insert new List<Sales_History__c>{
      new Sales_History__c(
        Name = 'Line-1',
        Account__c = testAccount.Id,
        Location__c = 'Chicago',
        Item_Name__c = 'Widget A',
        Division__c = 'Sales',
        Department__c = 'Direct',
        Group_Code__c = 'GRP001',
        Vendor__c = 'Vendor A',
        Vendor_Item_Number__c = 'VIN001',
        Price_Paid__c = 100,
        Order_Date__c = Date.today().addDays(-10)
      ),
      new Sales_History__c(
        Name = 'Line-2',
        Account__c = testAccount.Id,
        Location__c = 'Springfield',
        Item_Name__c = 'Widget B',
        Division__c = 'Sales',
        Department__c = 'Direct',
        Group_Code__c = 'GRP002',
        Vendor__c = 'Vendor B',
        Vendor_Item_Number__c = 'VIN002',
        Price_Paid__c = 200,
        Order_Date__c = Date.today().addDays(-3)
      )
    };
  }

  private static SalesHistoryModels.FilterCriteria baseCriteria() {
    SalesHistoryModels.FilterCriteria criteria = new SalesHistoryModels.FilterCriteria();
    criteria.pageSize = 50;
    criteria.offsetSize = 0;
    criteria.sortBy = 'totalSpend';
    criteria.sortDirection = 'desc';
    criteria.locations = new List<String>();
    return criteria;
  }

  @isTest
  static void testSalesHistoryServiceReturnsResults() {
    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.customer = 'Test Customer';

    Test.startTest();
    List<AggregateResult> results = SalesHistoryService.querySalesHistory(
      criteria
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assertEquals(
      1,
      results.size(),
      'Expected one aggregated customer row'
    );
  }

  @isTest
  static void testSalesHistoryServiceBirthdayFilter() {
    SalesHistoryModels.FilterCriteria criteria = baseCriteria();
    criteria.birthdayStartMonth = '6';
    criteria.birthdayStartDay = '1';
    criteria.birthdayEndMonth = '6';
    criteria.birthdayEndDay = '30';

    Test.startTest();
    List<AggregateResult> results = SalesHistoryService.querySalesHistory(
      criteria
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Expected June birthday account to match'
    );
  }

  @isTest
  static void testControllerGetSalesHistory() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      'Test Customer',
      new List<String>{ 'Chicago' },
      'John Doe',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      25,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Controller should return a list');
    System.assertEquals(
      1,
      results.size(),
      'Expected one aggregate row with filters'
    );
  }

  @isTest
  static void testControllerEnqueueAddAccountsToCampaignRequiresCampaignId() {
    Boolean thrown = false;
    try {
      SalesHistoryController.enqueueAddAccountsToCampaign(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      );
    } catch (AuraHandledException ex) {
      thrown = true;
    }

    System.assert(thrown, 'Expected AuraHandledException for null campaign id');
  }

  @isTest
  static void testControllerEnqueueAddAccountsToCampaignRunsBatch() {
    Campaign c = new Campaign(Name = 'SalesHistory Campaign', IsActive = true);
    insert c;

    Test.startTest();
    Id jobId = SalesHistoryController.enqueueAddAccountsToCampaign(
      c.Id,
      'Test Customer',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
      false,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertNotEquals(null, jobId, 'Batch job id should be returned');
  }

  @isTest
  static void testControllerGenerateCsvRunsBatch() {
    Test.startTest();
    Id jobId = SalesHistoryController.generateCsv(
      'Test Customer',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
      false,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertNotEquals(null, jobId, 'CSV batch job id should be returned');
  }

  @isTest
  static void testSalesHistoryModelsFilterCriteriaFieldsAreAssignable() {
    SalesHistoryModels.FilterCriteria criteria = new SalesHistoryModels.FilterCriteria();
    criteria.customer = 'Customer';
    criteria.locations = new List<String>{ 'Chicago' };
    criteria.salesRep = 'Rep';
    criteria.item = 'Item';
    criteria.division = 'Division';
    criteria.department = 'Department';
    criteria.groupcode = 'Group';
    criteria.purchaseStartDate = Date.today().addDays(-30);
    criteria.purchaseEndDate = Date.today();
    criteria.birthdayStartMonth = '1';
    criteria.birthdayStartDay = '1';
    criteria.birthdayEndMonth = '12';
    criteria.birthdayEndDay = '31';
    criteria.vendor = 'Vendor';
    criteria.vendorItemNum = 'VendorNum';
    criteria.isServiceOnly = true;
    criteria.isNewCustomer = false;
    criteria.pageSize = 10;
    criteria.offsetSize = 0;
    criteria.sortBy = 'totalSpend';
    criteria.sortDirection = 'asc';

    System.assertEquals('Customer', criteria.customer);
    System.assertEquals(1, criteria.locations.size());
    System.assertEquals(10, criteria.pageSize);
  }

  @isTest
  static void testBirthdayFilterSameMonth() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '6',
      '1',
      '6',
      '30',
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should find customer with birthday in June'
    );
  }

  @isTest
  static void testBirthdayFilterExcludesOutOfRange() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '1',
      '1',
      '1',
      '31',
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'Should not find customer with birthday in June when filtering for January'
    );
  }

  @isTest
  static void testBirthdayFilterCrossMonth() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '4',
      '1',
      '8',
      '31',
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should find customer with June birthday in April-August range'
    );
  }

  @isTest
  static void testBirthdayFilterStartMonthOnly() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '6',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should find customer with June birthday when filtering June and later'
    );
  }

  @isTest
  static void testBirthdayFilterEndMonthOnly() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '6',
      null,
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should find customer with June birthday when filtering June and earlier'
    );
  }

  @isTest
  static void testBirthdayFilterSpecificDayRange() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '6',
      '10',
      '6',
      '20',
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should find customer with June 15 birthday in June 10-20 range'
    );
  }

  @isTest
  static void testBirthdayFilterExcludesByDay() {
    Test.startTest();
    List<AggregateResult> results = SalesHistoryController.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '6',
      '1',
      '6',
      '10',
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'Should not find customer with June 15 birthday in June 1-10 range'
    );
  }
}
