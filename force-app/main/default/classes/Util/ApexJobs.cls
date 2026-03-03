public with sharing class ApexJobs {
  @AuraEnabled
  public static Map<String, Object> checkJobStatus(String jobId) {
    try {
      AsyncApexJob job = [
        SELECT
          Id,
          Status,
          NumberOfErrors,
          JobItemsProcessed,
          TotalJobItems,
          CreatedDate,
          CompletedDate,
          ExtendedStatus
        FROM AsyncApexJob
        WHERE Id = :jobId
        LIMIT 1
      ];

      return new Map<String, Object>{
        'status' => job.Status,
        'processed' => job.JobItemsProcessed,
        'total' => job.TotalJobItems,
        'errors' => job.NumberOfErrors,
        'extendedStatus' => job.ExtendedStatus,
        'completedDate' => job.CompletedDate
      };
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error checking job status: ' + e.getMessage()
      );
    }
  }
}
