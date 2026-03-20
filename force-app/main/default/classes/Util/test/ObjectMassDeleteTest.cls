@isTest
private class ObjectMassDeleteTest {
  @isTest
  static void testMassDeleteDeletesInsertedLogs() {
    List<Script_Log__c> logs = new List<Script_Log__c>{
      new Script_Log__c(
        Title__c = 'ObjectMassDelete Test 1',
        Details__c = 'Row 1',
        Timestamp__c = Datetime.now()
      ),
      new Script_Log__c(
        Title__c = 'ObjectMassDelete Test 2',
        Details__c = 'Row 2',
        Timestamp__c = Datetime.now()
      )
    };
    insert logs;

    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM Script_Log__c
        WHERE Title__c LIKE 'ObjectMassDelete Test %'
      ]
    );

    ObjectMassDelete batch = new ObjectMassDelete('Script_Log__c');

    Test.startTest();
    batch.start(null);

    List<SObject> scope = new List<SObject>();
    scope.addAll(
      [
        SELECT Id
        FROM Script_Log__c
        WHERE Title__c LIKE 'ObjectMassDelete Test %'
      ]
    );
    batch.execute(null, scope);
    batch.finish(null);
    Test.stopTest();

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Script_Log__c
        WHERE Title__c LIKE 'ObjectMassDelete Test %'
      ]
    );
  }

  @isTest
  static void testMassDeleteHandlesEmptyScope() {
    Test.startTest();
    Database.executeBatch(new ObjectMassDelete('Lead'), 50);
    Test.stopTest();

    System.assertEquals(0, [SELECT COUNT() FROM Lead]);
  }
}
