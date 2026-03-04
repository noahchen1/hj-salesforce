@isTest
private class AscSalesHistoryBatchTest {
  private static nco_aschistoricalsales__c createAscLineItem() {
    nco_aschistoricalsales__c lineItem = new nco_aschistoricalsales__c(
      Name = 'Test Line'
    );
    insert lineItem;

    return lineItem;
  }

  @isTest
  static void testInsertSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = createAscLineItem();

    Sales_History__c goodInsert = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id
    );

    AscSalesHistoryBatch.testOverrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ goodInsert },
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{}
    };

    Test.startTest();
    Database.executeBatch(new AscSalesHistoryBatch(), 1);
    Test.stopTest();

    List<Sales_History__c> record = [
      SELECT Id
      FROM Sales_History__c
      WHERE Name = 'Valid Record'
    ];

    System.assertEquals(1, record.size());
  }

  @isTest
  static void testInsertFailure() {
    createAscLineItem();

    Sales_History__c badInsert = new Sales_History__c(Name = null);

    AscSalesHistoryBatch.testOverrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{ badInsert },
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{}
    };

    Test.startTest();
    Database.executeBatch(new AscSalesHistoryBatch(), 1);
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c
      FROM Script_Log__c
      WHERE Title__c = 'ASC Sales History - Insert Error'
    ];

    System.assertEquals(1, logs.size());
  }

  @isTest
  static void testUpdateSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = createAscLineItem();

    Sales_History__c existing = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id
    );
    insert existing;

    existing.Quantity__c = 1;

    AscSalesHistoryBatch.testOverrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{ existing },
      'toDelete' => new List<Sales_History__c>{}
    };

    Test.startTest();
    Database.executeBatch(new AscSalesHistoryBatch(), 1);
    Test.stopTest();

    Sales_History__c refreshed = [
      SELECT Id, Quantity__c
      FROM Sales_History__c
      WHERE Id = :existing.Id
      LIMIT 1
    ];

    System.assertEquals(1, refreshed.Quantity__c);
  }

  @isTest
  static void testUpdateFailure() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = createAscLineItem();

    Sales_History__c existing = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id
    );
    insert existing;

    existing.Name = null;

    AscSalesHistoryBatch.testOverrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{ existing },
      'toDelete' => new List<Sales_History__c>{}
    };

    Test.startTest();
    Database.executeBatch(new AscSalesHistoryBatch(), 1);
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c
      FROM Script_Log__c
      WHERE Title__c = 'ASC Sales History - Update Error'
    ];

    System.assertEquals(1, logs.size());
  }

  @isTest
  static void testDeleteSuccess() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c lineItem = createAscLineItem();

    Sales_History__c existing = new Sales_History__c(
      Name = 'Valid Record',
      Account__c = acct.Id,
      ASC_Historical_Sales__c = lineItem.Id
    );
    insert existing;

    AscSalesHistoryBatch.testOverrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => new List<Sales_History__c>{},
      'toUpdate' => new List<Sales_History__c>{},
      'toDelete' => new List<Sales_History__c>{ existing }
    };

    Test.startTest();
    Database.executeBatch(new AscSalesHistoryBatch(), 1);
    Test.stopTest();

    List<Sales_History__c> record = [
      SELECT Id
      FROM Sales_History__c
      WHERE Name = 'Valid Record'
    ];
    System.assertEquals(0, record.size());

    List<Script_Log__c> logs = [
      SELECT Id
      FROM Script_Log__c
      WHERE Title__c = 'ASC Sales History - Delete Error'
    ];
    System.assertEquals(0, logs.size());
  }

  @isTest
  static void testEmptyUpdateMap() {
    createAscLineItem();

    AscSalesHistoryBatch.testOverrideMap = new Map<String, List<Sales_History__c>>{
      'toInsert' => null,
      'toUpdate' => null,
      'toDelete' => null
    };

    Boolean didThrow = false;

    try {
      Test.startTest();
      Database.executeBatch(new AscSalesHistoryBatch(), 1);
      Test.stopTest();
    } catch (Exception e) {
      didThrow = true;
    }

    System.assert(!didThrow, 'Job executed without exceptions');
  }
}
