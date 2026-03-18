public with sharing class NpcTaskScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    List<breadwinner_ns__BW_Line_Item__c> lineItems = [
      SELECT
        Id,
        breadwinner_ns__Invoice__c,
        breadwinner_ns__Invoice__r.Name,
        breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c,
        breadwinner_ns__Invoice__r.OwnerId,
        breadwinner_ns__Item__c,
        breadwinner_ns__Item__r.Name
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE
        (Amount_after_Discounts__c >= 5000
        OR breadwinner_ns__Amount__c >= 5000)
        AND breadwinner_ns__Invoice__c != NULL
        AND breadwinner_ns__Invoice__r.breadwinner_ns__TranDate__c = :Date.today()
          .addDays(-7)
    ];

    Set<Id> lineItemIds = new Set<Id>();

    for (breadwinner_ns__BW_Line_Item__c lineItem : lineItems) {
      lineItemIds.add(lineItem.Id);
    }

    Map<Id, Task> existingTasks = new Map<Id, Task>();

    for (Task task : [
      SELECT Id, NetSuite_Line_Item__c
      FROM Task
      WHERE NetSuite_Line_Item__c IN :lineItemIds
    ]) {
      existingTasks.put(task.NetSuite_Line_Item__c, task);
    }

    List<Task> tasksToInsert = new List<Task>();

    for (breadwinner_ns__BW_Line_Item__c lineItem : lineItems) {
      if (existingTasks.containsKey(lineItem.Id)) {
        continue;
      }

      Id invoiceId = lineItem.breadwinner_ns__Invoice__c;
      Id accountId = lineItem.breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c;
      Id itemId = lineItem.breadwinner_ns__Item__c;
      Id lineItemId = lineItem.Id;
      Id ownerId = lineItem.breadwinner_ns__Invoice__r.OwnerId;

      tasksToInsert.add(
        new Task(
          Subject = 'Reminder: Complete NPC',
          Status = 'Not Started',
          Priority = 'Normal',
          ActivityDate = Date.today(),
          OwnerId = ownerId,
          Invoice__c = invoiceId,
          Account__c = accountId,
          NetSuite_Item__c = itemId,
          NetSuite_Line_Item__c = lineItemId
        )
      );
    }

    if (!tasksToInsert.isEmpty()) {
      insert tasksToInsert;
    }
  }
}
