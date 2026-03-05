@isTest
private class SearchItemTest {
  @isTest
  static void testSearchItem_success() {
    breadwinner_ns__BW_Item__c newItem = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item1'
    );

    insert newItem;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchItem(
      'Test Item'
    );
    Test.stopTest();

    System.assert(results.size() == 1, 'Should return one result');
    System.assert(
      results[0].Name == 'Test Item1',
      'Should return the Test item'
    );
  }

  static void testSearchItem_failure() {
    breadwinner_ns__BW_Item__c newItem = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item1'
    );

    insert newItem;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchItem(
      'WRTEC'
    );
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return no results');
  }
}
