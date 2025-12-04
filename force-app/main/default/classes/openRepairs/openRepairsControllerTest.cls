@isTest
private class openRepairsControllerTest {
  private static void createTestOrder() {
    breadwinner_ns__BW_Company__c entity = new breadwinner_ns__BW_Company__c(
      Name = 'Test Customer'
    );

    insert entity;

    breadwinner_ns__BW_Sales_Order__c order = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order',
      breadwinner_ns__CreatedDate__c = Date.today(),
      breadwinner_ns__Total__c = 100,
      ncf_body_repair_station__c = 'Station A',
      ncf_body1__c = 'Type X',
      breadwinner_ns__Status__c = 'Open',
      ncf_body_repair_order__c = true,
      breadwinner_ns__Entity__c = entity.Id
    );

    insert order;
  }

  @isTest
  static void testGetOpenRepairs_Proper() {
    createTestOrder();

    Test.startTest();
    List<breadwinner_ns__BW_Sales_Order__c> results = OpenRepairsController.getOpenRepairs(
      'Test Customer',
      'Station A',
      10,
      0
    );

    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should at least one record');
  }

  @isTest
  static void testGetOpenRepairs_EmptyResults() {
    createTestOrder();

    Test.startTest();
    List<breadwinner_ns__BW_Sales_Order__c> results = OpenRepairsController.getOpenRepairs(
      'Test Entity',
      'Station A',
      10,
      0
    );

    System.debug(results);
    System.debug(results.size());

    Test.stopTest();

    System.assertEquals(0, results.size(), 'Should return empty results');
  }

  @isTest
  static void testGetOpenRepairs_Exception() {
    Test.startTest();
    try {
      OpenRepairsController.getOpenRepairs(null, null, -1, 0);
      System.assert(false, 'Exception should have been thrown');
    } catch (AurahandledException e) {
      System.assert(
        e.getMessage() != null,
        'Exception message should not be null'
      );
    }

    Test.stopTest();
  }
}
