public with sharing class openSpecialOrdersController {
  @AuraEnabled(cacheable=true)
  public static List<breadwinner_ns__BW_Sales_Order__c> getOpenSpecialOrders(
    Date dateFilter
  ) {
    try {
      return [
        SELECT
          Id,
          Name,
          breadwinner_ns__CreatedDate__c,
          breadwinner_ns__Entity__r.Name,
          ncf_body_special_date__c,
          breadwinner_ns__SalesRepName__c,
          ncf_body_special_statuses__c,
          ncf_body_special_comments__c
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE
          ncf_body_special_item_type__c != NULL
          AND breadwinner_ns__CreatedDate__c >= :dateFilter
        LIMIT 20
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
