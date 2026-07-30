@isTest
private class HelpersTest {
  @isTest
  static void testGetFirstNonEmptyString() {
    System.assertEquals(null, Helpers.getFirstNonEmptyString(null));
    System.assertEquals(
      null,
      Helpers.getFirstNonEmptyString(new List<String>())
    );
    System.assertEquals(
      null,
      Helpers.getFirstNonEmptyString(new List<String>{ '', '   ' })
    );
    System.assertEquals(
      'value',
      Helpers.getFirstNonEmptyString(
        new List<String>{ '', '   ', 'value', 'next' }
      )
    );
  }

  @isTest
  static void testWriteLog() {
    Test.startTest();
    Helpers.writeLog('Helpers Test', 'Details from unit test');
    Test.stopTest();

    List<Script_Log__c> logs = [
      SELECT Title__c, Details__c, Timestamp__c
      FROM Script_Log__c
      WHERE Title__c = 'Helpers Test'
      LIMIT 1
    ];

    System.assertEquals(1, logs.size());
    System.assertEquals('Details from unit test', logs[0].Details__c);
    System.assertNotEquals(null, logs[0].Timestamp__c);
  }

  @isTest
  static void testValuesEqual() {
    System.assertEquals(true, Helpers.valuesEqual(null, null));
    System.assertEquals(false, Helpers.valuesEqual(null, 'x'));
    System.assertEquals(true, Helpers.valuesEqual('100', 100));
    System.assertEquals(false, Helpers.valuesEqual('abc', 'def'));
  }

  @isTest
  static void testToIntOrNull() {
    System.assertEquals(null, Helpers.toIntOrNull(null));
    System.assertEquals(null, Helpers.toIntOrNull('   '));
    System.assertEquals(42, Helpers.toIntOrNull(' 42 '));
    System.assertEquals(-7, Helpers.toIntOrNull('-7'));
    System.assertEquals(null, Helpers.toIntOrNull('not-a-number'));
  }

  @isTest
  static void testGetPicklistLabels() {
    Map<String, String> validResult = Helpers.getPicklistLabels(
      'Task',
      'Priority'
    );
    System.assertNotEquals(null, validResult);
    System.assert(
      validResult.size() > 0,
      'Expected standard Task.Priority values'
    );

    Map<String, String> invalidResult = Helpers.getPicklistLabels(
      'NotARealObject__c',
      'Fake_Field__c'
    );
    System.assertNotEquals(null, invalidResult);
    System.assertEquals(0, invalidResult.size());
  }

  @isTest
  static void testToDateOnlyFromUnixSeconds() {
    System.assertEquals(null, Helpers.toDateOnlyFromUnixSeconds(null));
    System.assertEquals('1970-01-01', Helpers.toDateOnlyFromUnixSeconds(0L));
    System.assertEquals(
      '1970-01-02',
      Helpers.toDateOnlyFromUnixSeconds(86400L)
    );
  }

  @isTest
  static void testToUnixSeconds() {
    Date sourceDate = Date.newInstance(2024, 6, 15);
    Long expected =
      DateTime.newInstance(sourceDate, Time.newInstance(0, 0, 0, 0)).getTime() /
      1000;

    System.assertEquals(expected, Helpers.toUnixSeconds(sourceDate));
  }

  @isTest
  static void testToUnixSecondsNullThrows() {
    Boolean didThrow = false;

    try {
      Helpers.toUnixSeconds(null);
    } catch (Exception e) {
      didThrow = true;
    }

    System.assertEquals(true, didThrow);
  }

  @isTest
  static void testBuildAuraException() {
    String message = 'Custom error message';

    AuraHandledException ex = Helpers.buildAuraException(message);

    System.assertNotEquals(null, ex, 'Exception should be returned');
    System.assertEquals(
      message,
      ex.getMessage(),
      'Exception message should match input'
    );
  }

