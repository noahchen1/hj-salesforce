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
  }

  @AuraEnabled(cacheable=true)
  public static List<LookupResult> searchRepairStation(String input) {
    List<LookupResult> stations = new List<LookupResult>();
    Integer rownum = 1;

    for (AggregateResult ar : [
      SELECT ncf_body_repair_station__c station
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE ncf_body_repair_station__c LIKE :'%' + input + '%'
      GROUP BY ncf_body_repair_station__c
    ]) {
      stations.add(
        new LookupResult(String.valueOf(rownum), (String) ar.get('station'))
      );

      rowNum++;
    }

    return stations;
  }
}
