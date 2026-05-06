public with sharing class DataService {
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
  public static EmployeeResult getEmployeeData(Id userId) {
    if (userId == null) {
      throw new AuraHandledException('User Id is required.');
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
    if (String.isBlank(recordName) || fieldNames == null || fieldNames.isEmpty() || recordId == null) {
      throw new AuraHandledException('recordName, fieldNames, and recordId are required.');
    }

    Pattern apiNamePattern = Pattern.compile('^[a-zA-Z_][a-zA-Z0-9_]*(__c|__r)?$');
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

      fieldValues.put(fieldName, fieldValue != null ? String.valueOf(fieldValue) : null);
    }

    return fieldValues;
  }
}
