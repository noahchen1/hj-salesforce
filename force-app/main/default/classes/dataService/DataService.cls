public with sharing class DataService {
  @AuraEnabled(cacheable=true)
  public static Boolean checkOnHand(
    String itemName,
    String nsLocationId,
    Decimal qtyRequested
  ) {
    try {
      List<breadwinner_ns__BW_Inventory_Location__c> inventoryLocations = [
        SELECT breadwinner_ns__QuantityAvailable__c
        FROM breadwinner_ns__BW_Inventory_Location__c
        WHERE
          breadwinner_ns__Item__r.Name = :itemName
          AND breadwinner_ns__Location__r.breadwinner_ns__InternalId__c = :nsLocationId
        LIMIT 1
      ];

      if (inventoryLocations.isEmpty()) {
        return false;
      }

      Decimal quantityAvailable = inventoryLocations[0]
        .breadwinner_ns__QuantityAvailable__c;

      return quantityAvailable != null && quantityAvailable >= qtyRequested;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'DataService.checkOnHand failed: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Unable to verify on-hand inventory at this time.'
      );
    }
  }
}
