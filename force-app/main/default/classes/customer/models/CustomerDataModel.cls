public with sharing class CustomerDataModel {
  public class CustomerData {
    @AuraEnabled
    public String custNsInternalId;
    @AuraEnabled
    public List<Address> Addresses;

    public CustomerData() {
    }
  }

  public class Address {
    @AuraEnabled
    public String zip;
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String internalId;
    @AuraEnabled
    public String country;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String attention;
    @AuraEnabled
    public String addressee;
    @AuraEnabled
    public String addr2;
    @AuraEnabled
    public String addr1;
    @AuraEnabled
    public Boolean defaultShipping;
    @AuraEnabled
    public Boolean defaultBilling;
  }
}
