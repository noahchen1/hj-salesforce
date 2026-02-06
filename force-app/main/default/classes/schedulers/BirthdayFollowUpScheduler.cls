public with sharing class BirthdayFollowUpScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    Date today = Date.today();
    Date nextMonth = today.addMonths(1);
    Integer targetMonth = nextMonth.month();

    System.debug('target month: ' + targetMonth);

    List<Account> accounts = [
      SELECT Id, Birthdate__c, OwnerId
      FROM Account
      WHERE
        Birthdate__c != NULL
        AND CALENDAR_MONTH(Birthdate__c) = :targetMonth
        AND Id = '001WJ00000XDfQaYAL'
    ];

    System.debug('Accounts: ' + accounts);

    Set<Id> accountIds = new Set<Id>();

    for (Account a : accounts) {
      accountIds.add(a.Id);
    }

    Date startOfTargetMonth = Date.newInstance(
      nextMonth.year(),
      nextMonth.month(),
      1
    );
    Date endOfTargetMonth = startOfTargetMonth.addMonths(1).addDays(-1);

    Map<Id, Task> existingTasks = new Map<Id, Task>();

    for (Task t : [
      SELECT Id, AccountId
      FROM Task
      WHERE
        AccountId IN :accountIds
        AND Subject = 'Upcoming Birthday Follow-Up'
        AND ActivityDate >= :startOfTargetMonth
        AND ActivityDate <= :endOfTargetMonth
    ]) {
      existingTasks.put(t.AccountId, t);
    }

    List<Task> tasksToInsert = new List<Task>();

    for (Account a : accounts) {
      if (existingTasks.containsKey(a.Id)) {
        continue;
      }

      Date dueDate = Date.newInstance(
        today.year(),
        a.Birthdate__c.month(),
        a.Birthdate__c.day()
      );

      if (dueDate < today) {
        dueDate = dueDate.addYears(1);
      }

      tasksToInsert.add(
        new Task(
          Subject = 'Upcoming Birthday Follow-Up',
          Status = 'Not Started',
          Priority = 'Normal',
          ActivityDate = dueDate,
          OwnerId = a.OwnerId,
          WhatId = a.Id
        )
      );
    }

    if (!tasksToInsert.isEmpty()) {
      insert tasksToInsert;
    }
  }
}
