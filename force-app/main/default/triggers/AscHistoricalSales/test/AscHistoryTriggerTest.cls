@isTest
private class AscHistoryTriggerTest {
  @isTest
  static void testTriggerFiresOnInsert() {
    AscHistoryService.ignoreTrigger = true;

    Test.startTest();
    nco_aschistoricalsales__c ascRecord = new nco_aschistoricalsales__c(
      Name = 'Test ASC Record'
    );
    insert ascRecord;
    Test.stopTest();

    List<nco_aschistoricalsales__c> records = [
      SELECT Id, Name
      FROM nco_aschistoricalsales__c
      WHERE Name = 'Test ASC Record'
    ];
    System.assertEquals(
      1,
      records.size(),
      'Trigger should complete without errors on insert'
    );
  }

  @isTest
  static void testTriggerFiresOnUpdate() {
    nco_aschistoricalsales__c ascRecord = new nco_aschistoricalsales__c(
      Name = 'Test ASC Record'
    );
    insert ascRecord;

    AscHistoryService.ignoreTrigger = true;

    Test.startTest();
    ascRecord.Name = 'Updated ASC Record';
    update ascRecord;
    Test.stopTest();

    List<nco_aschistoricalsales__c> updated = [
      SELECT Name
      FROM nco_aschistoricalsales__c
      WHERE Id = :ascRecord.Id
    ];
    System.assertEquals(
      'Updated ASC Record',
      updated[0].Name,
      'Trigger should complete without errors on update'
    );
  }

  @isTest
  static void testTriggerFiresOnDelete() {
    nco_aschistoricalsales__c ascRecord = new nco_aschistoricalsales__c(
      Name = 'Test ASC Record'
    );
    insert ascRecord;
    Id recordId = ascRecord.Id;

    AscHistoryService.ignoreTrigger = true;

    Test.startTest();
    delete ascRecord;
    Test.stopTest();

    List<nco_aschistoricalsales__c> deleted = [
      SELECT Id
      FROM nco_aschistoricalsales__c
      WHERE Id = :recordId
    ];
    System.assertEquals(
      0,
      deleted.size(),
      'Trigger should complete without errors on delete'
    );
  }
}
