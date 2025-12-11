@isTest
private class SearchCustomerTest {
  @isTest
  static void testSearchCustomer_success() {
    breadwinner_ns__BW_Company__c newCustomer = new breadwinner_ns__BW_Company__c(
      Name = 'Test Customer'
    );

    insert newCustomer;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchCustomer(
      'Customer'
    );
    Test.stopTest();

    System.assert(results.size() == 1, 'Should return one customer');
    System.assertEquals(
      results[0].Name,
      'Test Customer',
      'Should return customer with the name Test Customer'
    );
  }

  @isTest
  static void testSearchCustomer_EmptyResults() {
    breadwinner_ns__BW_Company__c newCustomer = new breadwinner_ns__BW_Company__c(
      Name = 'Michael John'
    );

    insert newCustomer;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchCustomer(
      'Customer'
    );
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return empty results');
  }
}
