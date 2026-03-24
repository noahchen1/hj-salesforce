public with sharing class NpcTaskScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    List<breadwinner_ns__BW_Line_Item__c> lineItems = [
      SELECT
        Id,
        breadwinner_ns__Invoice__c,
        breadwinner_ns__Invoice__r.Name,
        breadwinner_ns__Invoice__r.breadwinner_ns__SalesRepName__c,
        breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c,
        breadwinner_ns__Invoice__r.OwnerId,
        breadwinner_ns__Item__c,
        breadwinner_ns__Item__r.Name
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE
        (Amount_after_Discounts__c >= 5000
        OR breadwinner_ns__Amount__c >= 5000)
        AND breadwinner_ns__Invoice__c != NULL
        AND (breadwinner_ns__Invoice__r.breadwinner_ns__TranDate__c = :Date.today()
          .addDays(-7)
        OR breadwinner_ns__Invoice__r.breadwinner_ns__TranDate__c = :Date.today()
          .addDays(-6)
        OR breadwinner_ns__Invoice__r.breadwinner_ns__TranDate__c = :Date.today()
          .addDays(-5)) //This part needs to be changed for the official process
    ];

    Set<Id> lineItemIds = new Set<Id>();
    Set<String> repNames = new Set<String>();

    for (breadwinner_ns__BW_Line_Item__c lineItem : lineItems) {
      lineItemIds.add(lineItem.Id);

      String repName = normalizeRepName(
        lineItem.breadwinner_ns__Invoice__r.breadwinner_ns__SalesRepName__c
      );

      if (!String.isBlank(repName)) {
        repNames.add(repName);
      }
    }

    Map<String, Id> userIdByName = new Map<String, Id>();

    if (!repNames.isEmpty()) {
      for (User u : [SELECT Id, Name FROM User WHERE Name IN :repNames]) {
        userIdByName.put(u.Name, u.Id);
      }
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

      String repName = normalizeRepName(
        lineItem.breadwinner_ns__Invoice__r.breadwinner_ns__SalesRepName__c
      );

      if (!userIdByName.containsKey(repName)) {
        continue;
      }

      Id invoiceId = lineItem.breadwinner_ns__Invoice__c;
      Id accountId = lineItem.breadwinner_ns__Invoice__r.breadwinner_ns__Salesforce_Account__c;
      Id itemId = lineItem.breadwinner_ns__Item__c;
      Id lineItemId = lineItem.Id;
      Id ownerId = userIdByName.get(repName);

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

  private static String normalizeRepName(String repName) {
    if (String.isBlank(repName)) {
      return null;
    }

    List<String> parts = repName.trim().split('\\s+');
    if (parts.isEmpty()) {
      return null;
    }

    if (parts.size() == 1) {
      return parts[0];
    }

    return parts[0] + ' ' + parts[parts.size() - 1];
  }
}
