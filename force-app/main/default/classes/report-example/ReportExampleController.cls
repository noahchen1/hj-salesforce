public with sharing class ReportExampleController {
  @AuraEnabled(cacheable=true)
  public static List<Opportunity> getOps(String stage, Integer limitSize) {
    if (String.isBlank(stage))
      stage = 'Closed Won';
    if (limitSize == null || limitSize <= 0)
      limitSize = 200;

    return [
      SELECT Id, Name, Account.Name, Amount, CloseDate, Owner.Name, StageName
      FROM Opportunity
      WHERE StageName = :stage
      ORDER BY CloseDate DESC
      LIMIT :limitSize
    ];
  }

}
