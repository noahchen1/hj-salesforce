public with sharing class OpenRepairsController {
  @AuraEnabled(cacheable=true)
  public static List<breadwinner_ns__BW_Sales_Order__c> getOpenRepairs(
    String billingStatus,
    String name
  ) {
    System.debug('OpenRepairsController called');

    try {
      return [
        SELECT
          Id,
          breadwinner_ns__CreatedDate__c,
          Name,
          breadwinner_ns__Entity__r.Name,
          breadwinner_ns__Total__c,
          ncf_body_repair_station__c,
          ncf_body1__c
        FROM breadwinner_ns__BW_Sales_Order__c
        LIMIT 10
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
