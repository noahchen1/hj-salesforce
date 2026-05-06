public with sharing class FilterDataController {
  public class LookupResult {
    @AuraEnabled
    public String Id;
    @AuraEnabled
    public String NsId;
    @AuraEnabled
    public String Name;

    public LookupResult(String id, String name) {
      this.Id = id;
      this.Name = name;
    }

    public LookupResult(String id, String name, String nsId) {
      this.Id = id;
      this.Name = name;
      this.NsId = nsId;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchCustomer(String input) {
    List<LookupResult> results = new List<LookupResult>();
    try {
      for (breadwinner_ns__BW_Company__c c : [
        SELECT Id, Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Company__c
        WHERE Name LIKE :'%' + input + '%'
        ORDER BY Name
        LIMIT 10
      ]) {
        results.add(
          new LookupResult(c.Id, c.Name, c.breadwinner_ns__InternalId__c)
        );
      }
      return results;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchRepairStation(String input) {
    List<LookupResult> stations = new List<LookupResult>();
    Integer rownum = 1;
    try {
      for (AggregateResult ar : [
        SELECT ncf_body_repair_station__c station
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE ncf_body_repair_station__c LIKE :'%' + input + '%'
        GROUP BY ncf_body_repair_station__c
      ]) {
        stations.add(
          new LookupResult(String.valueOf(rownum), (String) ar.get('station'))
        );
        rownum++;
      }
      return stations;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchSalesRep(String input) {
    List<LookupResult> results = new List<LookupResult>();
    try {
      for (breadwinner_ns__BW_Employee__c c : [
        SELECT Id, Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Employee__c
        WHERE
          Name LIKE :'%' + input + '%'
          AND breadwinner_ns__IsSalesRep__c = TRUE
        ORDER BY Name
        LIMIT 10
      ]) {
        results.add(
          new LookupResult(c.Id, c.Name, c.breadwinner_ns__InternalId__c)
        );
      }
      return results;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchVendor(String input) {
    List<LookupResult> vendors = new List<LookupResult>();
    try {
      for (breadwinner_ns__BW_Company__c vendor : [
        SELECT Id, Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Company__c
        WHERE
          breadwinner_ns__Entity_Type__c = 'Vendor'
          AND Name LIKE :'%' + input + '%'
      ]) {
        vendors.add(
          new LookupResult(
            vendor.Id,
            vendor.Name,
            vendor.breadwinner_ns__InternalId__c
          )
        );
      }
      return vendors;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchVendorNum(String input) {
    Set<String> vendorNumSet = new Set<String>();
    List<LookupResult> vendorNums = new List<LookupResult>();
    Integer batchSize = 2000;
    String lastName = null;
    Boolean moreRecords = true;

    while (moreRecords) {
      List<breadwinner_ns__BW_Item__c> batch;
      if (lastName == null) {
        batch = [
          SELECT Id, breadwinner_ns__InternalId__c, breadwinner_ns__VendorName__c
          FROM breadwinner_ns__BW_Item__c
          WHERE
            breadwinner_ns__VendorName__c != NULL
            AND breadwinner_ns__VendorName__c LIKE :input + '%'
          ORDER BY breadwinner_ns__VendorName__c
          LIMIT :batchSize
        ];
      } else {
        batch = [
          SELECT Id, breadwinner_ns__InternalId__c, breadwinner_ns__VendorName__c
          FROM breadwinner_ns__BW_Item__c
          WHERE
            breadwinner_ns__VendorName__c != NULL
            AND breadwinner_ns__VendorName__c LIKE :'%' + input + '%'
            AND breadwinner_ns__VendorName__c > :lastName
          ORDER BY breadwinner_ns__VendorName__c
          LIMIT :batchSize
        ];
      }

      for (breadwinner_ns__BW_Item__c item : batch) {
        String vendorNum = item.breadwinner_ns__VendorName__c;
        if (!vendorNumSet.contains(vendorNum)) {
          vendorNumSet.add(vendorNum);
          vendorNums.add(
            new LookupResult(item.Id, vendorNum, item.breadwinner_ns__InternalId__c)
          );
        }
      }

      if (batch.size() == batchSize) {
        lastName = batch[batch.size() - 1].breadwinner_ns__VendorName__c;
      } else {
        moreRecords = false;
      }
    }

    return vendorNums;
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchItem(String input) {
    List<LookupResult> items = new List<LookupResult>();

    try {
      for (breadwinner_ns__BW_Item__c item : [
        SELECT Id, Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE Name LIKE :input + '%'
      ]) {
        items.add(
          new LookupResult(
            item.Id,
            item.Name,
            item.breadwinner_ns__InternalId__c
          )
        );
      }

      return items;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchSellableItem(String input) {
    List<LookupResult> items = new List<LookupResult>();

    try {
      for (breadwinner_ns__BW_Item__c item : [
        SELECT Id, Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE
          Name LIKE :input + '%'
          AND (ncf_item_serialized_item_type__c = FALSE
          OR (ncf_item_serialized_item_type__c = TRUE
          AND breadwinner_ns__Parent__c != NULL))
      ]) {
        items.add(
          new LookupResult(
            item.Id,
            item.Name,
            item.breadwinner_ns__InternalId__c
          )
        );
      }

      return items;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchSepcialOrderItem(String input) {
    List<LookupResult> items = new List<LookupResult>();

    try {
      for (breadwinner_ns__BW_Item__c item : [
        SELECT Id, Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE
          Name LIKE :input + '%'
          AND breadwinner_ns__InternalId__c IN (
            '213836',
            '213837',
            '213838',
            '213839',
            '213840',
            '213841',
            '213842',
            '213834'
          )
      ]) {
        items.add(
          new LookupResult(
            item.Id,
            item.Name,
            item.breadwinner_ns__InternalId__c
          )
        );
      }

      return items;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
