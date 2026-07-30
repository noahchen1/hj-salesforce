public with sharing class Helpers {
  public static String getFirstNonEmptyString(List<String> stringList) {
    if (stringList == null || stringList.isEmpty())
      return null;

    for (String s : stringList) {
      if (String.isNotBlank(s))
        return s;
    }

    return null;
  }

  public static void writeLog(String title, String details) {
    try {
      Script_Log__c newLog = new Script_Log__c(
        Title__c = title,
        Details__c = details,
        Timestamp__c = Datetime.now()
      );

      insert newLog;
    } catch (Exception logErr) {
      System.debug(
        LoggingLevel.WARN,
        'Helpers.writeLog failed: ' + logErr.getMessage()
      );
    }
  }

  public static Boolean valuesEqual(Object a, Object b) {
    if (a == b)
      return true;
    if (a == null || b == null)
      return false;

    return String.valueOf(a).equals(String.valueOf(b));
  }

  public static Integer toIntOrNull(String s) {
    if (String.isBlank(s))
      return null;
    try {
      return Integer.valueOf(s.trim());
    } catch (Exception e) {
      return null;
    }
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> getPicklistLabels(
    String objectName,
    String fieldName
  ) {
    Map<String, String> picklistMap = new Map<String, String>();

    try {
      Schema.SObjectType sObjectType = Schema.getGlobalDescribe()
        .get(objectName);
      Schema.DescribeFieldResult fieldResult = sObjectType.getDescribe()
        .fields.getMap()
        .get(fieldName)
        .getDescribe();

      for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        picklistMap.put(entry.getValue(), entry.getLabel());
      }
    } catch (Exception e) {
      System.debug('Error getting picklist labels: ' + e.getMessage());
    }

    return picklistMap;
  }

  public static String toDateOnlyFromUnixSeconds(Long unixSeconds) {
    if (unixSeconds == null) {
      return null;
    }

    DateTime epoch = DateTime.newInstanceGmt(1970, 1, 1, 0, 0, 0);
    DateTime asUtc = epoch.addSeconds(
      Integer.valueOf(String.valueOf(unixSeconds))
    );

    return asUtc.formatGmt('yyyy-MM-dd');
  }

  public static Long toUnixSeconds(Date sourceDate) {
    DateTime asDateTime = DateTime.newInstance(
      sourceDate,
      Time.newInstance(0, 0, 0, 0)
    );

    return asDateTime.getTime() / 1000;
  }

  public static AuraHandledException buildAuraException(String message) {
    AuraHandledException e = new AuraHandledException(message);
    e.setMessage(message);
    return e;
  }

  public static String normalizeString(String str) {
    return String.isBlank(str) ? null : str.trim().toLowerCase();
  }

  public static String getFileNameFromContentDisposition(
    String contentDisposition
  ) {
    if (String.isBlank(contentDisposition)) {
      return null;
    }

    Pattern p = Pattern.compile('filename="?([^";]+)"?');
    Matcher m = p.matcher(contentDisposition);

    if (m.find()) {
      return m.group(1);
    }

    return null;
  }

  public static String getTitleFromFileName(String fileName) {
    if (String.isBlank(fileName)) {
      return 'downloaded-file';
    }

    Integer dotIndex = fileName.lastIndexOf('.');

    if (dotIndex > 0) {
      return fileName.substring(0, dotIndex);
    }

    return fileName;
  }

  public static Set<String> getLocations(SalesOrderType type) {
    if (type != SalesOrderType.repair && type != SalesOrderType.special) {
      return null;
    }

    Id userId = UserInfo.getUserId();
    Set<String> relevantGroupNames = new Set<String>{
      'Managers_All',
      'Managers_New_Jersey',
      'Rolex_Liason'
    };

    if (type == SalesOrderType.repair) {
      relevantGroupNames.addAll(
        new Set<String>{ 'Service_Managers_NJ', 'Service_Manager_PBG' }
      );
    }

    Set<String> userGroupNames = getUserGroupNames(userId, relevantGroupNames);

    if (userGroupNames.contains('Managers_All')) {
      return null;
    }

    if (type == SalesOrderType.repair) {
      Set<String> serviceLocations = new Set<String>();

      if (userGroupNames.contains('Service_Managers_NJ')) {
        serviceLocations.addAll(
          new Set<String>{ 'H1912', 'Princeton', 'Hamilton Home' }
        );
      }

      if (userGroupNames.contains('Service_Manager_PBG')) {
        serviceLocations.add('Palm Beach Gardens');
      }

      if (!serviceLocations.isEmpty()) {
        return serviceLocations;
      }
    }

    if (userGroupNames.contains('Managers_New_Jersey')) {
      return new Set<String>{ 'H1912', 'Princeton', 'Hamilton Home' };
    }

    if (
      type == SalesOrderType.special && userGroupNames.contains('Rolex_Liason')
    ) {
      return null;
    }

    User currentUser = [
      SELECT Location__c
      FROM User
      WHERE Id = :userId
      LIMIT 1
    ];

    return new Set<String>{ currentUser.Location__c };
  }

  private static Set<String> getUserGroupNames(
    Id userId,
    Set<String> relevantGroupNames
  ) {
    Set<String> groupNames = new Set<String>();
    Set<Id> checkedMemberIds = new Set<Id>();
    Set<Id> memberIdsToCheck = new Set<Id>{ userId };

    while (!memberIdsToCheck.isEmpty()) {
      checkedMemberIds.addAll(memberIdsToCheck);
      Set<Id> parentGroupIds = new Set<Id>();

      for (GroupMember membership : [
        SELECT GroupId, Group.DeveloperName
        FROM GroupMember
        WHERE Group.Type = 'Regular' AND UserOrGroupId IN :memberIdsToCheck
      ]) {
        if (relevantGroupNames.contains(membership.Group.DeveloperName)) {
          groupNames.add(membership.Group.DeveloperName);
        }

        if (!checkedMemberIds.contains(membership.GroupId)) {
          parentGroupIds.add(membership.GroupId);
        }
      }

      memberIdsToCheck = parentGroupIds;
    }

    return groupNames;
  }
}
