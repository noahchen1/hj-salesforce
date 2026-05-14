@isTest
private class SearchSepcialOrderItemTest {
  @isTest
  static void testSearchSepcialOrderItem_success() {
    breadwinner_ns__BW_Item__c specialItem = new breadwinner_ns__BW_Item__c(
      Name = 'SpecialOrderItem',
      breadwinner_ns__InternalId__c = '213836'
    );
    insert specialItem;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSepcialOrderItem(
      'SpecialOrder'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should return the special order item'
    );
    System.assertEquals(
      'SpecialOrderItem',
      results[0].Name,
      'Should return correct item name'
    );
    System.assertEquals(
      '213836',
      results[0].NsId,
      'Should return correct InternalId'
    );
  }

  @isTest
  static void testSearchSepcialOrderItem_emptyResults() {
    breadwinner_ns__BW_Item__c unrelated = new breadwinner_ns__BW_Item__c(
      Name = 'Unrelated',
      breadwinner_ns__InternalId__c = '999999'
    );
    insert unrelated;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSepcialOrderItem(
      'NoMatch'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
