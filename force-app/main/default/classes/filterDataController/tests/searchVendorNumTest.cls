@isTest
private class searchVendorNumTest {
  @isTest
  static void testSearchVendorNum_success_and_unique() {
    breadwinner_ns__BW_Item__c i1 = new breadwinner_ns__BW_Item__c(
      breadwinner_ns__VendorName__c = 'TestVendorNum1',
      breadwinner_ns__InternalId__c = 'VN1'
    );
    breadwinner_ns__BW_Item__c i2 = new breadwinner_ns__BW_Item__c(
      breadwinner_ns__VendorName__c = 'TestVendorNum2',
      breadwinner_ns__InternalId__c = 'VN2'
    );
    breadwinner_ns__BW_Item__c i3 = new breadwinner_ns__BW_Item__c(
      breadwinner_ns__VendorName__c = 'TestVendorNum1',
      breadwinner_ns__InternalId__c = 'VN3'
    ); // duplicate name
    insert new List<breadwinner_ns__BW_Item__c>{ i1, i2, i3 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendorNum(
      'TestVendorNum'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return unique vendor names');
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(
      names.contains('TestVendorNum1'),
      'Should contain TestVendorNum1'
    );
    System.assert(
      names.contains('TestVendorNum2'),
      'Should contain TestVendorNum2'
    );
    Set<String> nsIds = new Set<String>{ results[0].NsId, results[1].NsId };
    System.assert(
      nsIds.contains('VN1') || nsIds.contains('VN3'),
      'Should contain InternalId for TestVendorNum1'
    );
    System.assert(
      nsIds.contains('VN2'),
      'Should contain InternalId for TestVendorNum2'
    );
  }

  @isTest
  static void testSearchVendorNum_emptyResults() {
    breadwinner_ns__BW_Item__c newLineItem = new breadwinner_ns__BW_Item__c(
      breadwinner_ns__VendorName__c = 'Test Vendor Num',
      breadwinner_ns__InternalId__c = 'VN4'
    );
    insert newLineItem;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendorNum(
      'Rolex Num'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
