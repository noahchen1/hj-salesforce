trigger NsLineItem on breadwinner_ns__BW_Line_Item__c(
  after insert,
  after update,
  after delete
) {
  if (Trigger.isInsert) {
    NsLineItemService.onAfterInsert(Trigger.new);
  } else if (Trigger.isUpdate) {
    NsLineItemService.onAfterUpdate(Trigger.new);
  } else if (Trigger.isDelete) {
    NsLineItemService.onAfterDelete(Trigger.old);
  }
}
