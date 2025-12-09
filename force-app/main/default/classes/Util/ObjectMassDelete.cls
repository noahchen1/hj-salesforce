public class ObjectMassDelete implements Database.Batchable<SObject> {
  private String objectApiName;

  public ObjectMassDelete(String objectApiName) {
    this.objectApiName = objectApiName;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    String query = 'SELECT Id FROM ' + objectApiName;
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    delete scope;
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('Mass delete completed!');
  }
}
