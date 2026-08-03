@isTest
private class SearchItemTest {
  @isTest
  static void testSearchItem_success_and_prefix() {
    breadwinner_ns__BW_Item__c i1 = new breadwinner_ns__BW_Item__c(
      Name = 'Test Item1',
      breadwinner_ns__DisplayName__c = 'First Display Name',
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
    Map<String, String> displayNamesByName = new Map<String, String>();
    for (FilterDataController.LookupResult result : results) {
      displayNamesByName.put(result.Name, result.DisplayName);
    }
    System.assertEquals(
      'Test Item1 First Display Name',
      displayNamesByName.get('Test Item1'),
      'Should render the item and display names without changing Name'
    );
    System.assertEquals(
      'Test Item2',
      displayNamesByName.get('Test Item2'),
      'Should fall back to Name when the display name is blank'
    );
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

  @isTest
  static void testSearchItem_matchesDisplayName() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'SKU-001',
      breadwinner_ns__DisplayName__c = 'Emerald Bracelet',
      breadwinner_ns__InternalId__c = 'I5'
    );
    insert item;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchItem(
      'Emerald'
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals('SKU-001', results[0].Name);
    System.assertEquals('SKU-001 Emerald Bracelet', results[0].DisplayName);
  }
}
