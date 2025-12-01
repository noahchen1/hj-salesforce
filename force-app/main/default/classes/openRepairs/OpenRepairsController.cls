public with sharing class OpenRepairsController {
  @AuraEnabled(cacheable=true)
  public static List<breadwinner_ns__BW_Sales_Order__c> getOpenRepairs(
    String name,
    String station,
    Integer limitSize,
    Integer offsetSize
  ) {
    try {
      String query =
        'SELECT Id, breadwinner_ns__CreatedDate__c, Name, breadwinner_ns__Entity__r.Name, breadwinner_ns__Total__c, ' +
        'ncf_body_repair_station__c, ncf_body1__c, Days_Open__c, breadwinner_ns__Status__c ' +
        'FROM breadwinner_ns__BW_Sales_Order__c WHERE ncf_body_repair_order__c = TRUE';

      if (String.isNotBlank(name)) {
        query += ' AND breadwinner_ns__Entity__r.Name = :name';
      }
      if (String.isNotBlank(station)) {
        query += ' AND ncf_body_repair_station__c = :station';
      }
      query += ' LIMIT :limitSize OFFSET :offsetSize';

      return Database.query(query);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<String> getAccountNames() {
    List<String> names = new List<String>();
    for (breadwinner_ns__BW_Sales_Order__c so : [
      SELECT breadwinner_ns__Entity__r.Name
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE
        ncf_body_repair_order__c = TRUE
        AND breadwinner_ns__Entity__r.Name != NULL
    ]) {
      String name = so.breadwinner_ns__Entity__r.Name;

      if (!names.contains(name))
        names.add(name);
    }

    return names;
  }

  @AuraEnabled(cacheable=true)
  public static List<breadwinner_ns__BW_Company__c> searchCustomer(
    String input
  ) {
    return [
      SELECT Id, Name
      FROM breadwinner_ns__BW_Company__c
      WHERE Name LIKE :'%' + input + '%'
      LIMIT 10
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<String> getStations() {
    List<String> stations = new List<String>();

    for (AggregateResult ar : [
      SELECT ncf_body_repair_station__c station
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE ncf_body_repair_order__c = TRUE
      GROUP BY ncf_body_repair_station__c
      ORDER BY ncf_body_repair_station__c
    ]) {
      stations.add((string) ar.get('station'));
    }

    return stations;
  }
}
