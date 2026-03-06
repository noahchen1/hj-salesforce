public with sharing class SalesHistoryController {
  @AuraEnabled(cacheable=true)
  public static List<AggregateResult> getSalesHistory(
    String customer,
    List<String> locations,
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
    Integer pageSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    SalesHistoryModels.FilterCriteria criteria = buildCriteria(
      customer,
      locations,
      salesRep,
      item,
      division,
      department,
      groupcode,
      purchaseStartDate,
      purchaseEndDate,
      birthdayStartMonth,
      birthdayStartDay,
      birthdayEndMonth,
      birthdayEndDay,
      vendor,
      vendorItemNum,
      isServiceOnly,
      isNewCustomer,
      pageSize,
      offsetSize,
      sortBy,
      sortDirection
    );

    return SalesHistoryService.querySalesHistory(criteria);
  }

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

    SalesHistoryModels.FilterCriteria criteria = buildCriteria(
      customer,
      null,
      salesRep,
      item,
      division,
      department,
      groupcode,
      purchaseStartDate,
      purchaseEndDate,
      birthdayStartMonth,
      birthdayStartDay,
      birthdayEndMonth,
      birthdayEndDay,
      vendor,
      vendorItemNum,
      isServiceOnly,
      isNewCustomer,
      null,
      null,
      sortBy,
      sortDirection
    );

    return Database.executeBatch(
      new SalesHistoryAddToCampaignBatch(campaignId, criteria),
      200
    );
  }

  @AuraEnabled
  public static Id generateCsv(
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
    SalesHistoryModels.FilterCriteria criteria = buildCriteria(
      customer,
      null,
      salesRep,
      item,
      division,
      department,
      groupcode,
      purchaseStartDate,
      purchaseEndDate,
      birthdayStartMonth,
      birthdayStartDay,
      birthdayEndMonth,
      birthdayEndDay,
      vendor,
      vendorItemNum,
      isServiceOnly,
      isNewCustomer,
      null,
      null,
      sortBy,
      sortDirection
    );

    return Database.executeBatch(new SalesHistoryDownloadBatch(criteria), 200);
  }

  private static SalesHistoryModels.FilterCriteria buildCriteria(
    String customer,
    List<String> locations,
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
    Integer pageSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    SalesHistoryModels.FilterCriteria criteria = new SalesHistoryModels.FilterCriteria();
    criteria.customer = customer;
    criteria.locations = locations;
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
    criteria.pageSize = pageSize;
    criteria.offsetSize = offsetSize;
    criteria.sortBy = sortBy;
    criteria.sortDirection = sortDirection;
    return criteria;
  }
}
