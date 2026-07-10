@isTest
private class SearchNetsuiteContact {
  @isTest
  static void searchNetsuiteContact_success_and_prefix() {
    breadwinner_ns__BW_Contact__c contactOne = new breadwinner_ns__BW_Contact__c(
      Name = 'Test Contact Alpha',
      breadwinner_ns__InternalId__c = 'CONTACT-1'
    );
    breadwinner_ns__BW_Contact__c contactTwo = new breadwinner_ns__BW_Contact__c(
      Name = 'Test Contact Beta',
      breadwinner_ns__InternalId__c = 'CONTACT-2'
    );
    breadwinner_ns__BW_Contact__c unrelatedContact = new breadwinner_ns__BW_Contact__c(
      Name = 'Other Contact',
      breadwinner_ns__InternalId__c = 'CONTACT-3'
    );

    insert new List<breadwinner_ns__BW_Contact__c>{
      contactOne,
      contactTwo,
      unrelatedContact
    };

    Test.startTest();
    List<FilterDataController.LookupResult> results = FilterDataController.searchNetsuiteContact(
      'Test Contact'
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Should return matching contacts');
    Set<String> ids = new Set<String>{ results[0].Id, results[1].Id };
    Set<String> names = new Set<String>{ results[0].Name, results[1].Name };
    Set<String> nsIds = new Set<String>{ results[0].NsId, results[1].NsId };
    System.assert(ids.contains(String.valueOf(contactOne.Id)));
    System.assert(ids.contains(String.valueOf(contactTwo.Id)));
    System.assert(names.contains('Test Contact Alpha'));
    System.assert(names.contains('Test Contact Beta'));
    System.assert(nsIds.contains('CONTACT-1'));
    System.assert(nsIds.contains('CONTACT-2'));
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
