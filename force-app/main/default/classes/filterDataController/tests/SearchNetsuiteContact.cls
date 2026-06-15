@isTest
private class SearchNetsuiteContact {
  @isTest
  static void searchNetsuiteContact_success() {
    breadwinner_ns__BW_Contact__c nsContact = new breadwinner_ns__BW_Contact__c(
      Name = 'test contact',
      breadwinner_ns__InternalId__c = '123'
    );

    insert nsContact;

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchNetsuiteContact(
      'test contact'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Should return the netsuite contact'
    );
    System.assertEquals(
      'test contact',
      results[0].Name,
      'Should return correct netsuite contact name'
    );
    System.assertEquals(
      '123',
      results[0].NsId,
      'Should return correct InternalId'
    );
  }

  @isTest
  static void searchNetsuiteContact_emptyResults() {
    breadwinner_ns__BW_Contact__c nsContact = new breadwinner_ns__BW_Contact__c(
      Name = 'unrelated',
      breadwinner_ns__InternalId__c = '123'
    );

    insert nsContact;
    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchNetsuiteContact(
      'test contact'
    );
    Test.stopTest();

    System.assertEquals(0, results.size(), 'Should return no results');
  }
}
