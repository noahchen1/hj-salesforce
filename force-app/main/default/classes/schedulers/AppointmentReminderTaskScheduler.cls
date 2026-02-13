public with sharing class AppointmentReminderTaskScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    Date today = Date.today();
    Date tomorrow = today.addDays(1);

    List<Event> upcomingEvents = [
      SELECT
        ActivityDate,
        Owner.Name,
        Owner.Type,
        WhatId,
        WhoId,
        Acuity_Appointment__c
      FROM Event
      WHERE Owner.Type = 'User' AND ActivityDate = :tomorrow
    ];

    Set<Id> appointmentIds = new Set<Id>();

    for (Event event : upcomingEvents) {
      appointmentIds.add(event.Acuity_Appointment__c);
    }

    Map<Id, Task> existingTasks = new Map<Id, Task>();

    for (Task t : [
      SELECT Id, WhatId
      FROM Task
      WHERE ActivityDate = :today AND WhatId IN :appointmentIds
    ]) {
      existingTasks.put(t.WhatId, t);
    }

    List<Task> tasksToInsert = new List<Task>();

    for (Event event : upcomingEvents) {
      if (existingTasks.containskey(event.Acuity_Appointment__c)) {
        continue;
      }

      tasksToInsert.add(
        new Task(
          Subject = 'Upcoming Acuity Appointment',
          Status = 'Not Started',
          Priority = 'Normal',
          ActivityDate = Date.today(),
          OwnerId = event.WhoId,
          WhatId = event.Acuity_Appointment__c
        )
      );
    }

    if (!tasksToInsert.isEmpty())
      insert tasksToInsert;
  }
}
