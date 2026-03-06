public with sharing class SalesHistoryAddToCampaignBatch implements Database.Batchable<SObject> {
  private final Id campaignId;
  private final SalesHistoryModels.FilterCriteria criteria;

  public SalesHistoryAddToCampaignBatch(
    Id campaignId,
    SalesHistoryModels.FilterCriteria criteria
  ) {
    this.campaignId = campaignId;
    this.criteria = criteria;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    String customer = criteria?.customer;
    List<String> locations = (criteria?.locations == null)
      ? new List<String>()
      : criteria.locations;
    String salesRep = criteria?.salesRep;
    String item = criteria?.item;
    String division = criteria?.division;
    String department = criteria?.department;
    String groupcode = criteria?.groupcode;
    Date purchaseStartDate = criteria?.purchaseStartDate;
    Date purchaseEndDate = criteria?.purchaseEndDate;
    String birthdayStartMonth = criteria?.birthdayStartMonth;
    String birthdayStartDay = criteria?.birthdayStartDay;
    String birthdayEndMonth = criteria?.birthdayEndMonth;
    String birthdayEndDay = criteria?.birthdayEndDay;
    String vendor = criteria?.vendor;
    String vendorItemNum = criteria?.vendorItemNum;
    Boolean isServiceOnly = (criteria?.isServiceOnly == true);
    Boolean isNewCustomer = (criteria?.isNewCustomer == true);
    Integer pageSize = criteria?.pageSize;
    Integer offsetSize = criteria?.offsetSize;
    String sortBy = criteria?.sortBy;
    String sortDirection = criteria?.sortDirection;

    Map<String, String> sortMap = new Map<String, String>{
      'totalSpend' => 'SUM(Price_Paid__c)',
      'birthday' => 'Account__r.Birthdate__c'
    };

    String sortField = sortMap.containsKey(sortBy)
      ? sortMap.get(sortBy)
      : 'SUM(Price_Paid__c)';

    String direction = (String.isNotBlank(sortDirection) &&
      sortDirection.toLowerCase() == 'asc')
      ? 'ASC'
      : 'DESC';

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
      String.isNotEmpty(birthdayStartMonth) ||
      String.isNotEmpty(birthdayEndMonth) ||
      String.isNotEmpty(birthdayStartDay) ||
      String.isNotEmpty(birthdayEndDay)
    ) {
      Integer bdStartMonth = Helpers.toIntOrNull(birthdayStartMonth);
      Integer bdEndMonth = Helpers.toIntOrNull(birthdayEndMonth);
      Integer bdStartDay = Helpers.toIntOrNull(birthdayStartDay);
      Integer bdEndDay = Helpers.toIntOrNull(birthdayEndDay);

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
      Database.SaveResult[] results = Database.insert(toInsert, false);

      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error err : result.getErrors()) {
            Map<String, Object> errMap = new Map<String, Object>{
              'objectId' => result.getId(),
              'message' => err.getMessage(),
              'affected fields' => err.getFields()
            };

            Helpers.writeLog(
              'Sales History Add To Campaign Error',
              JSON.serialize(errMap)
            );
          }
        }
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
  }
}
