@isTest
private class OpenRepairsControllerTest {
  static void setupData() {
    breadwinner_ns__BW_Company__c newCustomer = new breadwinner_ns__BW_Company__c(
      Name = 'Test Customer'
    );
    insert newCustomer;

    breadwinner_ns__BW_Sales_Order__c order1 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order1',
      breadwinner_ns__Entity__c = newCustomer.Id,
      breadwinner_ns__Total__c = 100,
      ncf_body_repair_station__c = 'StationA',
      ncf_body1__c = 'TypeA',
      breadwinner_ns__Status__c = 'Open',
      ncf_body_repair_order__c = true
    );

    breadwinner_ns__BW_Sales_Order__c order2 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order2',
      breadwinner_ns__Entity__c = newCustomer.Id,
      breadwinner_ns__Total__c = 200,
      ncf_body_repair_station__c = 'StationB',
      ncf_body1__c = 'TypeB',
      breadwinner_ns__Status__c = 'Open',
      ncf_body_repair_order__c = true
    );

    insert new List<breadwinner_ns__BW_Sales_Order__c>{ order1, order2 };
  }

  @isTest
  static void testOpenRepairsController_success() {
    setupData();

    Test.startTest();
    List<breadwinner_ns__BW_Sales_Order__c> results = OpenRepairsController.getOpenRepairs(
      'Test Customer',
      null,
      10,
      0,
      'name',
      'asc'
    );

    System.Assert(
      results.size() == 2,
      'Should return 2 orders for Test Customer'
    );
    System.Assert(results[0].Name == 'Order1', 'Should return Order1 first');
    System.Assert(results[1].Name == 'Order2', 'Should return Order2 second');

    List<breadwinner_ns__BW_Sales_Order__c> stationResults = OpenRepairsController.getOpenRepairs(
      null,
      'StationA',
      10,
      0,
      'station',
      'desc'
    );

    System.Assert(
      stationResults.size() == 1,
      'Should return 1 order for StationA'
    );
    System.Assert(stationResults[0].Name == 'Order1', 'Should return Order1');

    List<breadwinner_ns__BW_Sales_Order__c> bothResults = OpenRepairsController.getOpenRepairs(
      'Test Customer',
      'StationB',
      10,
      0,
      'total',
      'desc'
    );

    System.Assert(
      bothResults.size() == 1,
      'Should return 1 order for Test Customer at StationB'
    );
    System.Assert(bothResults[0].Name == 'Order2', 'Should return Order2');

    List<breadwinner_ns__BW_Sales_Order__c> limitedResults = OpenRepairsController.getOpenRepairs(
      'Test Customer',
      null,
      1,
      1,
      'name',
      'asc'
    );

    System.Assert(
      limitedResults.size() == 1,
      'Should return 1 order with limit and offset'
    );
    System.Assert(limitedResults[0].Name == 'Order2', 'Should return Order2');

    Test.stopTest();
  }

  @isTest
  static void testGetOpenRepairs_invalidSortBy() {
    setupData();

    Test.startTest();
    List<breadwinner_ns__BW_Sales_Order__c> results = OpenRepairsController.getOpenRepairs(
      null,
      null,
      10,
      0,
      'invalidField',
      'asc'
    );
    System.Assert(
      results.size() == 2,
      'Should return 2 orders with invalid sortBy'
    );
    System.Assert(results[0].Name == 'Order1', 'Should return Order1 first');
    System.Assert(results[1].Name == 'Order2', 'Should return Order2 second');
    Test.stopTest();
  }

  @isTest
  static void testGetOpenRepairs_exception() {
    setupData();

    Test.startTest();
    try {
      OpenRepairsController.getOpenRepairs(null, null, -1, 0, 'name', 'asc');
      System.assert(false, 'Exception should have been thrown');
    } catch (AurahandledException e) {
      System.Assert(
        e.getMessage() != null,
        'Exception message should not be null'
      );
    }
    Test.stopTest();
  }
}
