public with sharing class FilterDataController {
  public class LookupResult {
    @AuraEnabled
    public String Id;
    @AuraEnabled
    public String Name;
    public LookupResult(String id, String name) {
      this.Id = id;
      this.Name = name;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchCustomer(String input) {
    List<LookupResult> results = new List<LookupResult>();
    try {
      for (breadwinner_ns__BW_Company__c c : [
        SELECT Id, Name
        FROM breadwinner_ns__BW_Company__c
        WHERE Name LIKE :'%' + input + '%'
        ORDER BY Name
        LIMIT 10
      ]) {
        results.add(new LookupResult(c.Id, c.Name));
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
    Set<String> repNames = new Set<String>();
    List<LookupResult> reps = new List<LookupResult>();
    try {
      for (AggregateResult ar : [
        SELECT breadwinner_ns__SalesRepName__c rep
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE breadwinner_ns__SalesRepName__c LIKE :'%' + input + '%'
        GROUP BY breadwinner_ns__SalesRepName__c
      ]) {
        String repName = (String) ar.get('rep');
        if (repName != null && !repNames.contains(repName)) {
          repNames.add(repName);
        }
      }

      for (AggregateResult ar : [
        SELECT ncf_body_salesrep2__c rep
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE ncf_body_salesrep2__c LIKE :'%' + input + '%'
        GROUP BY ncf_body_salesrep2__c
      ]) {
        String repName = (String) ar.get('rep');
        if (repName != null && !repNames.contains(repName)) {
          repNames.add(repName);
        }
      }

      for (String repName : repNames) {
        reps.add(new LookupResult(repName, repName));
      }

      return reps;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchVendor(String input) {
    List<LookupResult> vendors = new List<LookupResult>();
    try {
      for (breadwinner_ns__BW_Company__c vendor : [
        SELECT Name
        FROM breadwinner_ns__BW_Company__c
        WHERE
          breadwinner_ns__Entity_Type__c = 'Vendor'
          AND Name LIKE :'%' + input + '%'
      ]) {
        vendors.add(new LookupResult(vendor.Name, vendor.Name));
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
          SELECT breadwinner_ns__VendorName__c
          FROM breadwinner_ns__BW_Item__c
          WHERE
            breadwinner_ns__VendorName__c != NULL
            AND breadwinner_ns__VendorName__c LIKE :input + '%'
          ORDER BY breadwinner_ns__VendorName__c
          LIMIT :batchSize
        ];
      } else {
        batch = [
          SELECT breadwinner_ns__VendorName__c
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
        vendorNumSet.add(item.breadwinner_ns__VendorName__c);
      }

      if (batch.size() == batchSize) {
        lastName = batch[batch.size() - 1].breadwinner_ns__VendorName__c;
      } else {
        moreRecords = false;
      }
    }

    for (String vendorNum : vendorNumSet) {
      vendorNums.add(new LookupResult(vendorNum, vendorNum));
    }

    return vendorNums;
  }
}
