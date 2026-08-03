@isTest
private class SearchParentItemTest {
  @isTest
  static void testSearchParentItem_success() {
    breadwinner_ns__BW_Item__c parentItem = new breadwinner_ns__BW_Item__c(
      Name = 'ParentItem',
      breadwinner_ns__DisplayName__c = 'Parent Display',
      ncf_item_serialized_item_type__c = false
    );
    insert parentItem;

    breadwinner_ns__BW_Item__c serializedParent = new breadwinner_ns__BW_Item__c(
      Name = 'ParentSerialized',
      ncf_item_serialized_item_type__c = true,
      breadwinner_ns__Parent__c = null
    );
    insert serializedParent;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchParentItem(
      'Parent'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return both parent items');
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(names.contains('ParentItem'), 'Should contain ParentItem');
    System.assert(
      names.contains('ParentSerialized'),
      'Should contain ParentSerialized'
    );
    for (FilterDataController.LookupResult result : results) {
      if (result.Name == 'ParentItem') {
        System.assertEquals(
          'ParentItem Parent Display',
          result.DisplayName,
          'Should provide a separate rendering label'
        );
      }
    }
  }

  @isTest
  static void testSearchParentItem_emptyResults() {
    breadwinner_ns__BW_Item__c unrelated = new breadwinner_ns__BW_Item__c(
      Name = 'Unrelated',
      ncf_item_serialized_item_type__c = false
    );
    insert unrelated;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchParentItem(
      'NoMatch'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }

  @isTest
  static void testSearchParentItem_matchesDisplayNamePrefix() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'PARENT-SKU-001',
      breadwinner_ns__DisplayName__c = 'Emerald Parent',
      ncf_item_serialized_item_type__c = false
    );
    insert item;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchParentItem(
      'Emerald'
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals('PARENT-SKU-001', results[0].Name);
    System.assertEquals(
      'PARENT-SKU-001 Emerald Parent',
      results[0].DisplayName
    );
  }
}
