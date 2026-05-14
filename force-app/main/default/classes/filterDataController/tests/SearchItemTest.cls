@isTest
private class SearchItemTest {
  @isTest
  static void testSearchItem_success_and_prefix() {
    breadwinner_ns__BW_Item__c i1 = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item1',
      breadwinner_ns__InternalId__c = 'I1'
    );
    breadwinner_ns__BW_Item__c i2 = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item2',
      breadwinner_ns__InternalId__c = 'I2'
    );
    breadwinner_ns__BW_Item__c i3 = new breadwinner_ns__BW_Item__c(
      Name = 'Other',
      breadwinner_ns__InternalId__c = 'I3'
    );
    insert new List<breadwinner_ns__BW_Item__c>{ i1, i2, i3 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchItem(
      'Test Item'
    );
    Test.stopTest();

    System.assertEquals(
      2,
      results.size(),
      'Should return two items with prefix'
    );
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(names.contains('Test Item1'), 'Should contain Test Item1');
    System.assert(names.contains('Test Item2'), 'Should contain Test Item2');
    Set<String> nsIds = new Set<String>{ results[0].NsId, results[1].NsId };
    System.assert(nsIds.contains('I1'), 'Should contain correct InternalId I1');
    System.assert(nsIds.contains('I2'), 'Should contain correct InternalId I2');
  }

  @isTest
  static void testSearchItem_failure() {
    breadwinner_ns__BW_Item__c newItem = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item1',
      breadwinner_ns__InternalId__c = 'I4'
    );
    insert newItem;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchItem(
      'WRTEC'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
