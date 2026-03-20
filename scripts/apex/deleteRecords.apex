Id deleteJobId = Database.executeBatch(
  new ObjectMassDelete('Sales_History__c'),
  200
);
System.debug('deleteJobId: ' + deleteJobId);
