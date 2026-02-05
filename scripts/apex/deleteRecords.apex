Id deleteJobId = Database.executeBatch(
  new ObjectMassDelete(''),
  200
);
System.debug('deleteJobId: ' + deleteJobId);
