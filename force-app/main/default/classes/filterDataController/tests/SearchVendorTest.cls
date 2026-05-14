@isTest
private class SearchVendorTest {
  @isTest
  static void testSearchVendor_success_and_partial() {
    breadwinner_ns__BW_Company__c v1 = new breadwinner_ns__BW_Company__c(
      Name = 'Test Vendor',
      breadwinner_ns__Entity_Type__c = 'Vendor',
      breadwinner_ns__InternalId__c = 'V1'
    );
    breadwinner_ns__BW_Company__c v2 = new breadwinner_ns__BW_Company__c(
      Name = 'Another Vendor',
      breadwinner_ns__Entity_Type__c = 'Vendor',
      breadwinner_ns__InternalId__c = 'V2'
    );
    breadwinner_ns__BW_Company__c v3 = new breadwinner_ns__BW_Company__c(
      Name = 'NotAVendor',
      breadwinner_ns__Entity_Type__c = 'Customer',
      breadwinner_ns__InternalId__c = 'V3'
    );
    insert new List<breadwinner_ns__BW_Company__c>{ v1, v2, v3 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendor(
      'Vendor'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return two vendors');
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(names.contains('Test Vendor'), 'Should contain Test Vendor');
    System.assert(
      names.contains('Another Vendor'),
      'Should contain Another Vendor'
    );
    Set<String> nsIds = new Set<String>{ results[0].NsId, results[1].NsId };
    System.assert(nsIds.contains('V1'), 'Should contain correct InternalId V1');
    System.assert(nsIds.contains('V2'), 'Should contain correct InternalId V2');
  }

  @isTest
  static void testSearchVendor_emptyResults() {
    breadwinner_ns__BW_Company__c newVendor = new breadwinner_ns__BW_Company__c(
      Name = 'Test Vendor',
      breadwinner_ns__Entity_Type__c = 'Vendor',
      breadwinner_ns__InternalId__c = 'V4'
    );
    insert newVendor;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendor(
      'Rolex'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
