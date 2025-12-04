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
}
