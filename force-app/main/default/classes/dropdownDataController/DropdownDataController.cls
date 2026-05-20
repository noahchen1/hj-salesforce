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

  public class AddressOption {
    @AuraEnabled
    public String label;

    @AuraEnabled
    public String value;

    @AuraEnabled
    public Boolean isDefaultShipping;

    @AuraEnabled
    public Boolean isDefaultBilling;

    @AuraEnabled
    public String nsInternalId;

    public AddressOption(
      String label,
      String value,
      Boolean isDefaultBilling,
      Boolean isDefaultShipping,
      String nsInternalId
    ) {
      this.label = label;
      this.value = value;
      this.isDefaultBilling = isDefaultBilling;
      this.isDefaultShipping = isDefaultShipping;
      this.nsInternalId = nsInternalId;
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
  public static List<AddressOption> getCustomerAddresses(
    Id nsCompanyId,
    String nsLocationId
  ) {
    List<AddressOption> options = new List<AddressOption>();

    try {
      for (breadwinner_ns__BW_Address__c addr : [
        SELECT
          Id,
          breadwinner_ns__AddrText__c,
          breadwinner_ns__DefaultShipping__c,
          breadwinner_ns__DefaultBilling__c,
          breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Address__c
        WHERE breadwinner_ns__Company__c = :nsCompanyId
      ]) {
        options.add(
          new AddressOption(
            addr.breadwinner_ns__AddrText__c,
            addr.Id,
            addr.breadwinner_ns__DefaultBilling__c,
            addr.breadwinner_ns__DefaultShipping__c,
            addr.breadwinner_ns__InternalId__c
          )
        );
      }

      Map<String, String> hardcodedAddressesByLocationId = getHardcodedAddressesByLocationId();
      if (
        String.isNotBlank(nsLocationId)
        && hardcodedAddressesByLocationId.containsKey(nsLocationId)
      ) {
        options.add(
          new AddressOption(
            hardcodedAddressesByLocationId.get(nsLocationId),
            nsLocationId,
            false,
            false,
            nsLocationId
          )
        );
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Map<String, String> getHardcodedAddressesByLocationId() {
    return new Map<String, String>{
      '18' => 'H1912\n104 Nassau Street\nPrinceton NJ 08542\nUnited States',
      '21' => 'H1912 Web Sales\n104 Nassau Street\nPrinceton NJ 08542\nUnited States',
      '22' => 'Hamilton Home\n33 Witherspoon Street\nPrinceton NJ 08542\nUnited States',
      '25' => 'Hamilton Jewelers\n215 Worth Ave\nPalm Beach FL 33480\nUnited States',
      '26' => 'Hamilton Jewelers\n3101 PGA BLVD\nPalm Beach Gardens FL 33410\nUnited States',
      '28' => 'Hamilton Jewelers\n92 Nassau Street\nPrinceton NJ 08542\nUnited States',
      '29' => 'Hamilton Jewelers\n14 S Tulane Street\nPrinceton NJ 08542\nUnited States',
      '30' => 'Hamilton Jewelers\n14 S Tulane Street\nPrinceton NJ 08542\nUnited States',
      '31' => 'Corp Gifts (Historical)\n14 S. Tulane\nPrinceton NJ 08542\nUnited States',
      '32' => 'Corporate Gifts\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
      '33' => 'Corporate Gifts Web Sales\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
      '34' => 'Red Bank\nUnited States',
      '35' => 'Websales\n14 S. Tulane\nPrinceton NJ 08542\nUnited States',
      '36' => 'Insignia Web Sales\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
      '37' => 'Insignia\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
      '38' => 'Marketing\nUnited States',
      '39' => 'Work In Progress\nUnited States',
      '41' => 'Hamilton Elimination Location\nUnited States',
      '42' => 'Retail Elimination Location\nUnited States'
    };
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getSubsidiaries() {
    List<Option> options = new List<Option>();

    try {
      for (breadwinner_ns__BW_Subsidiary__c sub : [
        SELECT breadwinner_ns__InternalId__c, Name
        FROM breadwinner_ns__BW_Subsidiary__c
        WHERE
          breadwinner_ns__InternalId__c != NULL
          AND breadwinner_ns__InternalId__c NOT IN ('31', '32', '33')
      ]) {
        options.add(new Option(sub.Name, sub.breadwinner_ns__InternalId__c));
      }

      return options;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Option> getSubsidiaryLocations(String subsidiary) {
    List<Option> options = new List<Option>();

    try {
      for (breadwinner_ns__BW_Location__c location : [
        SELECT breadwinner_ns__InternalId__c, Name
        FROM breadwinner_ns__BW_Location__c
        WHERE
          breadwinner_ns__Subsidiary__r.breadwinner_ns__InternalId__c = :subsidiary
      ]) {
        options.add(
          new Option(location.Name, location.breadwinner_ns__InternalId__c)
        );
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

      for (Campaign campaign : [SELECT Id, Name FROM Campaign]) {
        options.add(new Option(campaign.Name, campaign.Id));
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
