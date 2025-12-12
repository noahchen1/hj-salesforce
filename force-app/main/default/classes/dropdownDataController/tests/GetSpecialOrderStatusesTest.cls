@isTest
private class GetSpecialOrderStatusesTest {
  @isTest
  static void testGetSpecialOrderStatuses_success() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order',
      ncf_body_special_statuses__c = 'Test Status'
    );

    insert newOrder;

    Test.startTest();
    List<DropdownDataController.Option> results = DropdownDataController.getSpecialOrderStatuses();
    Test.stopTest();

    System.assert(results.size() == 1, 'Should return one result');
    System.assert(
      results[0].label == 'Test Status',
      'Should return one result with type Test Status'
    );
  }

  @isTest
  static void testGetSpecialOrderStatuses_emptyResults() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order'
    );

    insert newOrder;

    Test.startTest();
    List<DropdownDataController.Option> results = DropdownDataController.getSpecialOrderStatuses();
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return one result');
  }
}
