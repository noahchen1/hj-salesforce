public with sharing class NetSuiteItemImageTriggerHandler {
  public void loadImageOnAfterInsert(List<breadwinner_ns__BW_Item__c> items) {
    List<NetSuiteItemImageEvent__e> events = new List<NetSuiteItemImageEvent__e>();

    for (breadwinner_ns__BW_Item__c item : items) {
      if (isImageLinkNotEmpty(item)) {
        events.add(new NetSuiteItemImageEvent__e(NetSuiteItemId__c = item.Id));
      }
    }
    EventBus.publish(events);
  }

  public void loadImageOnAfterUpdate(
    List<breadwinner_ns__BW_Item__c> items,
    Map<Id, breadwinner_ns__BW_Item__c> oldItems
  ) {
    List<NetSuiteItemImageEvent__e> events = new List<NetSuiteItemImageEvent__e>();

    for (breadwinner_ns__BW_Item__c item : items) {
      if (isImageLinkChanged(item, oldItems)) {
        events.add(new NetSuiteItemImageEvent__e(NetSuiteItemId__c = item.Id));
      }
    }
    EventBus.publish(events);
  }

  @TestVisible
  private Boolean isImageLinkChanged(
    breadwinner_ns__BW_Item__c item,
    Map<Id, breadwinner_ns__BW_Item__c> oldItems
  ) {
    breadwinner_ns__BW_Item__c oldItem = oldItems.get(item.Id);

    return isFirstImageLinkChanged(item, oldItem) ||
      isSecondImageLinkChanged(item, oldItem);
  }

  private Boolean isImageLinkNotEmpty(breadwinner_ns__BW_Item__c item) {
    return String.isNotBlank(item.ncf_item_web_image1_link__c) ||
      String.isNotBlank(item.ncf_item_show_image_link__c);
  }

  private Boolean isFirstImageLinkChanged(
    breadwinner_ns__BW_Item__c item,
    breadwinner_ns__BW_Item__c oldItem
  ) {
    return item.ncf_item_web_image1_link__c !=
      oldItem.ncf_item_web_image1_link__c &&
      String.isNotBlank(item.ncf_item_web_image1_link__c);
  }

  private Boolean isSecondImageLinkChanged(
    breadwinner_ns__BW_Item__c item,
    breadwinner_ns__BW_Item__c oldItem
  ) {
    return item.ncf_item_show_image_link__c !=
      oldItem.ncf_item_show_image_link__c &&
      String.isNotBlank(item.ncf_item_show_image_link__c);
  }
}
