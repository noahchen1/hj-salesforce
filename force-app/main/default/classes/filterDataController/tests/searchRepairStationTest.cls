@isTest
private class searchRepairStationTest {
  @isTest
  static void testSearchRepairStation_success() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order',
      ncf_body_repair_station__c = 'Test Station'
    );

    insert newOrder;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchRepairStation(
      'Test Station'
    );
    Test.stopTest();

    System.assert(results.size() == 1, 'Should return one result');
    System.assert(
      results[0].Name == 'Test Station',
      'should return the order with Test Station'
    );
  }

  @isTest
  static void testSearchRepairStation_emptyResults() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order',
      ncf_body_repair_station__c = 'Test Station'
    );

    insert newOrder;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchRepairStation(
      'Something'
    );
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return no results');
  }
}
