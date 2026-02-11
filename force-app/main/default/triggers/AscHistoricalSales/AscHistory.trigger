trigger AscHistory on nco_aschistoricalsales__c(
  after insert,
  after update,
  after delete
) {
  if (Trigger.isInsert) {
    AscHistoryService.onAfterInsert(Trigger.new);
  } else if (Trigger.isUpdate) {
    AscHistoryService.onAfterUpdate(Trigger.new, Trigger.oldMap);
  } else if (Trigger.isDelete) {
    AscHistoryService.onAfterDelete(Trigger.old);
  }
}
