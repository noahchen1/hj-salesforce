trigger NcoMessageHistoryTrigger on nco_message_history__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        new MessHistoryTaskTriggerHandler().createTaskOnInsert(Trigger.new);
    }

}