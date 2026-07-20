public with sharing class NetSuiteItemImageLoaderBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {

    public void execute(SchedulableContext context) {
        Database.executeBatch(new NetSuiteItemImageLoaderBatch(), 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT 
                Name,
                imageId__c,
                ncf_item_web_image1_link__c,
                ncf_item_show_image_link__c
            FROM breadwinner_ns__BW_Item__c 
            WHERE imageId__c = NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<breadwinner_ns__BW_Item__c> netSuiteItems) {
        Set<Id> filteredNetSuiteItemsIds = new Set<Id>();
        for (breadwinner_ns__BW_Item__c netSuiteItem : netSuiteItems) {
            if (isImageUrlExist(netSuiteItem)) {
                filteredNetSuiteItemsIds.add(netSuiteItem.Id);
            }
        }
        NetSuiteItemImageLoader.getInstance().loadImage(filteredNetSuiteItemsIds);
    }

    private Boolean isImageUrlExist(breadwinner_ns__BW_Item__c netSuiteItem) {
        return 
            String.isNotBlank(netSuiteItem.ncf_item_web_image1_link__c) || 
            String.isNotBlank(netSuiteItem.ncf_item_show_image_link__c);
    }

    public void finish(Database.BatchableContext bc) {
    }

}