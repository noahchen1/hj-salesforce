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

  @isTest
  static void getParentByVendorNum_returnsEmptyMapWhenVendorNumIsBlank() {
    Test.startTest();
    Map<String, String> result = DataService.getParentByVendorNum('   ');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(true, result.isEmpty(), 'Result should be empty');
  }

  @isTest
  static void getParentByVendorNum_returnsEmptyMapWhenNoParentItemFound() {
    Test.startTest();
    Map<String, String> result = DataService.getParentByVendorNum('VENDOR-MISS');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      true,
      result.isEmpty(),
      'Result should be empty when no matching parent item exists'
    );
  }

  @isTest
  static void getParentByVendorNum_returnsParentItemDataWhenMatchFound() {
    breadwinner_ns__BW_Item__c parentItem = new breadwinner_ns__BW_Item__c(
      Name = 'PARENT-ITEM-001',
      breadwinner_ns__VendorName__c = 'VENDOR-OK',
      ncf_item_groupcode__c = 'INCLUDE',
      Base_Price__c = 125.5,
      breadwinner_ns__DisplayName__c = 'Parent Display Name'
    );
    insert parentItem;

    Test.startTest();
    Map<String, String> result = DataService.getParentByVendorNum('  VENDOR-OK  ');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      'PARENT-ITEM-001',
      result.get('name'),
      'name should come from the matched parent item'
    );
    System.assertEquals(
      '125.50',
      result.get('basePrice'),
      'basePrice should be returned as a string'
    );
    System.assertEquals(
      'Parent Display Name',
      result.get('displayName'),
      'displayName should match the item display name'
    );
  }

  @isTest
  static void getLocationAddress_returnsEmptyAddressWhenLocationIdIsBlank() {
    Test.startTest();
    DataService.LocationAddress result = DataService.getLocationAddress('   ');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      null,
      result.addressText,
      'addressText should be null for blank input'
    );
    System.assertEquals(
      null,
      result.country,
      'country should be null for blank input'
    );
  }

  @isTest
  static void getLocationAddress_returnsMappedAddressWhenLocationIdExists() {
    Test.startTest();
    DataService.LocationAddress result = DataService.getLocationAddress('18');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals('H1912', result.addressee, 'addressee should match');
    System.assertEquals(
      '104 Nassau Street',
      result.address_1,
      'address_1 should match configured location address'
    );
    System.assertEquals('Princeton', result.city, 'city should match');
    System.assertEquals('NJ', result.state, 'state should match');
    System.assertEquals('08542', result.zip, 'zip should match');
    System.assertEquals(
      'United States',
      result.country,
      'country should match'
    );
  }

  @isTest
  static void getLocationAddress_returnsMappedAddressForAllConfiguredLocations() {
    Map<String, List<String>> expectedByLocationId = new Map<String, List<String>>{
      '18' => new List<String>{
        'H1912\n104 Nassau Street\nPrinceton NJ 08542\nUnited States',
        'H1912',
        '104 Nassau Street',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '21' => new List<String>{
        'H1912 Web Sales\n104 Nassau Street\nPrinceton NJ 08542\nUnited States',
        'H1912 Web Sales',
        '104 Nassau Street',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '22' => new List<String>{
        'Hamilton Home\n33 Witherspoon Street\nPrinceton NJ 08542\nUnited States',
        'Hamilton Home',
        '33 Witherspoon Street',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '25' => new List<String>{
        'Hamilton Jewelers\n215 Worth Ave\nPalm Beach FL 33480\nUnited States',
        'Hamilton Jewelers',
        '215 Worth Ave',
        'Palm Beach',
        'FL',
        '33480',
        'United States'
      },
      '26' => new List<String>{
        'Hamilton Jewelers\n3101 PGA BLVD\nPalm Beach Gardens FL 33410\nUnited States',
        'Hamilton Jewelers',
        '3101 PGA BLVD',
        'Palm Beach Gardens',
        'FL',
        '33410',
        'United States'
      },
      '28' => new List<String>{
        'Hamilton Jewelers\n92 Nassau Street\nPrinceton NJ 08542\nUnited States',
        'Hamilton Jewelers',
        '92 Nassau Street',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '29' => new List<String>{
        'Hamilton Jewelers\n14 S Tulane Street\nPrinceton NJ 08542\nUnited States',
        'Hamilton Jewelers',
        '14 S Tulane Street',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '30' => new List<String>{
        'Hamilton Jewelers\n14 S Tulane Street\nPrinceton NJ 08542\nUnited States',
        'Hamilton Jewelers',
        '14 S Tulane Street',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '31' => new List<String>{
        'Corp Gifts (Historical)\n14 S. Tulane\nPrinceton NJ 08542\nUnited States',
        'Corp Gifts (Historical)',
        '14 S. Tulane',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '32' => new List<String>{
        'Corporate Gifts\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
        'Corporate Gifts',
        '930 TOWN CENTER DR G-50',
        'Langhorne',
        'PA',
        '19047',
        'United States'
      },
      '33' => new List<String>{
        'Corporate Gifts Web Sales\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
        'Corporate Gifts Web Sales',
        '930 TOWN CENTER DR G-50',
        'Langhorne',
        'PA',
        '19047',
        'United States'
      },
      '34' => new List<String>{
        'Red Bank\nUnited States',
        'Red Bank',
        null,
        null,
        null,
        null,
        'United States'
      },
      '35' => new List<String>{
        'Websales\n14 S. Tulane\nPrinceton NJ 08542\nUnited States',
        'Websales',
        '14 S. Tulane',
        'Princeton',
        'NJ',
        '08542',
        'United States'
      },
      '36' => new List<String>{
        'Insignia Web Sales\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
        'Insignia Web Sales',
        '930 TOWN CENTER DR G-50',
        'Langhorne',
        'PA',
        '19047',
        'United States'
      },
      '37' => new List<String>{
        'Insignia\n930 TOWN CENTER DR G-50\nLanghorne PA 19047\nUnited States',
        'Insignia',
        '930 TOWN CENTER DR G-50',
        'Langhorne',
        'PA',
        '19047',
        'United States'
      },
      '38' => new List<String>{
        'Marketing\nUnited States',
        'Marketing',
        null,
        null,
        null,
        null,
        'United States'
      },
      '39' => new List<String>{
        'Work In Progress\nUnited States',
        'Work In Progress',
        null,
        null,
        null,
        null,
        'United States'
      },
      '41' => new List<String>{
        'Hamilton Elimination Location\nUnited States',
        'Hamilton Elimination Location',
        null,
        null,
        null,
        null,
        'United States'
      },
      '42' => new List<String>{
        'Retail Elimination Location\nUnited States',
        'Retail Elimination Location',
        null,
        null,
        null,
        null,
        'United States'
      }
    };

    Test.startTest();
    for (String locationId : expectedByLocationId.keySet()) {
      List<String> expected = expectedByLocationId.get(locationId);
      DataService.LocationAddress result = DataService.getLocationAddress(locationId);

      System.assertNotEquals(
        null,
        result,
        'Result should not be null for locationId=' + locationId
      );
      System.assertEquals(
        expected[0],
        result.addressText,
        'addressText should match for locationId=' + locationId
      );
      System.assertEquals(
        expected[1],
        result.addressee,
        'addressee should match for locationId=' + locationId
      );
      System.assertEquals(
        expected[2],
        result.address_1,
        'address_1 should match for locationId=' + locationId
      );
      System.assertEquals(
        expected[3],
        result.city,
        'city should match for locationId=' + locationId
      );
      System.assertEquals(
        expected[4],
        result.state,
        'state should match for locationId=' + locationId
      );
      System.assertEquals(
        expected[5],
        result.zip,
        'zip should match for locationId=' + locationId
      );
      System.assertEquals(
        expected[6],
        result.country,
        'country should match for locationId=' + locationId
      );
    }
    Test.stopTest();
  }

  @isTest
  static void getLocationAddress_returnsEmptyAddressWhenLocationIdIsUnknown() {
    Test.startTest();
    DataService.LocationAddress result = DataService.getLocationAddress('999');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      null,
      result.addressText,
      'addressText should be null for unknown location'
    );
    System.assertEquals(
      null,
      result.addressee,
      'addressee should be null for unknown location'
    );
  }
}
