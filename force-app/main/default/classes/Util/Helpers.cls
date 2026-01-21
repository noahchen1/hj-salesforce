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
}
