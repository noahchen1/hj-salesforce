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
      'custrecord_aschtitemcost__c, ' +
      'custrecord_aschitemdivision__c, ' +
      'custrecord_aschitemdepartment__c, ' +
      'custrecord_aschitemgroupcode__c, ' +
      'custrecord_aschitemretail__c, ' +
      'custrecord_aschorderdate__c ' +
      'FROM nco_aschistoricalsales__c';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<nco_aschistoricalsales__c> scope
  ) {
    if (scope.isEmpty())
      return;

    Set<String> sourceIds = new Set<String>();
    for (nco_aschistoricalsales__c line : scope) {
      sourceIds.add(String.valueOf(line.Id));
    }

    Map<String, Sales_History__c> existingBySourceId = new Map<String, Sales_History__c>();
    for (Sales_History__c history : [
      SELECT
        Id,
        Source_Id__c,
        Name,
        Sales_Rep_1__c,
        Sales_Rep_2__c,
        Account__c,
        Price_Paid__c,
        Item__c,
        Cost__c,
        Division__c,
        Department__c,
        Group_Code__c,
        Retail__c,
        Source__c,
        Order_Date__c,
        ASC_Historical_Sales__c
      FROM Sales_History__c
      WHERE Source__c = 'ASC' AND Source_Id__c IN :sourceIds
    ]) {
      existingBySourceId.put(history.Source_Id__c, history);
    }

    List<Sales_History__c> toInsert = new List<Sales_History__c>();
    List<Sales_History__c> toUpdate = new List<Sales_History__c>();

    for (nco_aschistoricalsales__c line : scope) {
      String sourceId = String.valueOf(line.Id);

      Map<String, Object> fieldMap = new Map<String, Object>{
        'Name' => line.Name,
        'Sales_Rep_1__c' => line.custrecord_aschassociate1__c,
        'Sales_Rep_2__c' => line.custrecord_aschassociate2__c,
        'Account__c' => line.Account__c,
        'Price_Paid__c' => line.custrecord_aschitempricepaid__c,
        'Item__c' => line.NetSuite_Item__c,
        'Cost__c' => line.custrecord_aschtitemcost__c,
        'Division__c' => line.custrecord_aschitemdivision__c,
        'Department__c' => line.custrecord_aschitemdepartment__c,
        'Group_Code__c' => line.custrecord_aschitemgroupcode__c,
        'Retail__c' => line.custrecord_aschitemretail__c,
        'Source__c' => 'ASC',
        'Order_Date__c' => line.custrecord_aschorderdate__c,
        'Source_Id__c' => sourceId,
        'ASC_Historical_Sales__c' => sourceId
      };

      Sales_History__c existing = existingBySourceId.get(sourceId);

      if (existing == null) {
        Sales_History__c toCreate = new Sales_History__c();
        for (String fieldName : fieldMap.keySet()) {
          toCreate.put(fieldName, fieldMap.get(fieldName));
        }
        toInsert.add(toCreate);
      } else {
        Boolean changed = false;

        for (String fieldName : fieldMap.keySet()) {
          Object newVal = fieldMap.get(fieldName);
          Object oldVal = existing.get(fieldName);

          if (!Helpers.valuesEqual(oldVal, newVal)) {
            existing.put(fieldName, newVal);
            changed = true;
          }
        }

        if (changed) {
          toUpdate.add(existing);
        }
      }
    }

    if (!toInsert.isEmpty()) {
      Database.SaveResult[] results = Database.insert(toInsert, false);
      Helpers.writeLog(
        'ASC Sales History - Insert Results',
        JSON.serialize(results)
      );
    }
    if (!toUpdate.isEmpty()) {
      Database.SaveResult[] results = Database.update(toUpdate, false);
      Helpers.writeLog(
        'ASC Sales History - Update Results',
        JSON.serialize(results)
      );
    }
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('Sync finished!');
  }
}
