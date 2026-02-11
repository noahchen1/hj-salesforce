public with sharing class NsSalesHistoryBatch implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String query =
      'SELECT ' +
      'Id, ' +
      'Name, ' +
      'breadwinner_ns__Invoice__r.Name, ' +
      'breadwinner_ns__Credit_Memo__r.Name, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__SalesRepName__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__SalesRepName__c, ' +
      'breadwinner_ns__Invoice__r.ncf_body_salesrep2__c, ' +
      'breadwinner_ns__Credit_Memo__r.ncf_body_salesrep2__c, ' +
      'breadwinner_ns__ParentSalesforceAccount__c, ' +
      'breadwinner_ns__Amount__c, ' +
      'Amount_after_Discounts__c, ' +
      'breadwinner_ns__Item__c, ' +
      'breadwinner_ns__Item__r.Name, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__Cost__c, ' +
      'breadwinner_ns__ClassName__c, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__ClassName__c, ' +
      'Item_Merchandise_Department__c, ' +
      'breadwinner_ns__Item__r.ncf_item_psgss_merc_dept__c, ' +
      'Item_Group_Code__c, ' +
      'breadwinner_ns__Item__r.ncf_item_groupcode__c, ' +
      'breadwinner_ns__Item__r.Base_Price__c, ' +
      'breadwinner_ns__CostEstimate__c, ' +
      'breadwinner_ns__Quantity__c, ' +
      'breadwinner_ns__ParentTransDate__c, ' +
      'breadwinner_ns__LocationName__c,  ' +
      'breadwinner_ns__Item__r.ncf_item9__c, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__VendorName__c, ' +
      'breadwinner_ns__Transaction_Type__c ' +
      'FROM breadwinner_ns__BW_Line_Item__c ' +
      'WHERE breadwinner_ns__Transaction_Type__c IN (\'Invoice\', \'CashSale\', \'CashRefund\', \'CreditMemo\') ' +
      'ORDER BY breadwinner_ns__ParentTransDate__c DESC';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<breadwinner_ns__BW_Line_Item__c> scope
  ) {
    if (scope == null || scope.isEmpty())
      return;

    Map<String, List<Sales_History__c>> updateMap = UpdateSalesHistory.getUpdatesFromNsLineItems(
      scope
    );
    if (updateMap == null)
      return;

    List<Sales_History__c> toInsert = updateMap.get('toInsert') != null
      ? updateMap.get('toInsert')
      : new List<Sales_History__c>();
    List<Sales_History__c> toUpdate = updateMap.get('toUpdate') != null
      ? updateMap.get('toUpdate')
      : new List<Sales_History__c>();

    if (!toInsert.isEmpty()) {
      Database.SaveResult[] results = Database.insert(toInsert, false);

      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'NS Sales History - Insert Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }

    if (!toUpdate.isEmpty()) {
      Database.SaveResult[] results = Database.update(toUpdate, false);

      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'NS Sales History - Update Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('NS Sync finished!');
  }
}
