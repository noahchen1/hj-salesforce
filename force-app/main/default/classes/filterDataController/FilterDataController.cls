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
  public static List<LookupResult> searchLocation(String input) {
    List<LookupResult> locations = new List<LookupResult>();
    try {
      for (AggregateResult ar : [
        SELECT breadwinner_ns__LocationName__c locationName
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE breadwinner_ns__LocationName__c LIKE :'%' + input + '%'
        GROUP BY breadwinner_ns__LocationName__c
      ]) {
        String locationName = (String) ar.get('locationName');
        locations.add(new LookupResult(locationName, locationName));
      }

      return locations;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
