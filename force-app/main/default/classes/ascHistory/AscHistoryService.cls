public with sharing class AscHistoryService {
  private static List<nco_aschistoricalsales__c> getLines(Set<Id> lineIds) {
    return [
      SELECT
        Id,
        Name,
        custrecord_aschassociate1__c,
        custrecord_aschassociate2__c,
        Account__c,
        custrecord_aschitempricepaid__c,
        NetSuite_Item__c,
        custrecord_aschsku__c,
        custrecord_aschtitemcost__c,
        custrecord_aschitemdivision__c,
        custrecord_aschitemdepartment__c,
        custrecord_aschitemgroupcode__c,
        custrecord_aschitemretail__c,
        custrecord_aschorderdate__c,
        custrecord_aschvendor__c,
        custrecord_aschvendoritemnum__c,
        custrecord_aschitemqty__c,
        custrecord_aschstore__c
      FROM nco_aschistoricalsales__c
      WHERE Id IN :lineIds
      ORDER BY custrecord_aschorderdate__c DESC
    ];
  }
  public static void onAfterInsert(List<nco_aschistoricalsales__c> lineItems) {
    if (lineItems == null || lineItems.isEmpty())
      return;

    Set<Id> newLineIds = new Set<Id>();

    for (nco_aschistoricalsales__c line : lineItems) {
      newLineIds.add(line.Id);
    }

    List<nco_aschistoricalsales__c> newLines = getLines(newLineIds);

    Map<String, List<Sales_History__c>> updateMap = UpdateSalesHistory.getUpdatesFromAscHistory(
      newLines
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

      Helpers.writeLog(
        'ASC Sales History - Trigger Insert Results',
        JSON.serialize(results)
      );
    }

    if (!toUpdate.isEmpty()) {
      Database.SaveResult[] results = Database.update(toUpdate, false);

      Helpers.writeLog(
        'ASC Sales History - Trigger Update Results',
        JSON.serialize(results)
      );
    }
  }

  public static void onAfterUpdate(
    List<nco_aschistoricalsales__c> lineItems,
    Map<Id, nco_aschistoricalsales__c> oldMap
  ) {
    Set<Id> changedIds = new Set<Id>();
    Set<String> IGNORED = new Set<String>{
      'Id',
      'CreatedDate',
      'CreatedById',
      'LastModifiedDate',
      'LastModifiedById',
      'SystemModstamp'
    };

    Map<String, Schema.SObjectField> fieldsMap = nco_aschistoricalsales__c.SObjectType
      .getDescribe()
      .fields.getMap();

    for (nco_aschistoricalsales__c line : lineItems) {
      nco_aschistoricalsales__c oldLine = oldMap.get(line.Id);

      if (oldLine == null)
        continue;

      for (String fieldName : fieldsMap.keySet()) {
        if (IGNORED.contains(fieldName))
          continue;

        Object newVal = line.get(fieldName);
        Object oldVal = oldLine.get(fieldName);

        Boolean different = false;

        if (newVal == oldVal) {
          different = false;
        } else if (newVal == null || oldVal == null) {
          different = true;
        } else {
          if (!String.valueOf(newVal).equals(String.valueOf(oldVal)))
            different = true;
        }

        if (different) {
          changedIds.add(line.Id);

          break;
        }
      }
    }

    if (changedIds.isEmpty())
      return;

    List<nco_aschistoricalsales__c> changedLines = getLines(changedIds);

    Map<String, List<Sales_History__c>> updateMap = UpdateSalesHistory.getUpdatesFromAscHistory(
      changedLines
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

      Helpers.writeLog(
        'ASC Sales History - Trigger Insert Results',
        JSON.serialize(results)
      );
    }

    if (!toUpdate.isEmpty()) {
      Database.SaveResult[] results = Database.update(toUpdate, false);

      Helpers.writeLog(
        'ASC Sales History - Trigger Update Results',
        JSON.serialize(results)
      );
    }
  }

  public static void onAfterDelete(List<nco_aschistoricalsales__c> lineItems) {
    if (lineItems == null || lineItems.isEmpty())
      return;

    Set<String> deletedSourceIds = new Set<String>();

    for (nco_aschistoricalsales__c line : lineItems) {
      deletedSourceIds.add(String.valueOf(line.Id));
    }

    if (deletedSourceIds.isEmpty())
      return;

    List<Sales_History__c> existingHistory = new List<Sales_History__c>();

    for (String Id : deletedSourceIds) {
      String pattern = Id + '%';

      existingHistory.addAll(
        [
          SELECT Id
          FROM Sales_History__c
          WHERE Source__c = 'NS' AND Source_Id__c LIKE :pattern
        ]
      );
    }

    if (!existingHistory.isEmpty()) {
      Database.DeleteResult[] results = Database.delete(existingHistory, false);

      Helpers.writeLog(
        'ASC Sales History - Delete Results',
        JSON.serialize(results)
      );
    }
  }
}
