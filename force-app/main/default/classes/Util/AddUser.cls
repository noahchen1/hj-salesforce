public with sharing class AddUser {
  public class Payload {
    public String FirstName;
    public String MiddleName;
    public String LastName;
    public String Alias;
    public String Email;
    public String Username;
    public String Title;
    public String Profile;
    public String UserRole;
    public String TimeZoneSidKey = 'America/New_York';
    public String LocaleSidKey = 'en_US';
    public String LanguageLocaleKey = 'en_US';
    public String EmailEncodingKey = 'UTF-8';
    public Boolean IsActive;
    public Boolean UserPermissionsInteractionUser;
  }

  public static void addNewUser(Payload payload) {
    if (payload == null) {
      return;
    }

    List<Profile> profiles = [
      SELECT Id
      FROM Profile
      WHERE Name = :payload.Profile
      LIMIT 1
    ];

    List<UserRole> roles = [
      SELECT Id
      FROM UserRole
      WHERE Name = :payload.UserRole
      LIMIT 1
    ];

    if (profiles.isEmpty() || roles.isEmpty()) {
      System.debug('Invalid profile/role detected: ' + JSON.serialize(payload));

      return;
    }

    User user = new User(
      FirstName = payload.FirstName,
      MiddleName = payload.MiddleName,
      LastName = payload.LastName,
      Alias = payload.Alias,
      Email = payload.Email,
      Username = payload.Username,
      Title = payload.Title,
      ProfileId = profiles[0].Id,
      UserRoleId = roles[0].Id,
      TimeZoneSidKey = payload.timeZoneSidKey,
      LocaleSidKey = payload.localeSidKey,
      LanguageLocaleKey = payload.languageLocaleKey,
      EmailEncodingKey = payload.emailEncodingKey,
      IsActive = payload.IsActive,
      UserPermissionsInteractionUser = payload.UserPermissionsInteractionUser
    );

    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.EmailHeader.triggerUserEmail = true;
    user.setOptions(dmlOptions);

    insert user;

    List<PermissionSetLicense> pslChatList = [
      SELECT Id
      FROM PermissionSetLicense
      WHERE Id = '0PLa50000029YatGAE'
      LIMIT 1
    ];

    if (!pslChatList.isEmpty()) {
      insert new PermissionSetLicenseAssign(
        AssigneeId = user.Id,
        PermissionSetLicenseId = pslChatList[0].Id
      );
    }

    List<PermissionSetLicense> pslMsgList = [
      SELECT Id
      FROM PermissionSetLicense
      WHERE Id = '0PLa50000029YaxGAE'
      LIMIT 1
    ];

    if (!pslMsgList.isEmpty()) {
      insert new PermissionSetLicenseAssign(
        AssigneeId = user.Id,
        PermissionSetLicenseId = pslMsgList[0].Id
      );
    }

    List<PermissionSetGroup> psgs = [
      SELECT Id
      FROM PermissionSetGroup
      WHERE DeveloperName = 'Sales_Associate'
      LIMIT 1
    ];

    if (!psgs.isEmpty()) {
      insert new PermissionSetAssignment(
        AssigneeId = user.Id,
        PermissionSetGroupId = psgs[0].Id
      );
    }

    System.debug('User created: ' + user.Id);
  }
}
