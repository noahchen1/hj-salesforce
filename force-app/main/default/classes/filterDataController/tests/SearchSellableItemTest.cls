@isTest
private class SearchSellableItemTest {
  @isTest
  static void testSearchSellableItem_success() {
    breadwinner_ns__BW_Item__c nonSerialized = new breadwinner_ns__BW_Item__c(
      Name = 'SellableNonSerialized',
      ncf_item_serialized_item_type__c = false
    );
    insert nonSerialized;

    breadwinner_ns__BW_Item__c serializedWithParent = new breadwinner_ns__BW_Item__c(
      Name = 'SellableSerialized',
      ncf_item_serialized_item_type__c = true,
      breadwinner_ns__Parent__c = 'a0WWJ0000016gkB2AQ'
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
}
