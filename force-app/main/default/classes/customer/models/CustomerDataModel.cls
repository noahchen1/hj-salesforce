public with sharing class CustomerDataModel {
  public class CustomerData {
    @AuraEnabled
    public String custNsInternalId;

    public CustomerData() {}
  }
}
