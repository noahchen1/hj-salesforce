public with sharing class UpdateSalesHistory {
  private class RepInfo {
    public Id rep1Id;
    public String rep1Name;
    public Id rep2Id;
    public String rep2Name;
    public Integer numRep;

    public RepInfo(Id r1Id, String r1Name, Id r2Id, String r2Name, Integer n) {
      this.rep1Id = r1Id;
      this.rep1Name = r1Name;
      this.rep2Id = r2Id;
      this.rep2Name = r2Name;
      this.numRep = n;
    }
  }

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

  private static RepInfo getSalesReps(breadwinner_ns__BW_Line_Item__c line) {
    String rep1Name = line.breadwinner_ns__Invoice__r
      ?.breadwinner_ns__SalesRepName__c ??
      line.breadwinner_ns__Credit_Memo__r?.breadwinner_ns__SalesRepName__c;
    String rep2Name = line.breadwinner_ns__Invoice__r?.ncf_body_salesrep2__c ??
      line.breadwinner_ns__Credit_Memo__r?.ncf_body_salesrep2__c;

    Integer numRep = 0;
    if (!String.isBlank(rep1Name))
      numRep++;
    if (!String.isBlank(rep2Name))
      numRep++;
    if (numRep < 1)
      numRep = 1;
    if (numRep > 2)
      numRep = 2;

    return new RepInfo(null, rep1Name, null, rep2Name, numRep);
  }

  private static RepInfo getSalesReps(nco_aschistoricalsales__c line) {
    String rep1Name = line.custrecord_aschassociate1__c;
    String rep2Name = line.custrecord_aschassociate2__c;

    Integer numRep = 0;
    if (!String.isBlank(rep1Name))
      numRep++;
    if (!String.isBlank(rep2Name))
      numRep++;
    if (numRep < 1)
      numRep = 1;
    if (numRep > 2)
      numRep = 2;

    return new RepInfo(null, rep1Name, null, rep2Name, numRep);
  }

  public static Map<String, List<Sales_History__c>> getUpdatesFromNsLineItems(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    if (lineItems == null || lineItems.isEmpty()) {
      return new Map<String, List<Sales_History__c>>{
        'toInsert' => new List<Sales_History__c>(),
        'toUpdate' => new List<Sales_History__c>(),
        'toDelete' => new List<Sales_History__c>()
      };
    }

    Set<String> sourceIds = new Set<String>();
    Set<Id> lineItemIds = new Set<Id>();
    Set<String> repNames = new Set<String>();
    List<Sales_History__c> toInsert = new List<Sales_History__c>();
    List<Sales_History__c> toUpdate = new List<Sales_History__c>();
    List<Sales_History__c> toDelete = new List<Sales_History__c>();

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      try {
        if (!isValidTransactionType(line.breadwinner_ns__Transaction_Type__c))
          continue;

        if (line.Id != null)
          lineItemIds.add(line.Id);

        RepInfo repInfo = getSalesReps(line);

        if (!String.isBlank(repInfo.rep1Name))
          repNames.add(repInfo.rep1Name);
        if (!String.isBlank(repInfo.rep2Name))
          repNames.add(repInfo.rep2Name);

        for (Integer repNum = 1; repNum <= repInfo.numRep; repNum++) {
          String historySourceId = String.valueOf(line.Id) + '_' + repNum;
          sourceIds.add(historySourceId);
        }
      } catch (Exception ex) {
        Helpers.writeLog(
          'NS Sales History - Error adding rep nams and source ids',
          'LineId=' +
            String.valueOf(line?.Id) +
            ' | Message=' +
            ex.getMessage() +
            ' | Stack=' +
            ex.getStackTraceString()
        );

        continue;
      }
    }

    Map<String, Sales_History__c> existingBySourceId = new Map<String, Sales_History__c>();
    if (!lineItemIds.isEmpty()) {
      for (Sales_History__c sh : [
        SELECT
          Id,
          Name,
          Sales_Rep__c,
          OwnerId,
          Account__c,
          NetSuite_Company__c,
          Price_Paid__c,
          Split__c,
          Item__c,
          Item_Name__c,
          Cost__c,
          Division__c,
          Department__c,
          Group_Code__c,
          Retail__c,
          Quantity__c,
          Source__c,
          Order_Date__c,
          Source_Id__c,
          Location__c,
          Vendor__c,
          Vendor_Item_Number__c,
          NetSuite_Line_Item__c,
          ASC_Historical_Sales__c
        FROM Sales_History__c
        WHERE Source__c = 'NS' AND NetSuite_Line_Item__c IN :lineItemIds
      ]) {
        if (sourceIds.contains(sh.Source_Id__c)) {
          existingBySourceId.put(sh.Source_Id__c, sh);
        } else {
          toDelete.add(sh);
        }
      }
    }

    Map<String, Id> userIdByName = new Map<String, Id>();
    if (!repNames.isEmpty()) {
      for (User u : [SELECT Id, Name FROM User WHERE Name IN :repNames]) {
        userIdByName.put(u.Name, u.Id);
      }
    }

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      try {
        if (!isValidTransactionType(line.breadwinner_ns__Transaction_Type__c))
          continue;

        String sourceId = String.valueOf(line.Id);

        String parentNumber = Helpers.getFirstNonEmptyString(
          new List<String>{
            line.breadwinner_ns__Invoice__r?.Name,
            line.breadwinner_ns__Credit_Memo__r?.Name
          }
        );

        String baseName = parentNumber + '_' + line.Name;
        RepInfo repInfo = getSalesReps(line);

        for (Integer repNum = 1; repNum <= repInfo.numRep; repNum++) {
          String historySourceId = String.valueOf(line.Id) + '_' + repNum;

          Id ownerId = (repNum == 1)
            ? (userIdByName.get(repInfo.rep1Name) != null
                ? userIdByName.get(repInfo.rep1Name)
                : UserInfo.getUserId())
            : (userIdByName.get(repInfo.rep2Name) != null
                ? userIdByName.get(repInfo.rep2Name)
                : UserInfo.getUserId());

          String salesRepText = (repNum == 1)
            ? (!String.isBlank(repInfo.rep1Name)
                ? repInfo.rep1Name
                : UserInfo.getName())
            : (!String.isBlank(repInfo.rep2Name)
                ? repInfo.rep2Name
                : UserInfo.getName());

          Decimal pricePaid = (line.Amount_after_Discounts__c != null)
            ? line.Amount_after_Discounts__c
            : line.breadwinner_ns__Amount__c;

          Decimal splitAmount = (repInfo.numRep > 1 &&
            pricePaid != null)
            ? pricePaid / 2
            : pricePaid;

          Decimal quantity = repInfo.numRep > 1 &&
            line.breadwinner_ns__Quantity__c != null
            ? line.breadwinner_ns__Quantity__c / 2
            : line.breadwinner_ns__Quantity__c;

          Map<String, Object> fieldMap = new Map<String, Object>{
            'Name' => baseName +
            '_REP' +
            repNum,
            'Sales_Rep__c' => salesRepText,
            'OwnerId' => ownerId,
            'Account__c' => line.breadwinner_ns__ParentSalesforceAccount__c,
            'NetSuite_Company__c' => line.breadwinner_ns__Invoice__r
              ?.breadwinner_ns__Entity__c ??
              line.breadwinner_ns__Credit_Memo__r?.breadwinner_ns__Entity__c,
            'Price_Paid__c' => pricePaid,
            'Split__c' => splitAmount,
            'Item__c' => line.breadwinner_ns__Item__c,
            'Item_Name__c' => line.breadwinner_ns__Item__r?.Name,
            'Cost__c' => line.breadwinner_ns__Item__r?.breadwinner_ns__Cost__c,
            'Division__c' => line.breadwinner_ns__ClassName__c ??
              line.breadwinner_ns__Item__r?.breadwinner_ns__ClassName__c,
            'Department__c' => line.Item_Merchandise_Department__c ??
              line.breadwinner_ns__Item__r?.ncf_item_psgss_merc_dept__c,
            'Group_Code__c' => line.Item_Group_Code__c ??
              line.breadwinner_ns__Item__r?.ncf_item_groupcode__c,
            'Retail__c' => line.breadwinner_ns__CostEstimate__c ??
              line.breadwinner_ns__Item__r?.Base_Price__c,
            'Quantity__c' => quantity,
            'Source__c' => 'NS',
            'Order_Date__c' => line.breadwinner_ns__ParentTransDate__c,
            'Source_Id__c' => historySourceId,
            'Location__c' => line.breadwinner_ns__LocationName__c,
            'Vendor__c' => line.breadwinner_ns__Item__r?.ncf_item9__c,
            'Vendor_Item_Number__c' => line.breadwinner_ns__Item__r
              ?.breadwinner_ns__VendorName__c,
            'NetSuite_Line_Item__c' => sourceId
          };

          Sales_History__c existing = existingBySourceId.get(historySourceId);

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
      } catch (Exception ex) {
        Helpers.writeLog(
          'NS Sales History - Error processing line',
          'LineId=' +
            String.valueOf(line?.Id) +
            ' | Message=' +
            ex.getMessage() +
            ' | Stack=' +
            ex.getStackTraceString()
        );
        continue;
      }
    }

    return new Map<String, List<Sales_History__c>>{
      'toInsert' => toInsert,
      'toUpdate' => toUpdate,
      'toDelete' => toDelete
    };
  }

  public static Map<String, List<Sales_History__c>> getUpdatesFromAscHistory(
    List<nco_aschistoricalsales__c> lineItems
  ) {
    if (lineItems == null || lineItems.isEmpty()) {
      return new Map<String, List<Sales_History__c>>{
        'toInsert' => new List<Sales_History__c>(),
        'toUpdate' => new List<Sales_History__c>(),
        'toDelete' => new List<Sales_History__c>()
      };
    }
    Set<String> sourceIds = new Set<String>();
    Set<Id> lineItemIds = new Set<Id>();
    Set<String> repNames = new Set<String>();
    List<Sales_History__c> toInsert = new List<Sales_History__c>();
    List<Sales_History__c> toUpdate = new List<Sales_History__c>();
    List<Sales_History__c> toDelete = new List<Sales_History__c>();

    for (nco_aschistoricalsales__c line : lineItems) {
      try {
        if (line.Id != null)
          lineItemIds.add(line.Id);

        RepInfo repInfo = getSalesReps(line);
        if (!String.isBlank(repInfo.rep1Name))
          repNames.add(repInfo.rep1Name);
        if (!String.isBlank(repInfo.rep2Name))
          repNames.add(repInfo.rep2Name);

        for (Integer repNum = 1; repNum <= repInfo.numRep; repNum++) {
          String historySourceId = String.valueOf(line.Id) + '_' + repNum;
          sourceIds.add(historySourceId);
        }
      } catch (Exception ex) {
        Helpers.writeLog(
          'ASC Sales History - Error adding rep nams and source ids',
          'LineId=' +
            String.valueOf(line?.Id) +
            ' | Message=' +
            ex.getMessage() +
            ' | Stack=' +
            ex.getStackTraceString()
        );

        continue;
      }
    }

    Map<String, Sales_History__c> existingBySourceId = new Map<String, Sales_History__c>();
    if (!lineItemIds.isEmpty()) {
      for (Sales_History__c history : [
        SELECT
          Id,
          Name,
          Sales_Rep__c,
          OwnerId,
          Account__c,
          NetSuite_Company__c,
          Price_Paid__c,
          Split__c,
          Item__c,
          Item_Name__c,
          Cost__c,
          Division__c,
          Department__c,
          Group_Code__c,
          Retail__c,
          Quantity__c,
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
        if (sourceIds.contains(history.Source_Id__c)) {
          existingBySourceId.put(history.Source_Id__c, history);
        } else {
          toDelete.add(history);
        }
      }
    }

    Map<String, Id> userIdByName = new Map<String, Id>();
    if (!repNames.isEmpty()) {
      for (User u : [SELECT Id, Name FROM User WHERE Name IN :repNames]) {
        userIdByName.put(u.Name, u.Id);
      }
    }

    for (nco_aschistoricalsales__c line : lineItems) {
      try {
        String sourceId = String.valueOf(line.Id);
        RepInfo repInfo = getSalesReps(line);

        for (Integer repNum = 1; repNum <= repInfo.numRep; repNum++) {
          String historySourceId = String.valueOf(line.Id) + '_' + repNum;

          Id ownerId = (repNum == 1)
            ? (userIdByName.get(repInfo.rep1Name) != null
                ? userIdByName.get(repInfo.rep1Name)
                : UserInfo.getUserId())
            : (userIdByName.get(repInfo.rep2Name) != null
                ? userIdByName.get(repInfo.rep2Name)
                : UserInfo.getUserId());

          String salesRepText = (repNum == 1)
            ? (!String.isBlank(repInfo.rep1Name)
                ? repInfo.rep1Name
                : UserInfo.getName())
            : (!String.isBlank(repInfo.rep2Name)
                ? repInfo.rep2Name
                : UserInfo.getName());

          Decimal pricePaid = line.custrecord_aschitempricepaid__c;
          Decimal splitAmount = (repInfo.numRep > 1 &&
            pricePaid != null)
            ? pricePaid / 2
            : pricePaid;
          Decimal quantity = repInfo.numRep > 1 &&
            line.custrecord_aschitemqty__c != null
            ? line.custrecord_aschitemqty__c / 2
            : line.custrecord_aschitemqty__c;

          Map<String, Object> fieldMap = new Map<String, Object>{
            'Name' => line.Name +
            '_REP' +
            repNum,
            'Sales_Rep__c' => salesRepText,
            'OwnerId' => ownerId,
            'Account__c' => line.Account__c,
            'NetSuite_Company__c' => line.NetSuite_Company__c,
            'Price_Paid__c' => pricePaid,
            'Split__c' => splitAmount,
            'Item__c' => line.NetSuite_Item__c,
            'Item_Name__c' => line.custrecord_aschsku__c,
            'Cost__c' => line.custrecord_aschtitemcost__c,
            'Division__c' => line.custrecord_aschitemdivision__c,
            'Department__c' => line.custrecord_aschitemdepartment__c,
            'Group_Code__c' => line.custrecord_aschitemgroupcode__c,
            'Retail__c' => line.custrecord_aschitemretail__c,
            'Quantity__c' => quantity,
            'Source__c' => 'ASC',
            'Order_Date__c' => line.custrecord_aschorderdate__c,
            'Source_Id__c' => historySourceId,
            'Location__c' => line.custrecord_aschstore__c,
            'Vendor__c' => line.custrecord_aschvendor__c,
            'Vendor_Item_Number__c' => line.custrecord_aschvendoritemnum__c,
            'ASC_Historical_Sales__c' => sourceId
          };

          Sales_History__c existing = existingBySourceId.get(historySourceId);

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
      } catch (Exception ex) {
        Helpers.writeLog(
          'ASC Sales History - Error processing line',
          'LineId=' +
            String.valueOf(line?.Id) +
            ' | Message=' +
            ex.getMessage() +
            ' | Stack=' +
            ex.getStackTraceString()
        );
        continue;
      }
    }

    return new Map<String, List<Sales_History__c>>{
      'toInsert' => toInsert,
      'toUpdate' => toUpdate,
      'toDelete' => toDelete
    };
  }
}
