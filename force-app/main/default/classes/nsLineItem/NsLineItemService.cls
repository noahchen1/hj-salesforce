public with sharing class NsLineItemService {
  public static List<breadwinner_ns__BW_Line_Item__c> getLines(
    Set<Id> lineIds
  ) {
    return [
      SELECT
        Id,
        Name,
        breadwinner_ns__Invoice__r.Name,
        breadwinner_ns__Credit_Memo__r.Name,
        breadwinner_ns__Invoice__r.breadwinner_ns__SalesRepName__c,
        breadwinner_ns__Credit_Memo__r.breadwinner_ns__SalesRepName__c,
        breadwinner_ns__Invoice__r.ncf_body_salesrep2__c,
        breadwinner_ns__Credit_Memo__r.ncf_body_salesrep2__c,
        breadwinner_ns__Invoice__r.breadwinner_ns__Entity__c,
        breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__c,
        breadwinner_ns__ParentSalesforceAccount__c,
        breadwinner_ns__Amount__c,
        Amount_after_Discounts__c,
        breadwinner_ns__Item__c,
        breadwinner_ns__Item__r.Name,
        breadwinner_ns__Item__r.breadwinner_ns__Cost__c,
        breadwinner_ns__ClassName__c,
        breadwinner_ns__Item__r.breadwinner_ns__ClassName__c,
        Item_Merchandise_Department__c,
        breadwinner_ns__Item__r.ncf_item_psgss_merc_dept__c,
        Item_Group_Code__c,
        breadwinner_ns__Item__r.ncf_item_groupcode__c,
        breadwinner_ns__Item__r.Base_Price__c,
        breadwinner_ns__CostEstimate__c,
        breadwinner_ns__Quantity__c,
        breadwinner_ns__ParentTransDate__c,
        breadwinner_ns__LocationName__c,
        breadwinner_ns__Item__r.ncf_item9__c,
        breadwinner_ns__Item__r.breadwinner_ns__VendorName__c,
        breadwinner_ns__Transaction_Type__c
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE
        breadwinner_ns__Transaction_Type__c IN (
          'Invoice',
          'CashSale',
          'CashRefund',
          'CreditMemo'
        )
        AND Id IN :lineIds
    ];
  }

  public static void onAfterInsert(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    if (lineItems == null || lineItems.isEmpty())
      return;

    Set<Id> newLineIds = new Set<Id>();

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      newLineIds.add(line.Id);
    }

    List<breadwinner_ns__BW_Line_Item__c> newLines = getLines(newLineIds);

    Map<String, List<Sales_History__c>> updateMap = UpdateSalesHistory.getUpdatesFromNsLineItems(
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

      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'NS Sales History - On After Insert: Trigger Insert Error',
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
              'NS Sales History - On After Insert: Trigger Update Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }
  }

  public static void onAfterUpdate(
    List<breadwinner_ns__BW_Line_Item__c> lineItems,
    Map<Id, breadwinner_ns__BW_Line_Item__c> oldMap
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

    Map<String, Schema.SObjectField> fieldsMap = breadwinner_ns__BW_Line_Item__c.SObjectType
      .getDescribe()
      .fields.getMap();

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      breadwinner_ns__BW_Line_Item__c oldLine = oldMap.get(line.Id);

      if (oldLine == null)
        continue;

      if (
        !UpdateSalesHistory.isValidTransactionType(
          line.breadwinner_ns__Transaction_Type__c
        )
      )
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

    List<breadwinner_ns__BW_Line_Item__c> changedLines = getLines(changedIds);

    Map<String, List<Sales_History__c>> updateMap = UpdateSalesHistory.getUpdatesFromNsLineItems(
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

      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'NS Sales History - On After Update: Trigger Insert Error',
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
              'NS Sales History - On After Update: Trigger Update Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }
  }

  public static void onAfterDelete(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    if (lineItems == null || lineItems.isEmpty())
      return;

    Set<String> deletedSourceIds = new Set<String>();
    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
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

      for (Database.DeleteResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'NS Sales History - On After Delete: Trigger Delete Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }
  }
}
