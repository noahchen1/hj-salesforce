@isTest
private class AddUserTest {
  private class PayloadFixture {
    AddUser.Payload payload;
    String username;
  }

  private static PayloadFixture buildPayloadFixture(
    String profileName,
    String roleName,
    String suffix
  ) {
    String uniquePart = String.valueOf(Datetime.now().getTime()) + suffix;
    String username = 'adduser.' + uniquePart + '@example.com';

    PayloadFixture fixture = new PayloadFixture();
    fixture.payload = new AddUser.Payload();
    fixture.payload.FirstName = 'Test';
    fixture.payload.LastName = 'User';
    fixture.payload.Alias = 'tuser';
    fixture.payload.Email = 'adduser+' + uniquePart + '@example.com';
    fixture.payload.Username = username;
    fixture.payload.Title = 'Sales Associate';
    fixture.payload.Profile = profileName;
    fixture.payload.UserRole = roleName;
    fixture.payload.IsActive = true;
    fixture.payload.UserPermissionsInteractionUser = false;
    fixture.username = username;

    return fixture;
  }

  @isTest
  static void addUser_nullPayload_noRecordsInserted() {
    Integer beforeCount = [SELECT COUNT() FROM User];

    Test.startTest();
    AddUser.addNewUser(null);
    Test.stopTest();

    Integer afterCount = [SELECT COUNT() FROM User];
    System.assertEquals(
      beforeCount,
      afterCount,
      'Null payload should not insert users.'
    );
  }

  @isTest
  static void addUser_invalidProfileOrRole_doesNotInsertUser() {
    PayloadFixture fixture = buildPayloadFixture(
      'Missing Profile',
      'Missing Role',
      'invalid'
    );

    Test.startTest();
    AddUser.addNewUser(fixture.payload);
    Test.stopTest();

    Integer userCount = [
      SELECT COUNT()
      FROM User
      WHERE Username = :fixture.username
    ];
    System.assertEquals(
      0,
      userCount,
      'User should not be created when profile or role is invalid.'
    );
  }

  @isTest
  static void addUser_validPayload_insertsUser() {
    Profile currentProfile = [
      SELECT Id, Name
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      LIMIT 1
    ];
    UserRole role = new UserRole(
      Name = 'AUTestRole_' + String.valueOf(Datetime.now().getTime())
    );
    insert role;

    PayloadFixture fixture = buildPayloadFixture(
      currentProfile.Name,
      role.Name,
      'valid'
    );

    Test.startTest();
    AddUser.addNewUser(fixture.payload);
    Test.stopTest();

    User insertedUser = [
      SELECT Id, Username, ProfileId, UserRoleId, IsActive
      FROM User
      WHERE Username = :fixture.username
      LIMIT 1
    ];

    System.assertNotEquals(
      null,
      insertedUser.Id,
      'Expected a user to be created.'
    );
    System.assertEquals(
      currentProfile.Id,
      insertedUser.ProfileId,
      'Profile should match payload profile.'
    );
    System.assertEquals(
      role.Id,
      insertedUser.UserRoleId,
      'Role should match payload role.'
    );
    System.assertEquals(
      true,
      insertedUser.IsActive,
      'Inserted user should be active.'
    );
  }
}
