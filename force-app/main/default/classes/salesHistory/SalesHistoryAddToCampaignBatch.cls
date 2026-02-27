public with sharing class SalesHistoryAddToCampaignBatch implements Database.Batchable<SObject> {
  public class FilterCriteria {
    @AuraEnabled
    public String customer;
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
    public String sortBy;
    @AuraEnabled
    public String sortDirection;
  }

  private final Id campaignId;
  private final FilterCriteria criteria;

  public SalesHistoryAddToCampaignBatch(
    Id campaignId,
    FilterCriteria criteria
  ) {
    this.campaignId = campaignId;
    this.criteria = criteria;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Map<String, String> sortMap = new Map<String, String>{
      'totalSpend' => 'SUM(Price_Paid__c)',
      'birthday' => 'Account__r.Birthdate__c'
    };

    String sortField = sortMap.containsKey(criteria.sortBy)
      ? sortMap.get(criteria.sortBy)
      : 'SUM(Price_Paid__c)';

    String direction = (String.isNotBlank(criteria.sortDirection) &&
      criteria.sortDirection.toLowerCase() == 'asc')
      ? 'ASC'
      : 'DESC';

    String customer = criteria != null ? criteria.customer : null;
    String salesRep = criteria != null ? criteria.salesRep : null;
    String item = criteria != null ? criteria.item : null;
    String division = criteria != null ? criteria.division : null;
    String department = criteria != null ? criteria.department : null;
    String groupcode = criteria != null ? criteria.groupcode : null;
    String vendor = criteria != null ? criteria.vendor : null;
    String vendorItemNum = criteria != null ? criteria.vendorItemNum : null;
    Boolean isServiceOnly = criteria != null ? criteria.isServiceOnly : false;
    Boolean isNewCustomer = criteria != null ? criteria.isNewCustomer : false;
    Date purchaseStartDate = criteria != null
      ? criteria.purchaseStartDate
      : null;
    Date purchaseEndDate = criteria != null ? criteria.purchaseEndDate : null;

    List<String> whereParts = new List<String>();

    if (String.isNotBlank(customer)) {
      whereParts.add('Account__r.Name = :customer');
    }

    if (String.isNotBlank(salesRep)) {
      whereParts.add('Account__r.Sales_Rep__c = :salesRep');
    }

    if (String.isNotBlank(item)) {
      whereParts.add('Item_Name__c = :item');
    }

    if (String.isNotBlank(division)) {
      whereParts.add('Division__c = :division');
    }

    if (String.isNotBlank(department)) {
      whereParts.add('Department__c = :department');
    }

    if (String.isNotBlank(groupcode)) {
      whereParts.add('Group_Code__c = :groupcode');
    }

    if (String.isNotBlank(vendor)) {
      whereParts.add('Vendor__c = :vendor');
    }

    if (String.isNotBlank(vendorItemNum)) {
      whereParts.add('Vendor_Item_Number__c = :vendorItemNum');
    }

    if (isServiceOnly == true) {
      whereParts.add('Account__r.Is_Service_Only__c = true');
    }

    if (isNewCustomer == true) {
      whereParts.add('Account__r.Is_New_Customer__c = true');
    }

    if (purchaseStartDate != null) {
      whereParts.add('Order_Date__c >= :purchaseStartDate');
    }

    if (purchaseEndDate != null) {
      whereParts.add('Order_Date__c <= :purchaseEndDate');
    }

    if (
      String.isNotEmpty(criteria.birthdayStartMonth) ||
      String.isNotEmpty(criteria.birthdayEndMonth) ||
      String.isNotEmpty(criteria.birthdayStartDay) ||
      String.isNotEmpty(criteria.birthdayEndDay)
    ) {
      Integer bdStartMonth = Helpers.toIntOrNull(criteria.birthdayStartMonth);
      Integer bdEndMonth = Helpers.toIntOrNull(criteria.birthdayEndMonth);
      Integer bdStartDay = Helpers.toIntOrNull(criteria.birthdayStartDay);
      Integer bdEndDay = Helpers.toIntOrNull(criteria.birthdayEndDay);

      if (bdStartMonth == null) {
        bdStartDay = null;
      }

      if (bdEndMonth == null) {
        bdEndDay = null;
      }

      List<String> conditions = new List<String>();

      if (bdStartMonth != null && bdEndMonth == null) {
        if (bdStartDay != null) {
          conditions.add(
            '(CALENDAR_MONTH(Account__r.Birthdate__c) > :bdStartMonth ' +
              'OR (CALENDAR_MONTH(Account__r.Birthdate__c) = :bdStartMonth ' +
              'AND DAY_IN_MONTH(Account__r.Birthdate__c) >= :bdStartDay))'
          );
        } else {
          conditions.add(
            'CALENDAR_MONTH(Account__r.Birthdate__c) >= :bdStartMonth'
          );
        }
      } else if (bdEndMonth != null && bdStartMonth == null) {
        if (bdEndDay != null) {
          conditions.add(
            '(CALENDAR_MONTH(Account__r.Birthdate__c) < :bdEndMonth ' +
              'OR (CALENDAR_MONTH(Account__r.Birthdate__c) = :bdEndMonth ' +
              'AND DAY_IN_MONTH(Account__r.Birthdate__c) <= :bdEndDay))'
          );
        } else {
          conditions.add(
            'CALENDAR_MONTH(Account__r.Birthdate__c) <= :bdEndMonth'
          );
        }
      } else if (
        bdStartMonth != null &&
        bdEndMonth != null &&
        bdStartMonth <= bdEndMonth
      ) {
        if (bdStartMonth == bdEndMonth) {
          conditions.add(
            '(CALENDAR_MONTH(Account__r.Birthdate__c) = :bdStartMonth ' +
              (bdStartDay != null
                ? 'AND DAY_IN_MONTH(Account__r.Birthdate__c) >= :bdStartDay '
                : '') +
              (bdEndDay != null
                ? 'AND DAY_IN_MONTH(Account__r.Birthdate__c) <= :bdEndDay '
                : '') +
              ')'
          );
        } else {
          String startCondition =
            '(CALENDAR_MONTH(Account__r.Birthdate__c) = :bdStartMonth ' +
            (bdStartDay != null
              ? 'AND DAY_IN_MONTH(Account__r.Birthdate__c) >= :bdStartDay'
              : '') +
            ')';

          String endCondition =
            '(CALENDAR_MONTH(Account__r.Birthdate__c) = :bdEndMonth ' +
            (bdEndDay != null
              ? 'AND DAY_IN_MONTH(Account__r.Birthdate__c) <= :bdEndDay'
              : '') +
            ')';

          String middleCondition =
            '(CALENDAR_MONTH(Account__r.Birthdate__c) > :bdStartMonth ' +
            'AND CALENDAR_MONTH(Account__r.Birthdate__c) < :bdEndMonth)';

          conditions.add(
            '(' +
              startCondition +
              ' OR ' +
              middleCondition +
              ' OR ' +
              endCondition +
              ')'
          );
        }
      }

      if (!conditions.isEmpty()) {
        whereParts.add('(' + String.join(conditions, ' AND ') + ')');
      }
    }

    String query = 'SELECT ' + 'Account__r.Id ' + 'FROM Sales_History__c ';

    if (!whereParts.isEmpty()) {
      query += ' WHERE ' + String.join(whereParts, ' AND ');
    }

    System.debug('query str: ' + query);

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<Sales_History__c> scope
  ) {
    Set<Id> accountIds = new Set<Id>();

    for (Sales_History__c result : scope) {
      accountIds.add(result.Account__r.Id);
    }

    List<CampaignMember> toInsert = new List<CampaignMember>();

    for (Id id : accountIds) {
      CampaignMember newMember = new CampaignMember(
        CampaignId = campaignId,
        AccountId = id,
        Status = 'Notsent'
      );

      toInsert.add(newMember);
    }

    if (!toInsert.isEmpty()) {
      Helpers.writeLog('toInsert', JSON.serialize(toInsert));
      Database.insert(toInsert);
    }
  }

  public void finish(Database.BatchableContext bc) {
  }
}
