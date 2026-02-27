public with sharing class SalesHistoryCampaignController {
  @AuraEnabled
  public static Id enqueueAddAccountsToCampaign(
    Id campaignId,
    String customer,
    String salesRep,
    String item,
    String division,
    String department,
    String groupcode,
    Date purchaseStartDate,
    Date purchaseEndDate,
    String birthdayStartMonth,
    String birthdayStartDay,
    String birthdayEndMonth,
    String birthdayEndDay,
    String vendor,
    String vendorItemNum,
    Boolean isServiceOnly,
    Boolean isNewCustomer,
    String sortBy,
    String sortDirection
  ) {
    if (campaignId == null) {
      throw new AuraHandledException('Campaign Id is required.');
    }

    SalesHistoryAddToCampaignBatch.FilterCriteria criteria = new SalesHistoryAddToCampaignBatch.FilterCriteria();
    criteria.customer = customer;
    criteria.salesRep = salesRep;
    criteria.item = item;
    criteria.division = division;
    criteria.department = department;
    criteria.groupcode = groupcode;
    criteria.purchaseStartDate = purchaseStartDate;
    criteria.purchaseEndDate = purchaseEndDate;
    criteria.birthdayStartMonth = birthdayStartMonth;
    criteria.birthdayStartDay = birthdayStartDay;
    criteria.birthdayEndMonth = birthdayEndMonth;
    criteria.birthdayEndDay = birthdayEndDay;
    criteria.vendor = vendor;
    criteria.vendorItemNum = vendorItemNum;
    criteria.isServiceOnly = isServiceOnly;
    criteria.isNewCustomer = isNewCustomer;
    criteria.sortBy = sortBy;
    criteria.sortDirection = sortDirection;

    return Database.executeBatch(
      new SalesHistoryAddToCampaignBatch(campaignId, criteria),
      200
    );
  }
}
