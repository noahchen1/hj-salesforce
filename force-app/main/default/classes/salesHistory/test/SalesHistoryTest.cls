@isTest
public class SalesHistoryTest {
  @TestSetup
  static void setup() {
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
      Is_New_Customer__c = false,
      AccountSource = 'Web'
    );
    insert testAccount;

    Sales_History__c sh1 = new Sales_History__c(
      Name = 'Test Line 1',
      Account__c = testAccount.Id,
      Location__c = 'Chicago',
      Item_Name__c = 'Widget A',
      Division__c = 'Sales',
      Department__c = 'Direct',
      Group_Code__c = 'GRP001',
      Vendor__c = 'Vendor A',
      Vendor_Item_Number__c = 'VIN001',
      Price_Paid__c = 1500,
      Order_Date__c = Date.newInstance(2025, 1, 15)
    );

    Sales_History__c sh2 = new Sales_History__c(
      Name = 'Test Line 2',
      Account__c = testAccount.Id,
      Location__c = 'Springfield',
      Item_Name__c = 'Widget B',
      Division__c = 'Sales',
      Department__c = 'Direct',
      Group_Code__c = 'GRP002',
      Vendor__c = 'Vendor B',
      Vendor_Item_Number__c = 'VIN002',
      Price_Paid__c = 2500,
      Order_Date__c = Date.newInstance(2025, 6, 20)
    );

    insert new List<Sales_History__c>{ sh1, sh2 };
  }

  @isTest
  static void testGetSalesHistoryNoFilters() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetSalesHistoryByCustomer() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
      'Test Customer',
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
      'Should return 1 aggregated customer'
    );
  }

  @isTest
  static void testGetSalesHistoryByLocation() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
      null,
      new List<String>{ 'Chicago' },
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
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetSalesHistoryByDateRange() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
      null,
      new List<String>(),
      null,
      null,
      null,
      null,
      null,
      Date.newInstance(2025, 1, 1),
      Date.newInstance(2025, 12, 31),
      null,
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

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetSalesHistoryAscendingSort() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
      null,
      null,
      null,
      null,
      null,
      null,
      10,
      0,
      'totalSpend',
      'asc'
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetSalesHistoryBirthdayFilter() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetSalesHistoryPagination() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
      null,
      null,
      null,
      null,
      null,
      null,
      5,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetSalesHistoryMultipleFilters() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
      'Test Customer',
      new List<String>{ 'Chicago', 'Springfield' },
      'John Doe',
      'Widget A',
      'Sales',
      'Direct',
      'GRP001',
      Date.newInstance(2025, 1, 1),
      Date.newInstance(2025, 12, 31),
      null,
      null,
      null,
      null,
      'Vendor A',
      'VIN001',
      false,
      false,
      10,
      0,
      'totalSpend',
      'desc'
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testBirthdayFilterSameMonth() {
    Test.startTest();
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
    List<AggregateResult> results = SalesHistory.getSalesHistory(
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
