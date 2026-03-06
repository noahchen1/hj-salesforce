public with sharing class SalesHistoryModels {
  public class FilterCriteria {
    @AuraEnabled
    public String customer;
    @AuraEnabled
    public List<String> locations;
    @AuraEnabled
    public String salesRep;
    @AuraEnabled
    public String item;
    @AuraEnabled
    public String division;
    @AuraEnabled
    public String department;
    @AuraEnabled
    public String groupcode;
    @AuraEnabled
    public Date purchaseStartDate;
    @AuraEnabled
    public Date purchaseEndDate;
    @AuraEnabled
    public String birthdayStartMonth;
    @AuraEnabled
    public String birthdayStartDay;
    @AuraEnabled
    public String birthdayEndMonth;
    @AuraEnabled
    public String birthdayEndDay;
    @AuraEnabled
    public String vendor;
    @AuraEnabled
    public String vendorItemNum;
    @AuraEnabled
    public Boolean isServiceOnly;
    @AuraEnabled
    public Boolean isNewCustomer;
    @AuraEnabled
    public Integer pageSize;
    @AuraEnabled
    public Integer offsetSize;
    @AuraEnabled
    public String sortBy;
    @AuraEnabled
    public String sortDirection;
  }
}
