@isTest
private class SearchCustomerTest {
  @isTest
  static void testSearchCustomer_success_and_partial() {
    breadwinner_ns__BW_Company__c c1 = new breadwinner_ns__BW_Company__c(
      Name = 'Test Customer',
      breadwinner_ns__InternalId__c = 'INT1'
    );
    breadwinner_ns__BW_Company__c c2 = new breadwinner_ns__BW_Company__c(
      Name = 'Another Customer',
      breadwinner_ns__InternalId__c = 'INT2'
    );
    breadwinner_ns__BW_Company__c c3 = new breadwinner_ns__BW_Company__c(
      Name = 'NoMatch',
      breadwinner_ns__InternalId__c = 'INT3'
    );
    insert new List<breadwinner_ns__BW_Company__c>{ c1, c2, c3 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchCustomer(
      'Customer'
    );
    Test.stopTest();

    System.assertEquals(
      2,
      results.size(),
      'Should return two customers with "Customer" in name'
    );
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(
      names.contains('Test Customer'),
      'Should contain Test Customer'
    );
    System.assert(
      names.contains('Another Customer'),
      'Should contain Another Customer'
    );
    Set<String> nsIds = new Set<String>{ results[0].NsId, results[1].NsId };
    System.assert(
      nsIds.contains('INT1'),
      'Should contain correct InternalId INT1'
    );
    System.assert(
      nsIds.contains('INT2'),
      'Should contain correct InternalId INT2'
    );
  }

  @isTest
  static void testSearchCustomer_limit() {
    List<breadwinner_ns__BW_Company__c> manyCustomers = new List<breadwinner_ns__BW_Company__c>();
    for (Integer i = 0; i < 15; i++) {
      manyCustomers.add(
        new breadwinner_ns__BW_Company__c(
          Name = 'Customer ' + i,
          breadwinner_ns__InternalId__c = 'LIM' + i
        )
      );
    }
    insert manyCustomers;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchCustomer(
      'Customer'
    );
    Test.stopTest();
    System.assert(results.size() <= 10, 'Should return at most 10 results');
  }

  @isTest
  static void testSearchCustomer_EmptyResults() {
    breadwinner_ns__BW_Company__c newCustomer = new breadwinner_ns__BW_Company__c(
      Name = 'Michael John',
      breadwinner_ns__InternalId__c = 'INT4'
    );
    insert newCustomer;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchCustomer(
      'Customer'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return empty results');
  }
}
