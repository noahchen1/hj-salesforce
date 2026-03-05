@isTest
private class NsLineItemTriggerTest {
  @isTest
  static void testTriggerFiresOnInsert() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    NsLineItemService.ignoreTrigger = true;

    Test.startTest();
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;
    Test.stopTest();

    List<breadwinner_ns__BW_Line_Item__c> records = [
      SELECT Id, Name
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Name = 'Test Line'
    ];
    System.assertEquals(
      1,
      records.size(),
      'Trigger should complete without errors on insert'
    );
  }

  @isTest
  static void testTriggerFiresOnUpdate() {
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;

    NsLineItemService.ignoreTrigger = true;

    Test.startTest();
    lineItem.Name = 'Updated Test Line';
    update lineItem;
    Test.stopTest();

    List<breadwinner_ns__BW_Line_Item__c> updated = [
      SELECT Name
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :lineItem.Id
    ];
    System.assertEquals(
      'Updated Test Line',
      updated[0].Name,
      'Trigger should complete without errors on update'
    );
  }

  @isTest
  static void testTriggerFiresOnDelete() {
    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line',
      breadwinner_ns__Transaction_Type__c = 'Invoice'
    );
    insert lineItem;
    Id lineItemId = lineItem.Id;

    NsLineItemService.ignoreTrigger = true;

    Test.startTest();
    delete lineItem;
    Test.stopTest();

    List<breadwinner_ns__BW_Line_Item__c> deleted = [
      SELECT Id
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :lineItemId
    ];
    System.assertEquals(
      0,
      deleted.size(),
      'Trigger should complete without errors on delete'
    );
  }
}
