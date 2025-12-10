public with sharing class DropdownDataController {
  public class Option {
    @AuraEnabled
    public String label;

    @AuraEnabled
    public String value;

    public Option(String label, String value) {
      this.label = label;
      this.value = value;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getSpecialOrderItemTypes() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT ncf_body_special_item_type__c itemType
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE ncf_body_special_item_type__c != NULL
        GROUP BY ncf_body_special_item_type__c
      ]) {
        String itemType = (String) ar.get('itemType');

        options.add(new Option(itemType, itemType));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getSpecialOrderStatuses() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT ncf_body_special_statuses__c statusName
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE ncf_body_special_statuses__c != NULL
        GROUP BY ncf_body_special_statuses__c
      ]) {
        String statusName = (String) ar.get('statusName');

        options.add(new Option(statusName, statusName));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getLocations() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT breadwinner_ns__LocationName__c locationName
        FROM breadwinner_ns__BW_Sales_Order__c
        WHERE breadwinner_ns__LocationName__c != NULL
        GROUP BY breadwinner_ns__LocationName__c
      ]) {
        String locationName = (String) ar.get('locationName');

        options.add(new Option(locationName, locationName));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
