public with sharing class NsLineItemService {
  public static void onAfterInsert(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    System.debug('Items created: ' + lineItems);
  }

  public static void onAfterUpdate(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    System.debug('Items updated: ' + lineItems);
  }

  public static void onAfterDelete(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    System.debug('Items deleted: ' + lineItems);
  }
}
