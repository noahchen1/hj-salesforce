@isTest
private class SearchSalesRepTest {
  @isTest
  static void testSearchSalesRep_success() {
    breadwinner_ns__BW_Sales_Order__c newOrder1 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order1',
      breadwinner_ns__SalesRepName__c = 'Test Rep'
    );

    breadwinner_ns__BW_Sales_Order__c newOrder2 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order2',
      ncf_body_salesrep2__c = 'Test Rep2'
    );

    insert newOrder1;
    insert newOrder2;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSalesRep(
      'Test Rep'
    );
    Test.stopTest();

    System.assert(results.size() == 2, 'Should return two result');
    System.assert(
      results[0].Name.contains('Test Rep'),
      'Should return the Test Rep'
    );
  }

  @isTest
  static void testSearchSalesRep_emptyResults() {
    breadwinner_ns__BW_Sales_Order__c newOrder = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Test Order',
      breadwinner_ns__SalesRepName__c = 'Test Rep'
    );

    insert newOrder;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSalesRep(
      'John'
    );
    Test.stopTest();

    System.assert(results.size() == 0, 'Should return no results');
  }
}
