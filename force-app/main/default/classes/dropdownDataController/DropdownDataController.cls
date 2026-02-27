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

  @AuraEnabled(cacheable=true)
  public static List<Option> getDivisions() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT Division__c division
        FROM Sales_History__c
        WHERE Division__c NOT IN ('Opening Balance', 'Shipping (7)')
        GROUP BY Division__c
      ]) {
        String divisionName = (String) ar.get('division');

        options.add(new Option(divisionName, divisionName));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getDepartments() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT Department__c department
        FROM Sales_History__c
        GROUP BY Department__c
      ]) {
        String departmentName = (String) ar.get('department');

        options.add(new Option(departmentName, departmentName));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getGroupCodes() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT Group_Code__c groupcode
        FROM Sales_History__c
        GROUP BY Group_Code__c
      ]) {
        String groupCodeName = (String) ar.get('groupcode');

        options.add(new Option(groupCodeName, groupCodeName));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getCampaigns() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT Campaign.Id campaignId, Campaign.Name campaignName
        FROM CampaignMember
        WHERE Account.OwnerId = :UserInfo.getUserId()
        GROUP BY Campaign.Id, Campaign.Name
      ]) {
        String Id = (String) ar.get('campaignId');
        String Name = (String) ar.get('campaignName');
        options.add(new Option(Name, Id));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getAllCampaigns() {
    List<Option> options = new List<Option>();

    try {
      for (AggregateResult ar : [
        SELECT Campaign.Id campaignId, Campaign.Name campaignName
        FROM CampaignMember
        GROUP BY Campaign.Id, Campaign.Name
      ]) {
        String Id = (String) ar.get('campaignId');
        String Name = (String) ar.get('campaignName');
        options.add(new Option(Name, Id));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getCustomEmailTemplates(String type) {
    List<Option> options = new List<Option>();

    try {
      for (Custom_Email_Template__c template : [
        SELECT Id, Label__c
        FROM Custom_Email_Template__c
        WHERE Type__c = :type
      ]) {
        options.add(new Option(template.Label__c, template.Id));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
