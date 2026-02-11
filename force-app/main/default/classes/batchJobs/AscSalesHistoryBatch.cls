public with sharing class AscSalesHistoryBatch implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String query =
      'SELECT ' +
      'Id, ' +
      'Name, ' +
      'custrecord_aschassociate1__c, ' +
      'custrecord_aschassociate2__c, ' +
      'Account__c, ' +
      'custrecord_aschitempricepaid__c, ' +
      'NetSuite_Item__c, ' +
      'custrecord_aschsku__c, ' +
      'custrecord_aschtitemcost__c, ' +
      'custrecord_aschitemdivision__c, ' +
      'custrecord_aschitemdepartment__c, ' +
      'custrecord_aschitemgroupcode__c, ' +
      'custrecord_aschitemretail__c, ' +
      'custrecord_aschorderdate__c, ' +
      'custrecord_aschvendor__c, ' +
      'custrecord_aschvendoritemnum__c, ' +
      'custrecord_aschitemqty__c, ' +
      'custrecord_aschstore__c ' +
      'FROM nco_aschistoricalsales__c ' +
      'ORDER BY custrecord_aschorderdate__c DESC';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<nco_aschistoricalsales__c> scope
  ) {
    if (scope == null || scope.isEmpty())
      return;

    Map<String, List<Sales_History__c>> updateMap = UpdateSalesHistory.getUpdatesFromAscHistory(
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

    List<Sales_History__c> toDelete = updateMap.get('toDelete') != null
      ? updateMap.get('toDelete')
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
              'ASC Sales History - Insert Error',
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
              'ASC Sales History - Update Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }

    if (!toDelete.isEmpty()) {
      Database.DeleteResult[] results = Database.delete(toDelete, false);

      for (Database.DeleteResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'ASC Sales History - Delete Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('ASC Sync finished!');
  }
}
