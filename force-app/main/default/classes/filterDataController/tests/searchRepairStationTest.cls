@isTest
private class SearchRepairStationTest {
  @isTest
  static void testSearchRepairStation_success_and_uniqueness() {
    breadwinner_ns__BW_Sales_Order__c o1 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order1',
      ncf_body_repair_station__c = 'StationA'
    );
    breadwinner_ns__BW_Sales_Order__c o2 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order2',
      ncf_body_repair_station__c = 'StationA'
    );
    breadwinner_ns__BW_Sales_Order__c o3 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order3',
      ncf_body_repair_station__c = 'StationB'
    );
    insert new List<breadwinner_ns__BW_Sales_Order__c>{ o1, o2, o3 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchRepairStation(
      'Station'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return two unique stations');
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(names.contains('StationA'), 'Should contain StationA');
    System.assert(names.contains('StationB'), 'Should contain StationB');
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
    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
