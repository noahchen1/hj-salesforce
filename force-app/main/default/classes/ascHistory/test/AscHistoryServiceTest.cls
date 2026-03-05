@isTest
private class AscHistoryServiceTest {
  @isTest
  static void testOnAfterInsertSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = new nco_aschistoricalsales__c(
      Name = 'Test ASC Line',
      Account__c = acct.Id
    );
    insert lineItem;

    Sales_History__c goodInsert = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id
    );

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ goodInsert },
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{}
    };

    AscHistoryService.testOverrideMap = overrideMap;

    List<nco_aschistoricalsales__c> lineItems = [
      SELECT Id
      FROM nco_aschistoricalsales__c
      WHERE Id = :lineItem.Id
    ];

    Boolean didThrow = false;

    try {
      Test.startTest();
      AscHistoryService.onAfterInsert(lineItems);
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job executed without exceptions');

    List<Sales_History__c> record = [
      SELECT Name, Id
      FROM Sales_History__c
      WHERE Name = 'Valid Record'
    ];

    System.assertEquals(1, record.size());
  }

  @isTest
  static void testOnAfterInsertFailure() {
    nco_aschistoricalsales__c lineItem = new nco_aschistoricalsales__c(
      Name = 'Test ASC Line'
    );
    insert lineItem;

    Sales_History__c badInsert = new Sales_History__c(Name = null);

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ badInsert },
      'toUpdate' => new List<Sales_History__c>{ badInsert },
      'toDelete' => new List<Sales_History__c>{}
    };

    AscHistoryService.testOverrideMap = overrideMap;

    List<nco_aschistoricalsales__c> lineItems = [
      SELECT Id
      FROM nco_aschistoricalsales__c
      WHERE Id = :lineItem.Id
    ];

    Test.startTest();
    AscHistoryService.onAfterInsert(lineItems);
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c
      FROM Script_Log__c
    ];

    System.assertEquals(2, logs.size());
  }

  @isTest
  static void testOnAfterUpdateSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = new nco_aschistoricalsales__c(
      Name = 'Test ASC Line',
      Account__c = acct.Id
    );
    insert lineItem;

    Sales_History__c existingHistory = new Sales_History__c(
      Name = 'Existing Record',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id
    );
    insert existingHistory;

    Sales_History__c updatedHistory = new Sales_History__c(
      Id = existingHistory.Id,
      Name = 'Updated Record'
    );

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{ updatedHistory }
    };

    AscHistoryService.testOverrideMap = overrideMap;

    nco_aschistoricalsales__c oldLine = lineItem.clone();

    lineItem.Name = 'New Test ASC Line';

    Test.startTest();
    AscHistoryService.onAfterUpdate(
      new List<nco_aschistoricalsales__c>{ lineItem },
      new Map<Id, nco_aschistoricalsales__c>{ lineItem.Id => oldLine }
    );
    Test.stopTest();

    List<Sales_History__c> updated = [
      SELECT Name
      FROM Sales_History__c
      WHERE Id = :existingHistory.Id
    ];

    System.assertEquals(1, updated.size());
    System.assertEquals('Updated Record', updated[0].Name);
  }

  @isTest
  static void testOnAfterUpdateFailure() {
    nco_aschistoricalsales__c lineItem = new nco_aschistoricalsales__c(
      Name = 'Test ASC Line'
    );
    insert lineItem;

    Sales_History__c badUpdate = new Sales_History__c(Name = null);

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ badUpdate },
      'toUpdate' => new List<Sales_History__c>{ badUpdate }
    };

    AscHistoryService.testOverrideMap = overrideMap;

    nco_aschistoricalsales__c oldLine = lineItem.clone();
    lineItem.Name = 'New Test ASC Line';

    Test.startTest();
    AscHistoryService.onAfterUpdate(
      new List<nco_aschistoricalsales__c>{ lineItem },
      new Map<Id, nco_aschistoricalsales__c>{ lineItem.Id => oldLine }
    );
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c
      FROM Script_Log__c
    ];

    System.assertEquals(2, logs.size());
  }

  @isTest
  static void testOnAfterDeleteSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = new nco_aschistoricalsales__c(
      Name = 'Test ASC Line',
      Account__c = acct.Id
    );
    insert lineItem;

    Sales_History__c history = new Sales_History__c(
      Name = 'History For Delete',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id,
      Source__c = 'NS',
      Source_Id__c = lineItem.Id + '-001'
    );
    insert history;

    Test.startTest();
    AscHistoryService.onAfterDelete(
      new List<nco_aschistoricalsales__c>{ lineItem }
    );
    Test.stopTest();

    List<Sales_History__c> deleted = [
      SELECT Id
      FROM Sales_History__c
    ];

    System.assertEquals(0, deleted.size());
  }
}
