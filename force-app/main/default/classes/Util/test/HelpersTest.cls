@isTest
private class HelpersTest {
  @isTest
  static void testGetFirstNonEmptyString() {
    System.assertEquals(null, Helpers.getFirstNonEmptyString(null));
    System.assertEquals(
      null,
      Helpers.getFirstNonEmptyString(new List<String>())
    );
    System.assertEquals(
      null,
      Helpers.getFirstNonEmptyString(new List<String>{ '', '   ' })
    );
    System.assertEquals(
      'value',
      Helpers.getFirstNonEmptyString(
        new List<String>{ '', '   ', 'value', 'next' }
      )
    );
  }

  @isTest
  static void testWriteLog() {
    Test.startTest();
    Helpers.writeLog('Helpers Test', 'Details from unit test');
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c, Timestamp__c
      FROM Script_Log__c
      WHERE Title__c = 'Helpers Test'
      LIMIT 1
    ];

    System.assertEquals(1, logs.size());
    System.assertEquals('Details from unit test', logs[0].Details__c);
    System.assertNotEquals(null, logs[0].Timestamp__c);
  }

  @isTest
  static void testValuesEqual() {
    System.assertEquals(true, Helpers.valuesEqual(null, null));
    System.assertEquals(false, Helpers.valuesEqual(null, 'x'));
    System.assertEquals(true, Helpers.valuesEqual('100', 100));
    System.assertEquals(false, Helpers.valuesEqual('abc', 'def'));
  }

  @isTest
  static void testToIntOrNull() {
    System.assertEquals(null, Helpers.toIntOrNull(null));
    System.assertEquals(null, Helpers.toIntOrNull('   '));
    System.assertEquals(42, Helpers.toIntOrNull(' 42 '));
    System.assertEquals(-7, Helpers.toIntOrNull('-7'));
    System.assertEquals(null, Helpers.toIntOrNull('not-a-number'));
  }

  @isTest
  static void testGetPicklistLabels() {
    Map<String, String> validResult = Helpers.getPicklistLabels(
      'Task',
      'Priority'
    );
    System.assertNotEquals(null, validResult);
    System.assert(
      validResult.size() > 0,
      'Expected standard Task.Priority values'
    );

    Map<String, String> invalidResult = Helpers.getPicklistLabels(
      'NotARealObject__c',
      'Fake_Field__c'
    );
    System.assertNotEquals(null, invalidResult);
    System.assertEquals(0, invalidResult.size());
  }
}
