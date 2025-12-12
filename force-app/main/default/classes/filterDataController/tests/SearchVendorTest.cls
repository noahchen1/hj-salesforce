@isTest
private class SearchVendorTest {
  @isTest
  static void testSearchVendor_success() {
    breadwinner_ns__BW_Company__c newVendor = new breadwinner_ns__BW_Company__c(
      Name = 'Test Vendor',
      breadwinner_ns__Entity_Type__c = 'Vendor'
    );

    insert newVendor;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendor(
      'Test Vendor'
    );
    Test.stopTest();

    System.assert(results.size() == 1, 'Should return one result');
    System.assert(
      results[0].Name == 'Test Vendor',
      'Should return the Test Vendor'
    );
  }

  static void testSearchVendor_emptyResults() {
    breadwinner_ns__BW_Company__c newVendor = new breadwinner_ns__BW_Company__c(
      Name = 'Test Vendor',
      breadwinner_ns__Entity_Type__c = 'Vendor'
    );

    insert newVendor;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendor(
      'Rolex'
    );
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return no results');
  }
}