  @isTest
  static void testNormalizeString() {
    System.assertEquals(null, Helpers.normalizeString(null));
    System.assertEquals(null, Helpers.normalizeString(''));
    System.assertEquals(null, Helpers.normalizeString('   '));
    System.assertEquals(
      'hello world',
      Helpers.normalizeString('  HeLLo WoRLD  ')
    );
    System.assertEquals('abc123', Helpers.normalizeString('ABC123'));
  }

  @isTest
  static void testGetFileNameFromContentDisposition() {
    System.assertEquals(null, Helpers.getFileNameFromContentDisposition(null));
    System.assertEquals(
      null,
      Helpers.getFileNameFromContentDisposition('attachment')
    );
    System.assertEquals(
      'document.pdf',
      Helpers.getFileNameFromContentDisposition(
        'attachment; filename="document.pdf"'
      )
    );
    System.assertEquals(
      'report final.csv',
      Helpers.getFileNameFromContentDisposition(
        'inline; filename=report final.csv; size=1024'
      )
    );
  }

  @isTest
  static void testGetTitleFromFileName() {
    System.assertEquals('downloaded-file', Helpers.getTitleFromFileName(null));
    System.assertEquals('downloaded-file', Helpers.getTitleFromFileName('   '));
    System.assertEquals(
      'sales.order',
      Helpers.getTitleFromFileName('sales.order.pdf')
    );
    System.assertEquals('readme', Helpers.getTitleFromFileName('readme'));
    System.assertEquals(
      '.gitignore',
      Helpers.getTitleFromFileName('.gitignore')
    );
  }

  @isTest
  static void testGetLocations() {
    User locationUser = new User(
      Alias = 'locuser',
      Email = 'helpers-location@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Helpers Location',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      Location__c = 'Worth Ave',
      ProfileId = UserInfo.getProfileId(),
      TimeZoneSidKey = 'America/New_York',
      UserName = 'helpers-location-' + DateTime.now().getTime() + '@example.com'
    );
    insert locationUser;

    System.runAs(locationUser) {
      System.assertEquals(null, Helpers.getLocations(SalesOrderType.sales));
      System.assertEquals(
        new Set<String>{ 'Worth Ave' },
        Helpers.getLocations(SalesOrderType.repair)
      );
    }
  }

  @isTest
  static void testGetLocationsForNjManager() {
    User locationUser = createLocationUser('njmgr', 'Worth Ave');
    Group managerGroup = getOrCreateGroup(
      'Managers - New Jersey',
      'Managers_New_Jersey'
    );

    insert new GroupMember(
      GroupId = managerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(
        new Set<String>{ 'H1912', 'Princeton', 'Hamilton Home' },
        Helpers.getLocations(SalesOrderType.repair)
      );
    }
  }

  @isTest
  static void testGetLocationsForNjServiceManager() {
    User locationUser = createLocationUser('njsvc', 'Worth Ave');
    Group managerGroup = getOrCreateGroup(
      'Service Managers - NJ',
      'Service_Managers_NJ'
    );

    insert new GroupMember(
      GroupId = managerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(
        new Set<String>{ 'H1912', 'Princeton', 'Hamilton Home' },
        Helpers.getLocations(SalesOrderType.repair)
      );
    }
  }

  @isTest
  static void testGetLocationsForPbgServiceManager() {
    User locationUser = createLocationUser('pbgsvc', 'Worth Ave');
    Group managerGroup = getOrCreateGroup(
      'Service Manager - PBG',
      'Service_Manager_PBG'
    );

    insert new GroupMember(
      GroupId = managerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(
        new Set<String>{ 'Palm Beach Gardens' },
        Helpers.getLocations(SalesOrderType.repair)
      );
    }
  }

  @isTest
  static void testGetLocationsCombinesServiceManagerGroups() {
    User locationUser = createLocationUser('multisvc', 'Worth Ave');
    Group njManagerGroup = getOrCreateGroup(
      'Service Managers - NJ',
      'Service_Managers_NJ'
    );
    Group pbgManagerGroup = getOrCreateGroup(
      'Service Manager - PBG',
      'Service_Manager_PBG'
    );

    insert new List<GroupMember>{
      new GroupMember(
        GroupId = njManagerGroup.Id,
        UserOrGroupId = locationUser.Id
      ),
      new GroupMember(
        GroupId = pbgManagerGroup.Id,
        UserOrGroupId = locationUser.Id
      )
    };

    System.runAs(locationUser) {
      System.assertEquals(
        new Set<String>{
          'H1912',
          'Princeton',
          'Hamilton Home',
          'Palm Beach Gardens'
        },
        Helpers.getLocations(SalesOrderType.repair)
      );
    }
  }

