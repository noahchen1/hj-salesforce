@isTest
private class SearchSellableItemTest {
  @isTest
  static void testSearchSellableItem_success() {
    breadwinner_ns__BW_Item__c nonSerialized = new breadwinner_ns__BW_Item__c(
      Name = 'SellableNonSerialized',
      breadwinner_ns__DisplayName__c = 'Sellable Display',
      ncf_item_serialized_item_type__c = false
    );
    insert nonSerialized;

    breadwinner_ns__BW_Item__c parent = new breadwinner_ns__BW_Item__c(
      Name = 'SellableSerialized',
      ncf_item_serialized_item_type__c = true
    );
    insert parent;

    breadwinner_ns__BW_Item__c serializedWithParent = new breadwinner_ns__BW_Item__c(
      Name = 'SellableSerialized',
      ncf_item_serialized_item_type__c = true,
      breadwinner_ns__Parent__c = parent.Id
    );
    insert serializedWithParent;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSellableItem(
      'Sellable'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return both sellable items');
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(
      names.contains('SellableNonSerialized'),
      'Should contain SellableNonSerialized'
    );
    System.assert(
      names.contains('SellableSerialized'),
      'Should contain SellableSerialized'
    );
    for (FilterDataController.LookupResult result : results) {
      if (result.Name == 'SellableNonSerialized') {
        System.assertEquals(
          'SellableNonSerialized Sellable Display',
          result.DisplayName,
          'Should provide a separate rendering label'
        );
      }
    }
  }

  @isTest
  static void testSearchSellableItem_emptyResults() {
    breadwinner_ns__BW_Item__c unrelated = new breadwinner_ns__BW_Item__c(
      Name = 'Unrelated',
      ncf_item_serialized_item_type__c = false
    );
    insert unrelated;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSellableItem(
      'NoMatch'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }

  @isTest
  static void testSearchSellableItem_matchesDisplayNamePrefix() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'SELLABLE-SKU-001',
      breadwinner_ns__DisplayName__c = 'Emerald Sellable',
      ncf_item_serialized_item_type__c = false
    );
    insert item;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSellableItem(
      'Emerald'
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals('SELLABLE-SKU-001', results[0].Name);
    System.assertEquals(
      'SELLABLE-SKU-001 Emerald Sellable',
      results[0].DisplayName
    );
  }
}
