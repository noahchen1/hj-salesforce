public with sharing class UpdateSalesHistory {
  public static Boolean isValidTransactionType(String type) {
    if (String.isBlank(type))
      return false;

    if (
      type == BW_TransactionType.Invoice.name() ||
      type == BW_TransactionType.CashSale.name() ||
      type == BW_TransactionType.CashRefund.name() ||
      type == BW_TransactionType.CreditMemo.name()
    ) {
      return true;
    }

    return false;
  }

  public static Map<String, List<Sales_History__c>> getUpdatesFromNsLineItems(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    if (lineItems == null || lineItems.isEmpty()) {
      return new Map<String, List<Sales_History__c>>{
        'toInsert' => new List<Sales_History__c>(),
        'toUpdate' => new List<Sales_History__c>()
      };
    }

    Set<String> sourceIds = new Set<String>();

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      if (!isValidTransactionType(line.breadwinner_ns__Transaction_Type__c))
        continue;

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

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      if (!isValidTransactionType(line.breadwinner_ns__Transaction_Type__c))
        continue;

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

    return new Map<String, List<Sales_History__c>>{
      'toInsert' => toInsert,
      'toUpdate' => toUpdate
    };
  }

  public static Map<String, List<Sales_History__c>> getUpdatesFromAscHistory(
    List<nco_aschistoricalsales__c> lineItems
  ) {
    if (lineItems == null || lineItems.isEmpty()) {
      return new Map<String, List<Sales_History__c>>{
        'toInsert' => new List<Sales_History__c>(),
        'toUpdate' => new List<Sales_History__c>()
      };
    }

    Set<String> sourceIds = new Set<String>();
    for (nco_aschistoricalsales__c line : lineItems) {
      sourceIds.add(String.valueOf(line.Id));
    }

    Map<String, Sales_History__c> existingBySourceId = new Map<String, Sales_History__c>();
    for (Sales_History__c history : [
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
      WHERE Source__c = 'ASC' AND Source_Id__c IN :sourceIds
    ]) {
      existingBySourceId.put(history.Source_Id__c, history);
    }

    List<Sales_History__c> toInsert = new List<Sales_History__c>();
    List<Sales_History__c> toUpdate = new List<Sales_History__c>();

    for (nco_aschistoricalsales__c line : lineItems) {
      String sourceId = String.valueOf(line.Id);

      Map<String, Object> fieldMap = new Map<String, Object>{
        'Name' => line.Name,
        'Sales_Rep_1__c' => line.custrecord_aschassociate1__c,
        'Sales_Rep_2__c' => line.custrecord_aschassociate2__c,
        'Account__c' => line.Account__c,
        'Price_Paid__c' => line.custrecord_aschitempricepaid__c,
        'Item__c' => line.NetSuite_Item__c,
        'Item_Name__c' => line.custrecord_aschsku__c,
        'Cost__c' => line.custrecord_aschtitemcost__c,
        'Division__c' => line.custrecord_aschitemdivision__c,
        'Department__c' => line.custrecord_aschitemdepartment__c,
        'Group_Code__c' => line.custrecord_aschitemgroupcode__c,
        'Retail__c' => line.custrecord_aschitemretail__c,
        'Source__c' => 'ASC',
        'Order_Date__c' => line.custrecord_aschorderdate__c,
        'Source_Id__c' => sourceId,
        'Location__c' => line.custrecord_aschstore__c,
        'Vendor__c' => line.custrecord_aschvendor__c,
        'Vendor_Item_Number__c' => line.custrecord_aschvendoritemnum__c,
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

          if (oldVal != newVal) {
            existing.put(fieldName, newVal);
            changed = true;
          }
        }

        if (changed) {
          toUpdate.add(existing);
        }
      }
    }

    return new Map<String, List<Sales_History__c>>{
      'toInsert' => toInsert,
      'toUpdate' => toUpdate
    };
  }
}
