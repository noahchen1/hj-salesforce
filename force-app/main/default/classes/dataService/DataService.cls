public with sharing class DataService {
  public class EmployeeInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;

    public EmployeeInfo(String id, String name) {
      this.id = id;
      this.name = name;
    }
  }

  public class SubsidiaryInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;

    public SubsidiaryInfo(String id, String name) {
      this.id = id;
      this.name = name;
    }
  }

  public class LocationInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;

    public LocationInfo(String id, String name) {
      this.id = id;
      this.name = name;
    }
  }

  public class EmployeeResult {
    @AuraENabled
    public EmployeeInfo employeeInfo;
    @AuraEnabled
    public SubsidiaryInfo subsidiary;
    @AuraEnabled
    public LocationInfo location;

    public EmployeeResult(
      SubsidiaryInfo subsidiary,
      LocationInfo location,
      EmployeeInfo employeeInfo
    ) {
      this.subsidiary = subsidiary;
      this.location = location;
      this.employeeInfo = employeeInfo;
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
  public static EmployeeResult getEmployeeData(Id id) {
    if (id == null) {
      throw new AuraHandledException('User Id is required.');
    }

    try {
      List<breadwinner_ns__BW_Employee__c> employees = [
        SELECT
          Name,
          breadwinner_ns__InternalId__c,
          breadwinner_ns__Subsidiary__r.breadwinner_ns__InternalId__c,
          breadwinner_ns__Subsidiary__r.Name,
          breadwinner_ns__LocationName__c
        FROM breadwinner_ns__BW_Employee__c
        WHERE breadwinner_ns__Salesforce_User__c = :id
        LIMIT 1
      ];

      if (employees.isEmpty()) {
        return new EmployeeResult(null, null, null);
      }

      breadwinner_ns__BW_Employee__c emp = employees[0];

      SubsidiaryInfo subsidiary = null;

      if (emp.breadwinner_ns__Subsidiary__c != null) {
        subsidiary = new SubsidiaryInfo(
          emp.breadwinner_ns__Subsidiary__r?.breadwinner_ns__InternalId__c,
          emp.breadwinner_ns__Subsidiary__r?.Name
        );
      }

      EmployeeInfo employeeInfo = new EmployeeInfo(
        emp.breadwinner_ns__InternalId__c,
        emp.Name
      );

      LocationInfo location = null;
      if (String.isNotBlank(emp.breadwinner_ns__LocationName__c)) {
        List<breadwinner_ns__BW_Location__c> locations = [
          SELECT Name, breadwinner_ns__InternalId__c
          FROM breadwinner_ns__BW_Location__c
          WHERE Name = :emp.breadwinner_ns__LocationName__c
          LIMIT 1
        ];

        if (
          !locations.isEmpty() &&
          String.isNotBlank(locations[0].breadwinner_ns__InternalId__c)
        ) {
          location = new LocationInfo(
            locations[0].breadwinner_ns__InternalId__c,
            locations[0].Name
          );
        }
      }

      System.debug(
        'employee data: ' +
        new EmployeeResult(subsidiary, location, employeeInfo)
      );
      return new EmployeeResult(subsidiary, location, employeeInfo);
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
}
