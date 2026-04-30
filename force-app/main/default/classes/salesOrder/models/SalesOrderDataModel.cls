public with sharing class SalesOrderDataModel {
  public class SalesOrderData {
    @AuraEnabled
    public String soNsInternalId;
    @AuraEnabled
    public Id nsCompanyId;
    @AuraEnabled
    public String customerName;
    @AuraEnabled
    public String customerNsId;
    @AuraEnabled
    public String orderDate;
    @AuraEnabled
    public String salesRep1Name;
    @AuraEnabled
    public String salesRep1NsId;
    @AuraEnabled
    public String salesRep2Name;
    @AuraEnabled
    public String salesRep2NsId;
    @AuraEnabled
    public String subsidiaryNsId;
    @AuraEnabled
    public String locationNsId;
    @AuraEnabled
    public String memo;
    @AuraEnabled
    public Address shippingAddress;
    @AuraEnabled
    public Address billingAddress;
    @AuraEnabled
    public List<LineItem> lineItems = new List<LineItem>();
  }

  public class LineItem {
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String item;
    @AuraEnabled
    public String itemName;
    @AuraEnabled
    public String quantity;
    @AuraEnabled
    public String rate;
    @AuraEnabled
    public String amount;
    @AuraEnabled
    public String line;
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
    public String addr1;
    @AuraEnabled
    public String addr2;
    @AuraEnabled
    public String addr3;
  }
}
