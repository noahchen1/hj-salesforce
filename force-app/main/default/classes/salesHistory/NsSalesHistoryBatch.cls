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
      'breadwinner_ns__ParentTransDate__c, ' +
      'breadwinner_ns__LocationName__c,  ' +
      'breadwinner_ns__Item__r.ncf_item9__c, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__VendorName__c ' +
      'FROM breadwinner_ns__BW_Line_Item__c ' +
      'WHERE breadwinner_ns__Transaction_Type__c IN (\'Invoice\', \'CashSale\', \'CashRefund\', \'CreditMemo\') ' +
      'ORDER BY breadwinner_ns__ParentTransDate__c DESC';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<breadwinner_ns__BW_Line_Item__c> scope
  ) {
    if (scope.isEmpty())
      return;

    Set<String> sourceIds = new Set<String>();
    for (breadwinner_ns__BW_Line_Item__c line : scope) {
      sourceIds.add(String.valueOf(line.Id));
    }

    Map<String, Sales_History__c> existingBySourceId = new Map<String, Sales_History__c>();
    for (Sales_History__c sh : [
      SELECT
        Id,
        Name,
        Sales_Rep_1__c,
        Sales_Rep_2__c,
        Account__c,
        Price_Paid__c,
        Item__c,
        Item_Name__c,
        Cost__c,
        Division__c,
        Department__c,
        Group_Code__c,
        Retail__c,
        Source__c,
        Order_Date__c,
        Source_Id__c,
        Location__c,
        Vendor__c,
        Vendor_Item_Number__c,
        NetSuite_Line_Item__c,
        ASC_Historical_Sales__c
      FROM Sales_History__c
      WHERE Source__c = 'NS' AND Source_Id__c IN :sourceIds
    ]) {
      existingBySourceId.put(sh.Source_Id__c, sh);
    }

    List<Sales_History__c> toInsert = new List<Sales_History__c>();
    List<Sales_History__c> toUpdate = new List<Sales_History__c>();

    for (breadwinner_ns__BW_Line_Item__c line : scope) {
      String sourceId = String.valueOf(line.Id);

      String parentNumber = Helpers.getFirstNonEmptyString(
        new List<String>{
          line.breadwinner_ns__Invoice__r?.Name,
          line.breadwinner_ns__Credit_Memo__r?.Name
        }
      );

      String name = parentNumber + '_' + line.Name;

      Map<String, Object> fieldMap = new Map<String, Object>{
        'Name' => name,
        'Sales_Rep_1__c' => line.breadwinner_ns__Invoice__r
          ?.breadwinner_ns__SalesRepName__c ??
          line.breadwinner_ns__Credit_Memo__r?.breadwinner_ns__SalesRepName__c,
        'Sales_Rep_2__c' => line.breadwinner_ns__Invoice__r
          ?.ncf_body_salesrep2__c ??
          line.breadwinner_ns__Credit_Memo__r?.ncf_body_salesrep2__c,
        'Account__c' => line.breadwinner_ns__ParentSalesforceAccount__c,
        'Price_Paid__c' => line.Amount_after_Discounts__c ??
          line.breadwinner_ns__Amount__c,
        'Item__c' => line.breadwinner_ns__Item__c,
        'Item_Name__c' => line.breadwinner_ns__Item__r.Name,
        'Cost__c' => line.breadwinner_ns__Item__r?.breadwinner_ns__Cost__c,
        'Division__c' => line.breadwinner_ns__ClassName__c ??
          line.breadwinner_ns__Item__r?.breadwinner_ns__ClassName__c,
        'Department__c' => line.Item_Merchandise_Department__c ??
          line.breadwinner_ns__Item__r?.ncf_item_psgss_merc_dept__c,
        'Group_Code__c' => line.Item_Group_Code__c ??
          line.breadwinner_ns__Item__r?.ncf_item_groupcode__c,
        'Retail__c' => line.breadwinner_ns__Item__r?.Base_Price__c,
        'Source__c' => 'NS',
        'Order_Date__c' => line.breadwinner_ns__ParentTransDate__c,
        'Source_Id__c' => sourceId,
        'Location__c' => line.breadwinner_ns__LocationName__c,
        'Vendor__c' => line.breadwinner_ns__Item__r.ncf_item9__c,
        'Vendor_Item_Number__c' => line.breadwinner_ns__Item__r.breadwinner_ns__VendorName__c,
        'NetSuite_Line_Item__c' => sourceId
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

          if (newVal != oldVal) {
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
      Helpers.writeLog('Insert Results', JSON.serialize(results));
    }
    if (!toUpdate.isEmpty()) {
      Database.SaveResult[] results = Database.update(toUpdate, false);
      Helpers.writeLog('Update Results', JSON.serialize(results));
    }
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('Sync finished!');
  }
}
