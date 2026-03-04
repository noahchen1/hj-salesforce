@isTest
private class NsSalesHistoryBatchTest {
  @isTest
  static void testInsertSuccess() {
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

    NsSalesHistoryBatch.testOverrideMap = overrideMap;

    Boolean didThrow = false;

    try {
      Test.startTest();
      Database.executeBatch(new NsSalesHistoryBatch(), 1);
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
  static void testInsertFailure() {
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c badInsert = new Sales_History__c(Name = null);

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ badInsert },
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{}
    };

    NsSalesHistoryBatch.testOverrideMap = overrideMap;

    Test.startTest();
    Database.executeBatch(new NsSalesHistoryBatch(), 1);
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c
      FROM Script_Log__c
    ];

    System.assertEquals(1, logs.size());
    System.assertEquals(logs[0].Title__c, 'NS Sales History - Insert Error');
  }

  @isTest
  static void testUpdateSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c existing = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      NetSuite_Line_Item__c = lineItem.Id
    );

    insert existing;

    existing.Quantity__c = 1;

    Sales_History__c goodUpdate = existing;

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{ goodUpdate },
      'toDelete' => new List<Sales_History__c>{}
    };

    NsSalesHistoryBatch.testOverrideMap = overrideMap;

    Boolean didThrow = false;

    try {
      Test.startTest();
      Database.executeBatch(new NsSalesHistoryBatch(), 1);
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job executed without exceptions');

    List<Sales_History__c> record = [SELECT Name, Id FROM Sales_History__c];

    System.assertEquals(1, record.size());
    System.assertEquals(record[0].Quantity__c, 1);
  }

  @isTest
  static void testUpdateFailure() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c existing = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      NetSuite_Line_Item__c = lineItem.Id
    );

    insert existing;

    existing.Name = null;

    Sales_History__c goodUpdate = existing;

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{ goodUpdate },
      'toDelete' => new List<Sales_History__c>{}
    };

    NsSalesHistoryBatch.testOverrideMap = overrideMap;

    Test.startTest();
    Database.executeBatch(new NsSalesHistoryBatch(), 1);
    Test.stopTest();

    Test.startTest();
    Database.executeBatch(new NsSalesHistoryBatch(), 1);
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c
      FROM Script_Log__c
    ];

    System.assertEquals(1, logs.size());
    System.assertEquals(logs[0].Title__c, 'NS Sales History - Update Error');
  }

  @isTest
  static void testDeleteSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    Sales_History__c existing = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      NetSuite_Line_Item__c = lineItem.Id
    );

    insert existing;

    Sales_History__c toDelete = existing;

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{ toDelete }
    };

    NsSalesHistoryBatch.testOverrideMap = overrideMap;

    Boolean didThrow = false;

    try {
      Test.startTest();
      Database.executeBatch(new NsSalesHistoryBatch(), 1);
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

    System.assertEquals(0, record.size());

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c
      FROM Script_Log__c
      WHERE Title__c = 'NS Sales History - Delete Error'
    ];
    System.assertEquals(
      0,
      logs.size(),
      'No delete errors should be logged: ' + logs
    );
  }

  @isTest
  static void testEmptyUpdateMap() {
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );

    insert lineItem;

    Map<String, List<Sales_History__c>> overrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => null,
      'toUpdate' => null,
      'toDelete' => null
    };

    NsSalesHistoryBatch.testOverrideMap = overrideMap;

    Boolean didThrow = false;

    try {
      Test.startTest();
      Database.executeBatch(new NsSalesHistoryBatch(), 1);
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job executed without exceptions');
  }
}
