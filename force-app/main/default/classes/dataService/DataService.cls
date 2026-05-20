public with sharing class DataService {
  @TestVisible
  private static Map<Id, EmployeeResult> testEmployeeResultsByUserId;

  public class EmployeeResult {
    @AuraEnabled
    public String employeeId;
    @AuraEnabled
    public String employeeName;
    @AuraEnabled
    public String subsidiaryId;
    @AuraEnabled
    public String subsidiaryName;
    @AuraEnabled
    public String locationId;
    @AuraEnabled
    public String locationName;
  }

  public class LocationAddress {
    @AuraEnabled
    public String addressText;
    @AuraEnabled
    public String addressee;
    @AuraEnabled
    public String address_1;
    @AuraEnabled
    public String address_2;
    @AuraEnabled
    public String address_3;
    @AuraEnabled
    public String attention;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String zip;
    @AuraEnabled
    public String country;

    public LocationAddress() {
    }

    public LocationAddress(
      String addressText,
      String addressee,
      String address_1,
      String address_2,
      String address_3,
      String attention,
      String city,
      String state,
      String zip,
      String country
    ) {
      this.addressText = addressText;
      this.addressee = addressee;
      this.address_1 = address_1;
      this.address_2 = address_2;
      this.address_3 = address_3;
      this.attention = attention;
      this.city = city;
      this.state = state;
      this.zip = zip;
      this.country = country;
    }
  }

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

  @AuraEnabled(cacheable=true)
  public static Map<String, Decimal> getItemQuantities(
    String itemName,
    String nsLocationId
  ) {
    try {
      List<breadwinner_ns__BW_Inventory_Location__c> inventoryLocations = [
        SELECT
          breadwinner_ns__QuantityAvailable__c,
          breadwinner_ns__QuantityBackOrdered__c
        FROM breadwinner_ns__BW_Inventory_Location__c
        WHERE
          breadwinner_ns__Item__r.Name = :itemName
          AND breadwinner_ns__Location__r.breadwinner_ns__InternalId__c = :nsLocationId
        LIMIT 1
      ];

      if (inventoryLocations.isEmpty()) {
        return new Map<String, Decimal>();
      }

      Decimal quantityAvailable = inventoryLocations[0]
        .breadwinner_ns__QuantityAvailable__c;
      Decimal quantityBackOrdered = inventoryLocations[0]
        .breadwinner_ns__QuantityBackOrdered__c;

      return new Map<String, Decimal>{
        'quantityAvailable' => quantityAvailable,
        'quantityBackOrdered' => quantityBackOrdered
      };
    } catch (Exception err) {
      System.debug(
        LoggingLevel.ERROR,
        'DataService.getItemQuantities failed: ' + err.getMessage()
      );
      throw new AuraHandledException(
        'Unable to verify on-hand inventory at this time.'
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static EmployeeResult getEmployeeData(Id userId) {
    if (userId == null) {
      throw new AuraHandledException('User Id is required.');
    }

    if (
      Test.isRunningTest() &&
      testEmployeeResultsByUserId != null &&
      testEmployeeResultsByUserId.containsKey(userId)
    ) {
      return testEmployeeResultsByUserId.get(userId);
    }

    try {
      breadwinner_ns__BW_Employee__c emp = [
        SELECT
          Name,
          breadwinner_ns__InternalId__c,
          breadwinner_ns__Subsidiary__r.breadwinner_ns__InternalId__c,
          breadwinner_ns__Subsidiary__r.Name,
          breadwinner_ns__LocationName__c
        FROM breadwinner_ns__BW_Employee__c
        WHERE breadwinner_ns__Salesforce_User__c = :userId
        LIMIT 1
      ];

      EmployeeResult result = new EmployeeResult();

      result.employeeId = emp.breadwinner_ns__InternalId__c;
      result.employeeName = emp.Name;
      result.subsidiaryId = emp.breadwinner_ns__Subsidiary__r
        ?.breadwinner_ns__InternalId__c;
      result.subsidiaryName = emp.breadwinner_ns__Subsidiary__r?.Name;

      if (String.isNotBlank(emp.breadwinner_ns__LocationName__c)) {
        breadwinner_ns__BW_Location__c loc = [
          SELECT Name, breadwinner_ns__InternalId__c
          FROM breadwinner_ns__BW_Location__c
          WHERE Name = :emp.breadwinner_ns__LocationName__c
          LIMIT 1
        ];

        result.locationId = loc.breadwinner_ns__InternalId__c;
        result.locationName = loc.Name;
      }

      return result;
    } catch (QueryException e) {
      return new EmployeeResult();
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'DataService.getEmployeeData failed: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Unable to load employee data at this time.'
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> getValue(
    String recordName,
    List<String> fieldNames,
    Id recordId
  ) {
    if (
      String.isBlank(recordName) ||
      fieldNames == null ||
      fieldNames.isEmpty() ||
      recordId == null
    ) {
      throw new AuraHandledException(
        'recordName, fieldNames, and recordId are required.'
      );
    }

    Pattern apiNamePattern = Pattern.compile(
      '^[a-zA-Z_][a-zA-Z0-9_]*(__c|__r)?$'
    );
    if (!apiNamePattern.matcher(recordName).matches()) {
      throw new AuraHandledException('Invalid object name.');
    }
    for (String fieldName : fieldNames) {
      if (!apiNamePattern.matcher(fieldName).matches()) {
        throw new AuraHandledException('Invalid field name: ' + fieldName);
      }
    }

    String query =
      'SELECT ' +
      String.join(fieldNames, ', ') +
      ' FROM ' +
      recordName +
      ' WHERE Id = :recordId';

    List<SObject> results = Database.query(query);

    if (results.isEmpty()) {
      return null;
    }

    Map<String, String> fieldValues = new Map<String, String>();

    for (String fieldName : fieldNames) {
      Object fieldValue = results[0].get(fieldName);

      fieldValues.put(
        fieldName,
        fieldValue != null ? String.valueOf(fieldValue) : null
      );
    }

    return fieldValues;
  }

  @AuraEnabled
  public static Map<String, String> getParentByVendorNum(String vendorNum) {
    if (String.isBlank(vendorNum)) {
      return new Map<String, String>();
    }

    String normalizedVendorNum = vendorNum.trim();

    List<breadwinner_ns__BW_Item__c> items = [
      SELECT Name, Base_Price__c, breadwinner_ns__DisplayName__c
      FROM breadwinner_ns__BW_Item__c
      WHERE
        breadwinner_ns__VendorName__c = :normalizedVendorNum
        AND breadwinner_ns__Parent__c = NULL
        AND ncf_item_groupcode__c NOT IN ('WRTRD', 'WRCPO')
      LIMIT 1
    ];

    if (items.isEmpty())
      return new Map<String, String>();

    breadwinner_ns__BW_Item__c item = items[0];

    return new Map<String, String>{
      'name' => item.Name,
      'basePrice' => String.valueOf(item.Base_Price__c),
      'displayName' => item.breadwinner_ns__DisplayName__c
    };
  }

  @AuraEnabled
  public static LocationAddress getLocationAddress(String nsLocationId) {
    if (String.isBlank(nsLocationId)) {
      return new LocationAddress();
    }

    switch on nsLocationId {
      when '18' {
        return new LocationAddress(
          'H1912\n104 Nassau Street\nPrinceton NJ 08542\nUnited States',
          'H1912',
          '104 Nassau Street',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '21' {
        return new LocationAddress(
          'H1912 Web Sales\n104 Nassau Street\nPrinceton NJ 08542\nUnited States',
          'H1912 Web Sales',
          '104 Nassau Street',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '22' {
        return new LocationAddress(
          'Hamilton Home\n33 Witherspoon Street\nPrinceton NJ 08542\nUnited States',
          'Hamilton Home',
          '33 Witherspoon Street',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '25' {
        return new LocationAddress(
          'Hamilton Jewelers\n215 Worth Ave\nPalm Beach FL 33480\nUnited States',
          'Hamilton Jewelers',
          '215 Worth Ave',
          null,
          null,
          null,
          'Palm Beach',
          'FL',
          '33480',
          'United States'
        );
      }
      when '26' {
        return new LocationAddress(
          'Hamilton Jewelers\n3101 PGA BLVD\nPalm Beach Gardens FL 33410\nUnited States',
          'Hamilton Jewelers',
          '3101 PGA BLVD',
          null,
          null,
          null,
          'Palm Beach Gardens',
          'FL',
          '33410',
          'United States'
        );
      }
      when '28' {
        return new LocationAddress(
          'Hamilton Jewelers\n92 Nassau Street\nPrinceton NJ 08542\nUnited States',
          'Hamilton Jewelers',
          '92 Nassau Street',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '29' {
        return new LocationAddress(
          'Hamilton Jewelers\n14 S Tulane Street\nPrinceton NJ 08542\nUnited States',
          'Hamilton Jewelers',
          '14 S Tulane Street',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '30' {
        return new LocationAddress(
          'Hamilton Jewelers\n14 S Tulane Street\nPrinceton NJ 08542\nUnited States',
          'Hamilton Jewelers',
          '14 S Tulane Street',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '31' {
        return new LocationAddress(
          'Corp Gifts (Historical)\n14 S. Tulane\nPrinceton NJ 08542\nUnited States',
          'Corp Gifts (Historical)',
          '14 S. Tulane',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '32' {
        return new LocationAddress(
          'Corporate Gifts\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
          'Corporate Gifts',
          '930 TOWN CENTER DR G-50',
          null,
          null,
          null,
          'Langhorne',
          'PA',
          '19047',
          'United States'
        );
      }
      when '33' {
        return new LocationAddress(
          'Corporate Gifts Web Sales\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
          'Corporate Gifts Web Sales',
          '930 TOWN CENTER DR G-50',
          null,
          null,
          null,
          'Langhorne',
          'PA',
          '19047',
          'United States'
        );
      }
      when '34' {
        return new LocationAddress(
          'Red Bank\nUnited States',
          'Red Bank',
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          'United States'
        );
      }
      when '35' {
        return new LocationAddress(
          'Websales\n14 S. Tulane\nPrinceton NJ 08542\nUnited States',
          'Websales',
          '14 S. Tulane',
          null,
          null,
          null,
          'Princeton',
          'NJ',
          '08542',
          'United States'
        );
      }
      when '36' {
        return new LocationAddress(
          'Insignia Web Sales\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
          'Insignia Web Sales',
          '930 TOWN CENTER DR G-50',
          null,
          null,
          null,
          'Langhorne',
          'PA',
          '19047',
          'United States'
        );
      }
      when '37' {
        return new LocationAddress(
          'Insignia\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
          'Insignia',
          '930 TOWN CENTER DR G-50',
          null,
          null,
          null,
          'Langhorne',
          'PA',
          '19047',
          'United States'
        );
      }
      when '38' {
        return new LocationAddress(
          'Marketing\nUnited States',
          'Marketing',
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          'United States'
        );
      }
      when '39' {
        return new LocationAddress(
          'Work In Progress\nUnited States',
          'Work In Progress',
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          'United States'
        );
      }
      when '41' {
        return new LocationAddress(
          'Hamilton Elimination Location\nUnited States',
          'Hamilton Elimination Location',
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          'United States'
        );
      }
      when '42' {
        return new LocationAddress(
          'Retail Elimination Location\nUnited States',
          'Retail Elimination Location',
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          'United States'
        );
      }
      when else {
        return new LocationAddress();
      }
    }
  }
}
