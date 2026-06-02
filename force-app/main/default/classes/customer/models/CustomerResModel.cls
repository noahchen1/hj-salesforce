public with sharing class CustomerResModel {
  public class ResponseJson {
    public String status;
    public List<ErrorDetail> errors;
    public List<Customer> customers;

    public ResponseJson() {
    }
  }

  public class ErrorDetail {
    public String code;
    public String message;
    public String detail;
    public String field;
    public String type;

    public ErrorDetail() {
    }
  }

  public class customer {
    public String internalId;
    public AddressBookList addressbookList;

    public customer() {
    }
  }

  public class AddressBookList {
    @AuraEnabled
    public List<AddressBookItem> addressbook;
  }

  public class AddressBookItem {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean isResidential;
    @AuraEnabled
    public String internalId;
    @AuraEnabled
    public Boolean defaultShipping;
    @AuraEnabled
    public Boolean defaultBilling;
    @AuraEnabled
    public AddressBookAddress addressbookAddress;
  }

  public class AddressBookAddress {
    @AuraEnabled
    public String zip;
    @AuraEnabled
    public String state;
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
  }
}