  @isTest
  static void testManagersAllTakesPrecedenceOverNestedServiceManager() {
    User locationUser = createLocationUser('nestednj', 'Worth Ave');
    Group serviceManagerGroup = getOrCreateGroup(
      'Service Managers - NJ',
      'Service_Managers_NJ'
    );
    Group allManagerGroup = getOrCreateGroup('Managers - All', 'Managers_All');

    ensureGroupMembership(serviceManagerGroup.Id, allManagerGroup.Id);
    insert new GroupMember(
      GroupId = allManagerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(null, Helpers.getLocations(SalesOrderType.repair));
    }
  }

  @isTest
  static void testGetLocationsForNestedPbgServiceManager() {
    User locationUser = createLocationUser('nestedpb', 'Worth Ave');
    Group serviceManagerGroup = getOrCreateGroup(
      'Service Manager - PBG',
      'Service_Manager_PBG'
    );
    Group pbgManagerGroup = getOrCreateGroup(
      'Managers - Palm Beach Gardens',
      'Managers_Palm_Beach_Gardens'
    );

    ensureGroupMembership(serviceManagerGroup.Id, pbgManagerGroup.Id);
    insert new GroupMember(
      GroupId = pbgManagerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(
        new Set<String>{ 'Palm Beach Gardens' },
        Helpers.getLocations(SalesOrderType.repair)
      );
    }
  }

  @isTest
  static void testGetLocationsForAllManager() {
    User locationUser = createLocationUser('allonly', 'Worth Ave');
    Group managerGroup = getOrCreateGroup('Managers - All', 'Managers_All');

    insert new GroupMember(
      GroupId = managerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(null, Helpers.getLocations(SalesOrderType.repair));
      System.assertEquals(null, Helpers.getLocations(SalesOrderType.special));
    }
  }

  @isTest
  static void testGetLocationsForRolexLiason() {
    User locationUser = createLocationUser('rolex', 'Worth Ave');
    Group managerGroup = getOrCreateGroup('Rolex Liason', 'Rolex_Liason');

    insert new GroupMember(
      GroupId = managerGroup.Id,
      UserOrGroupId = locationUser.Id
    );

    System.runAs(locationUser) {
      System.assertEquals(null, Helpers.getLocations(SalesOrderType.special));
    }
  }

  private static User createLocationUser(String alias, String location) {
    User locationUser = new User(
      Alias = alias,
      Email = alias + '@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Helpers Location',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      Location__c = location,
      ProfileId = UserInfo.getProfileId(),
      TimeZoneSidKey = 'America/New_York',
      UserName = alias + '-' + DateTime.now().getTime() + '@example.com'
    );
    insert locationUser;

    return locationUser;
  }

  private static Group getOrCreateGroup(String name, String developerName) {
    List<Group> groups = [
      SELECT Id
      FROM Group
      WHERE DeveloperName = :developerName AND Type = 'Regular'
      LIMIT 1
    ];

    if (!groups.isEmpty()) {
      return groups[0];
    }

    Group newGroup = new Group(
      Name = name,
      DeveloperName = developerName,
      Type = 'Regular'
    );
    insert newGroup;

    return newGroup;
  }

  private static void ensureGroupMembership(Id parentGroupId, Id childGroupId) {
    if (
      [
        SELECT COUNT()
        FROM GroupMember
        WHERE GroupId = :parentGroupId AND UserOrGroupId = :childGroupId
      ] == 0
    ) {
      insert new GroupMember(
        GroupId = parentGroupId,
        UserOrGroupId = childGroupId
      );
    }
  }
}
