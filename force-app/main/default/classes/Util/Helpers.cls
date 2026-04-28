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
    Script_Log__c newLog = new Script_Log__c(
      Title__c = title,
      Details__c = details,
      Timestamp__c = Datetime.now()
    );

    insert newLog;
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

    // Matches lightning-input type="date" expected format
    return asUtc.formatGmt('yyyy-MM-dd');
  }

  public static Long toUnixSeconds(Date sourceDate) {
    DateTime asDateTime = DateTime.newInstance(
      sourceDate,
      Time.newInstance(0, 0, 0, 0)
    );

    return asDateTime.getTime() / 1000;
  }
}
