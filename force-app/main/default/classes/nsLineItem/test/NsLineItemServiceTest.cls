@isTest
private class NsLineItemServiceTest {
  @isTest
  static void testOnAfterInsertSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c goodInsert = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      NetSuite_Line_Item__c = lineItem.Id
    );

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ goodInsert },
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{}
    };

    NsLineItemService.testOverrideMap = overrideMap;

    List<breadwinner_ns__BW_Line_Item__c> lineItems = [
      SELECT Id
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :lineItem.Id
    ];

    Boolean didThrow = false;

    try {
      Test.startTest();
      NsLineItemService.onAfterInsert(lineItems);
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
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c badInsert = new Sales_History__c(Name = null);

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ badInsert },
      'toUpdate' => new List<Sales_History__c>{ badInsert },
      'toDelete' => new List<Sales_History__c>{}
    };

    NsLineItemService.testOverrideMap = overrideMap;

    List<breadwinner_ns__BW_Line_Item__c> lineItems = [
      SELECT Id
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :lineItem.Id
    ];

    Test.startTest();
    NsLineItemService.onAfterInsert(lineItems);
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

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c existingHistory = new Sales_History__c(
      Name = 'Existing Record',
      Account__c = acct.Id,
      NetSuite_Line_Item__c = lineItem.Id
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

    NsLineItemService.testOverrideMap = overrideMap;

    breadwinner_ns__BW_Line_Item__c oldLine = lineItem.clone();

    lineItem.Name = 'New Test Line';

    Test.startTest();
    NsLineItemService.onAfterUpdate(
      new List<breadwinner_ns__BW_Line_Item__c>{ lineItem },
      new Map<Id, breadwinner_ns__BW_Line_Item__c>{ lineItem.Id => oldLine }
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
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c badUpdate = new Sales_History__c(Name = null);

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ badUpdate },
      'toUpdate' => new List<Sales_History__c>{ badUpdate }
    };

    NsLineItemService.testOverrideMap = overrideMap;

    breadwinner_ns__BW_Line_Item__c oldLine = lineItem.clone();
    lineItem.Name = 'New Test Line';

    Test.startTest();
    NsLineItemService.onAfterUpdate(
      new List<breadwinner_ns__BW_Line_Item__c>{ lineItem },
      new Map<Id, breadwinner_ns__BW_Line_Item__c>{ lineItem.Id => oldLine }
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

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c history = new Sales_History__c(
      Name = 'History For Delete',
      Account__c = acct.Id,
      NetSuite_Line_Item__c = lineItem.Id,
      Source__c = 'NS',
      Source_Id__c = lineItem.Id + '-001'
    );
    insert history;

    Test.startTest();
    NsLineItemService.onAfterDelete(
      new List<breadwinner_ns__BW_Line_Item__c>{ lineItem }
    );
    Test.stopTest();

    List<Sales_History__c> deleted = [
      SELECT Id
      FROM Sales_History__c
    ];

    System.assertEquals(0, deleted.size());
  }
}
