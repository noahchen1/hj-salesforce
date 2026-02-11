Id deleteJobId = Database.executeBatch(
  new ObjectMassDelete('Script_Log__c'),
  200
);
System.debug('deleteJobId: ' + deleteJobId);
