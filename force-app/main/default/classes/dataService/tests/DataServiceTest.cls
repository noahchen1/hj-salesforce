@isTest
private class DataServiceTest {
  @isTest
  static void checkOnHand_returnsTrueWhenSufficientInventory() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'TestItem'
    );
    insert item;

    breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
      Name = 'TestLocation',
      breadwinner_ns__InternalId__c = 'LOC001'
    );
    insert loc;

    breadwinner_ns__BW_Inventory_Location__c inv = new breadwinner_ns__BW_Inventory_Location__c(
      breadwinner_ns__Item__c = item.Id,
      breadwinner_ns__Location__c = loc.Id,
      breadwinner_ns__QuantityAvailable__c = 10
    );
    insert inv;

    Test.startTest();
    Boolean result = DataService.checkOnHand('TestItem', 'LOC001', 5);
    Test.stopTest();

    System.assertEquals(
      true,
      result,
      'Should return true when available qty >= requested qty'
    );
  }

  @isTest
  static void checkOnHand_returnsFalseWhenInsufficientInventory() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'LowStockItem'
    );
    insert item;

    breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
      Name = 'TestLocation2',
      breadwinner_ns__InternalId__c = 'LOC002'
    );
    insert loc;

    breadwinner_ns__BW_Inventory_Location__c inv = new breadwinner_ns__BW_Inventory_Location__c(
      breadwinner_ns__Item__c = item.Id,
      breadwinner_ns__Location__c = loc.Id,
      breadwinner_ns__QuantityAvailable__c = 2
    );
    insert inv;

    Test.startTest();
    Boolean result = DataService.checkOnHand('LowStockItem', 'LOC002', 5);
    Test.stopTest();

    System.assertEquals(
      false,
      result,
      'Should return false when available qty < requested qty'
    );
  }

  @isTest
  static void checkOnHand_returnsFalseWhenNoInventoryLocationFound() {
    Test.startTest();
    Boolean result = DataService.checkOnHand('NonExistentItem', 'LOC999', 1);
    Test.stopTest();

    System.assertEquals(
      false,
      result,
      'Should return false when no inventory location record exists'
    );
  }

  @isTest
  static void checkOnHand_returnsFalseWhenQuantityAvailableIsNull() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'NullQtyItem'
    );
    insert item;

    breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
      Name = 'TestLocation3',
      breadwinner_ns__InternalId__c = 'LOC003'
    );
    insert loc;

    breadwinner_ns__BW_Inventory_Location__c inv = new breadwinner_ns__BW_Inventory_Location__c(
      breadwinner_ns__Item__c = item.Id,
      breadwinner_ns__Location__c = loc.Id,
      breadwinner_ns__QuantityAvailable__c = null
    );
    insert inv;

    Test.startTest();
    Boolean result = DataService.checkOnHand('NullQtyItem', 'LOC003', 1);
    Test.stopTest();

    System.assertEquals(
      false,
      result,
      'Should return false when quantity available is null'
    );
  }

  @isTest
  static void getItemQuantities_returnsQuantitiesWhenFound() {
    breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
      Name = 'QuantityItem'
    );
    insert item;

    breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
      Name = 'QtyLocation',
      breadwinner_ns__InternalId__c = 'LOC004'
    );
    insert loc;

    breadwinner_ns__BW_Inventory_Location__c inv = new breadwinner_ns__BW_Inventory_Location__c(
      breadwinner_ns__Item__c = item.Id,
      breadwinner_ns__Location__c = loc.Id,
      breadwinner_ns__QuantityAvailable__c = 8,
      breadwinner_ns__QuantityBackOrdered__c = 3
    );
    insert inv;

    Test.startTest();
    Map<String, Decimal> result = DataService.getItemQuantities(
      'QuantityItem',
      'LOC004'
    );
    Test.stopTest();

    System.assertEquals(
      8,
      result.get('quantityAvailable'),
      'quantityAvailable should be 8'
    );
    System.assertEquals(
      3,
      result.get('quantityBackOrdered'),
      'quantityBackOrdered should be 3'
    );
  }

  @isTest
  static void getItemQuantities_returnsEmptyMapWhenNotFound() {
    Test.startTest();
    Map<String, Decimal> result = DataService.getItemQuantities(
      'GhostItem',
      'LOC999'
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result map should not be null');
    System.assertEquals(
      true,
      result.isEmpty(),
      'Result map should be empty when no record found'
    );
  }

  // ─── getEmployeeData ──────────────────────────────────────────────────────

  @isTest
  static void getEmployeeData_throwsWhenUserIdIsNull() {
    Test.startTest();
    try {
      DataService.getEmployeeData(null);
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getEmployeeData_returnsEmptyResultWhenNoEmployeeFound() {
    User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

    Test.startTest();
    DataService.EmployeeResult result = DataService.getEmployeeData(u.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      null,
      result.employeeId,
      'employeeId should be null when no employee record found'
    );
  }

  @isTest
  static void getEmployeeData_returnsPopulatedResultWhenEmployeeFound() {
    User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

    DataService.EmployeeResult mockResult = new DataService.EmployeeResult();
    mockResult.employeeId = 'EMP001';
    mockResult.employeeName = 'Test Employee';
    mockResult.subsidiaryId = 'SUB001';
    mockResult.subsidiaryName = 'Test Subsidiary';
    mockResult.locationId = 'LOC005';
    mockResult.locationName = 'EmpLocation';
    DataService.testEmployeeResultsByUserId = new Map<Id, DataService.EmployeeResult>{
      u.Id => mockResult
    };

    Test.startTest();
    DataService.EmployeeResult result = DataService.getEmployeeData(u.Id);
    Test.stopTest();

    DataService.testEmployeeResultsByUserId = null;

    System.assertEquals('EMP001', result.employeeId, 'employeeId should match');
    System.assertEquals(
      'Test Employee',
      result.employeeName,
      'employeeName should match'
    );
    System.assertEquals(
      'SUB001',
      result.subsidiaryId,
      'subsidiaryId should match'
    );
    System.assertEquals(
      'Test Subsidiary',
      result.subsidiaryName,
      'subsidiaryName should match'
    );
    System.assertEquals('LOC005', result.locationId, 'locationId should match');
    System.assertEquals(
      'EmpLocation',
      result.locationName,
      'locationName should match'
    );
  }

  @isTest
  static void getEmployeeData_returnsResultWithoutLocationWhenLocationNameBlank() {
    User u = [
      SELECT Id
      FROM User
      WHERE IsActive = TRUE AND Id != :UserInfo.getUserId()
      LIMIT 1
    ];

    DataService.EmployeeResult mockResult = new DataService.EmployeeResult();
    mockResult.employeeId = 'EMP002';
    mockResult.employeeName = 'No Location Employee';
    mockResult.subsidiaryId = 'SUB002';
    mockResult.subsidiaryName = 'Sub NoLoc';
    mockResult.locationId = null;
    mockResult.locationName = null;
    DataService.testEmployeeResultsByUserId = new Map<Id, DataService.EmployeeResult>{
      u.Id => mockResult
    };

    Test.startTest();
    DataService.EmployeeResult result = DataService.getEmployeeData(u.Id);
    Test.stopTest();

    DataService.testEmployeeResultsByUserId = null;

    System.assertEquals('EMP002', result.employeeId, 'employeeId should match');
    System.assertEquals(
      null,
      result.locationId,
      'locationId should be null when no location name'
    );
  }

  // ─── getValue ─────────────────────────────────────────────────────────────

  @isTest
  static void getValue_throwsWhenRecordNameIsBlank() {
    Test.startTest();
    try {
      DataService.getValue(
        '',
        new List<String>{ 'Name' },
        UserInfo.getUserId()
      );
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getValue_throwsWhenFieldNamesIsNull() {
    Test.startTest();
    try {
      DataService.getValue('User', null, UserInfo.getUserId());
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getValue_throwsWhenFieldNamesIsEmpty() {
    Test.startTest();
    try {
      DataService.getValue('User', new List<String>(), UserInfo.getUserId());
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getValue_throwsWhenRecordIdIsNull() {
    Test.startTest();
    try {
      DataService.getValue('User', new List<String>{ 'Name' }, null);
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getValue_throwsWhenObjectNameIsInvalid() {
    Test.startTest();
    try {
      DataService.getValue(
        'Robert; DROP TABLE Users--',
        new List<String>{ 'Name' },
        UserInfo.getUserId()
      );
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getValue_throwsWhenFieldNameIsInvalid() {
    Test.startTest();
    try {
      DataService.getValue(
        'User',
        new List<String>{ 'Name; DROP TABLE--' },
        UserInfo.getUserId()
      );
      System.assert(false, 'Expected AuraHandledException was not thrown');
    } catch (AuraHandledException e) {
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void getValue_returnsFieldValuesForExistingRecord() {
    Id userId = UserInfo.getUserId();

    Test.startTest();
    Map<String, String> result = DataService.getValue(
      'User',
      new List<String>{ 'Name', 'Email' },
      userId
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertNotEquals(
      null,
      result.get('Name'),
      'Name field value should be returned'
    );
    System.assertNotEquals(
      null,
      result.get('Email'),
      'Email field value should be returned'
    );
  }

  @isTest
  static void getValue_returnsNullWhenRecordNotFound() {
    // Use a well-formed but non-existent Id
    Id fakeId = '005000000000001AAA';

    Test.startTest();
    Map<String, String> result = DataService.getValue(
      'User',
      new List<String>{ 'Name' },
      fakeId
    );
    Test.stopTest();

    System.assertEquals(
      null,
      result,
      'Result should be null when no record matches the Id'
    );
  }
}
