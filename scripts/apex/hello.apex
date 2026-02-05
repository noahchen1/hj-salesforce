Id nsJobId = Database.executeBatch(new NsSalesHistoryBatch(), 200);
System.debug('nsJobId: ' + nsJobId);
Id ascJobId = Database.executeBatch(new AscSalesHistoryBatch(), 200);
System.debug('ascJobId: ' + ascJobId);

Id deleteJobId = Database.executeBatch(new ObjectMassDelete('Sales_History__c'), 200);
System.debug('deleteJobId: ' + deleteJobId);


AsyncApexJob job = [
  SELECT
    Id,
    Status,
    JobType,
    NumberOfErrors,
    TotalJobItems,
    JobItemsProcessed,
    CreatedDate
  FROM AsyncApexJob
  WHERE Id = :nsJobId
];

System.debug(job);
