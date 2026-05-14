@isTest
private class SearchSalesRepTest {
  @isTest
  static void testSearchSalesRep_success_and_partial() {
    breadwinner_ns__BW_Employee__c e1 = new breadwinner_ns__BW_Employee__c(
      Name = 'Test Rep',
      breadwinner_ns__IsSalesRep__c = true,
      breadwinner_ns__InternalId__c = 'EMP1'
    );
    breadwinner_ns__BW_Employee__c e2 = new breadwinner_ns__BW_Employee__c(
      Name = 'Another Rep',
      breadwinner_ns__IsSalesRep__c = true,
      breadwinner_ns__InternalId__c = 'EMP2'
    );
    breadwinner_ns__BW_Employee__c e3 = new breadwinner_ns__BW_Employee__c(
      Name = 'Not a Rep',
      breadwinner_ns__IsSalesRep__c = false,
      breadwinner_ns__InternalId__c = 'EMP3'
    );
    insert new List<breadwinner_ns__BW_Employee__c>{ e1, e2, e3 };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSalesRep(
      'Rep'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return two sales reps');
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    System.assert(names.contains('Test Rep'), 'Should contain Test Rep');
    System.assert(names.contains('Another Rep'), 'Should contain Another Rep');
    Set<String> nsIds = new Set<String>{ results[0].NsId, results[1].NsId };
    System.assert(
      nsIds.contains('EMP1'),
      'Should contain correct InternalId EMP1'
    );
    System.assert(
      nsIds.contains('EMP2'),
      'Should contain correct InternalId EMP2'
    );
  }

  @isTest
  static void testSearchSalesRep_emptyResults() {
    breadwinner_ns__BW_Employee__c e1 = new breadwinner_ns__BW_Employee__c(
      Name = 'Test Rep',
      breadwinner_ns__IsSalesRep__c = true,
      breadwinner_ns__InternalId__c = 'EMP4'
    );
    insert e1;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchSalesRep(
      'John'
    );
    Test.stopTest();
    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
