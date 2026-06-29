public with sharing class SalesOrderDataModel {
  public class SalesOrderData {
    @AuraEnabled
    public String orderType;
    @AuraEnabled
    public String soNsInternalId;
    @AuraEnabled
    public Id nsCompanyId;
    @AuraEnabled
    public String customerName;
    @AuraEnabled
    public Id accountId;
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
    public String termNsId;
    @AuraEnabled
    public String memo;
    @AuraEnabled
    public String specialOrderStatus;
    @AuraEnabled
    public String specialDate;
    @AuraEnabled
    public String needByDate;
    @AuraEnabled
    public String specialOrderItemType;
    @AuraEnabled
    public String specialOrderVendorName;
    @AuraEnabled
    public String specialOrderVendorNsId;
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
    public String repairPersonName;
    @AuraEnabled
    public String repairLocation;
    @AuraEnabled
    public String repairVendor;
    @AuraEnabled
    public String repairVendorName;
    @AuraEnabled
    public String shipRepairTo;
    @AuraEnabled
    public String shipRepairToName;
    @AuraEnabled
    public String repairDescription;
    @AuraEnabled
    public String extendedDescription;
    @AuraEnabled
    public String dateOpened;
    @AuraEnabled
    public String datePromised;
    @AuraEnabled
    public String attachmentUrls;

    @AuraEnabled
    public String inquiryModel;
    @AuraEnabled
    public String inquiryName;
    @AuraEnabled
    public String inquiryLink;
    @AuraEnabled
    public Boolean inquiryIsPrority;
    @AuraEnabled
    public Boolean inquiryIsOpenDial;
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
    public String specialOrderItem;
    @AuraEnabled
    public String specialOrderVendorNum;
    @AuraEnabled
    public String imageUrl;
    @AuraEnabled
    public String quantity;
    @AuraEnabled
    public String rate;
    @AuraEnabled
    public String amount;
    @AuraEnabled
    public String quotedPrice;
    @AuraEnabled
    public String line;
    @AuraEnabled
    public String quantityAvailable;
    @AuraEnabled
    public String quantityBackOrdered;
    @AuraEnabled
    public String displayName;
    @AuraEnabled
    public String itemType;
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
