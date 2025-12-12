@isTest
private class searchVendorNumTest {
  @isTest
  static void testSearchVendorNum_success() {
    List<breadwinner_ns__BW_Item__c> newLienItems = new List<breadwinner_ns__BW_Item__c>();

    Integer batchSize = 2000;

    for (Integer i = 0; i < batchSize; i++) {
      newLienItems.add(
        new breadwinner_ns__BW_Item__c(
          breadwinner_ns__VendorName__c = 'TestVendorNum' + String.valueOf(i)
        )
      );
    }

    insert newLienItems;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendorNum(
      'TestVendorNum'
    );
    Test.stopTest();

    System.assert(results.size() == batchSize, 'Should return all results');
    System.assert(
      results[0].Name.startsWith('TestVendorNum'),
      'Should return the Test Vendor Num'
    );
  }

  @isTest
  static void testSearchVendorNum_emptyResults() {
    breadwinner_ns__BW_Item__c newLineItem = new breadwinner_ns__BW_Item__c(
      breadwinner_ns__VendorName__c = 'Test Vendor Num'
    );

    insert newLineItem;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchVendorNum(
      'Rolex Num'
    );
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return no results');
  }
}
