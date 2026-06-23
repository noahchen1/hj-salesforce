public with sharing class SalesOrderParamModel {
  public class SalesOrderSaveParam {
    @AuraEnabled
    public String orderType;
    @AuraEnabled
    public String inquiryType;
    @AuraEnabled
    public String soNsInternalId;
    @AuraEnabled
    public String custNsInternalId;
    @AuraEnabled
    public Date orderDate;
    @AuraEnabled
    public String salesRep1;
    @AuraEnabled
    public String salesRep2;
    @AuraEnabled
    public String subsidiary;
    @AuraEnabled
    public String location;
    @AuraEnabled
    public String termsNsInternalId;
    @AuraEnabled
    public String memo;
    @AuraEnabled
    public Date specialDate;
    @AuraEnabled
    public Date needByDate;
    @AuraEnabled
    public String specialOrderItemType;
    @AuraEnabled
    public String specialOrderVendor;
    @AuraEnabled
    public String specialOrderRequestedVendor;
    @AuraEnabled
    public String specialOrderComments;
    @AuraEnabled
    public String specialOrderNotes;
    @AuraEnabled
    public String specialOrderMemoOrSold;
    @AuraEnabled
    public String repairType;
    @AuraEnabled
    public String repairStation;
    @AuraEnabled
    public String repairPerson;
    @AuraEnabled
    public String repairLocation;
    @AuraEnabled
    public String repairVendor;
    @AuraEnabled
    public String shipRepairTo;
    @AuraEnabled
    public String repairDescription;
    @AuraEnabled
    public String extendedDescription;
    @AuraEnabled
    public Date dateOpened;
    @AuraEnabled
    public Date datePromised;
    @AuraEnabled
    public String attachmentUrls;
    @AuraEnabled
    public String shippingAddressJson;
    @AuraEnabled
    public String billingAddressJson;
    @AuraEnabled
    public String inquiryId;
    @AuraEnabled
    public String inquiryModel;
    @AuraEnabled
    public String inquiryName;
    @AuraEnabled
    public String inquiryLink;
    @AuraEnabled
    public String inquiryPersonalMsg;
    @AuraEnabled
    public Boolean inquiryIsSendEmail;
    @AuraEnabled
    public Boolean inquiryIsPrority;
    @AuraEnabled
    public Boolean inquiryIsOpenDial;
    @AuraEnabled
    public String lineItemsJson;
    @AuraEnabled
    public String fileJson;
  }
}
