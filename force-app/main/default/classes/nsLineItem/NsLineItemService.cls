public with sharing class NsLineItemService {
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
  }

  public static void onAfterInsert(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    Script_Log__c newLog = new Script_Log__c(
      Title__c = 'Items created',
      Details__c = JSON.serialize(lineItems),
      Timestamp__c = Datetime.now()
    );
    insert newLog;
  }

  public static void onAfterUpdate(
    List<breadwinner_ns__BW_Line_Item__c> lineItems,
    Map<Id, breadwinner_ns__BW_Line_Item__c> oldMap
  ) {
    List<breadwinner_ns__BW_Line_Item__c> changed = new List<breadwinner_ns__BW_Line_Item__c>();

    Set<String> IGNORED = new Set<String>{
      'Id',
      'CreatedDate',
      'CreatedById',
      'LastModifiedDate',
      'LastModifiedById',
      'SystemModstamp'
    };

    for (breadwinner_ns__BW_Line_Item__c line : lineItems) {
      breadwinner_ns__BW_Line_Item__c oldLine = oldMap.get(line.Id);

      if (oldLine == null)
        continue;

      String type = line.breadwinner_ns__Transaction_Type__c;

      if (!isValidTransactionType(type))
        continue;

      Map<String, Schema.SObjectField> fieldsMap = line.getSObjectType()
        .getDescribe()
        .fields.getMap();

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

        if (different)
          changed.add(line);
      }
    }

    for (breadwinner_ns__BW_Line_Item__c line : changed) {
      Id lineId = line.Id;

      Sales_History__c matchingHistory = [
        SELECT Name
        FROM Sales_History__c
        WHERE Source_Id__c = :lineId
      ];

      if (matchingHistory != null) {
        List<String> parentNumbers = new List<String>{
          line.breadwinner_ns__Invoice__c,
          line.breadwinner_ns__Credit_Memo__c
        };

        String name =
          Helpers.getFirstNonEmptyString(parentNumbers) +
          '_' +
          line.Name;

        Helpers.writeLog('name', name);
      } else {
      }
    }

    Script_Log__c newLog = new Script_Log__c(
      Title__c = 'Items updated',
      Details__c = JSON.serialize(changed),
      Timestamp__c = Datetime.now()
    );

    insert newLog;
  }

  public static void onAfterDelete(
    List<breadwinner_ns__BW_Line_Item__c> lineItems
  ) {
    Script_Log__c newLog = new Script_Log__c(
      Title__c = 'Items deleted',
      Details__c = JSON.serialize(lineItems),
      Timestamp__c = Datetime.now()
    );
    insert newLog;
  }
}
