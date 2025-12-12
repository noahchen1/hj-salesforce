@isTest
private class GetSpecialOrderItemTypesTest {
  @isTest
  static void testGetSpecialOrderItemTypes_success() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order',
      ncf_body_special_item_type__c = 'Test Type'
    );

    insert newOrder;

    Test.startTest();
    List<DropdownDataController.Option> results = DropdownDataController.getSpecialOrderItemTypes();
    Test.stopTest();

    System.assert(results.size() == 1, 'Should return one result');
    System.assert(
      results[0].label == 'Test Type',
      'Should return one result with type Test Type'
    );
  }

  @isTest
  static void testGetSpecialOrderItemTypes_emptyResults() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order'
    );

    insert newOrder;

    Test.startTest();
    List<DropdownDataController.Option> results = DropdownDataController.getSpecialOrderItemTypes();
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return no results');
  }
}
