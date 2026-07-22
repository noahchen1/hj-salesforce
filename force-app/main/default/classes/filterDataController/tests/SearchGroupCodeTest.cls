@isTest
private class SearchGroupCodeTest {
  @isTest
  static void testSearchGroupCode_success_unique_and_trimmed() {
    breadwinner_ns__BW_Item__c i1 = new breadwinner_ns__BW_Item__c(
      ncf_item_groupcode__c = 'GRP-ALPHA'
    );
    breadwinner_ns__BW_Item__c i2 = new breadwinner_ns__BW_Item__c(
      ncf_item_groupcode__c = 'GRP-BETA'
    );
    breadwinner_ns__BW_Item__c i3 = new breadwinner_ns__BW_Item__c(
      ncf_item_groupcode__c = 'GRP-ALPHA'
    );
    breadwinner_ns__BW_Item__c i4 = new breadwinner_ns__BW_Item__c(
      ncf_item_groupcode__c = 'OTHER'
    );
    insert new List<breadwinner_ns__BW_Item__c>{ i1, i2, i3, i4 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchGroupCode(
      '  GRP-  '
    );
    Test.stopTest();

    System.assertEquals(
      2,
      results.size(),
      'Should return distinct matching group codes'
    );
    System.assertEquals(
      'GRP-ALPHA',
      results[0].Id,
      'Should return the group code as the Id'
    );
    System.assertEquals(
      'GRP-ALPHA',
      results[0].Name,
      'Should return the group code as the Name'
    );
    System.assertEquals(
      'GRP-BETA',
      results[1].Id,
      'Should return results in group-code order'
    );
  }

  @isTest
  static void testSearchGroupCode_blankInput() {
    insert new breadwinner_ns__BW_Item__c(ncf_item_groupcode__c = 'GRP-ALPHA');

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchGroupCode(
      ' '
    );
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'Should return no results for blank input'
    );
  }
}
