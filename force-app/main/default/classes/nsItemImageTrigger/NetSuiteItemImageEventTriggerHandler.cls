public with sharing class NetSuiteItemImageEventTriggerHandler {

    private final static Integer BATCH_SIZE = 5;

    public void loadImage(List<NetSuiteItemImageEvent__e> events) {
        Set<Id> itemsIdsBatch = new Set<Id>();

        for (NetSuiteItemImageEvent__e event : events) {
            itemsIdsBatch.add(event.NetSuiteItemId__c);

            if (itemsIdsBatch.size() == BATCH_SIZE) {
                loadImageFuture(itemsIdsBatch);
                itemsIdsBatch.clear();
            }
        }

        if (!itemsIdsBatch.isEmpty()) {
            loadImageFuture(itemsIdsBatch);
        }
    }

    @future(callout=true)
    private static void loadImageFuture(Set<Id> itemIds) {
        NetSuiteItemImageLoader.getInstance().loadImage(itemIds);
    }

}