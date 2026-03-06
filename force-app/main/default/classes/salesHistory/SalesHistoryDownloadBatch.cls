public with sharing class SalesHistoryDownloadBatch implements Database.Batchable<SObject>, Database.Stateful {
  private class AggregatedRow {
    public String name;
    public String firstName;
    public String lastName;
    public String email;
    public String phone;
    public String mobile;
    public String street;
    public String city;
    public String state;
    public String postal;
    public String country;
    public String subsidiary;
    public String salesRep;
    public Date birthdate;
    public Date anniversary;
    public String ranking;
    public Boolean isNewCustomer;
    public String accountSource;
    public Decimal lifetimeSpend;
    public Decimal totalSpend = 0;
  }

  public final SalesHistoryModels.FilterCriteria criteria;
  private Map<Id, AggregatedRow> results = new Map<Id, AggregatedRow>();
  private String csvContent;

  public SalesHistoryDownloadBatch(SalesHistoryModels.FilterCriteria criteria) {
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

    String query =
      'SELECT ' +
      'Account__r.Name, ' +
      'Account__r.First_Name__c, ' +
      'Account__r.Last_Name__c, ' +
      'Account__r.Email__c, ' +
      'Account__r.Phone, ' +
      'Account__r.Mobile_Phone__c, ' +
      'Account__r.BillingStreet, ' +
      'Account__r.BillingCity, ' +
      'Account__r.BillingState, ' +
      'Account__r.BillingPostalCode, ' +
      'Account__r.BillingCountry, ' +
      'Account__r.Subsidiary__r.Name, ' +
      'Account__r.Sales_Rep__c, ' +
      'Account__r.Birthdate__c, ' +
      'Account__r.Anniversary__c, ' +
      'Account__r.Ranking__c, ' +
      'Account__r.Is_New_Customer__c, ' +
      'Account__r.AccountSource, ' +
      'Account__r.Lifetime_Spend_Number__c, ' +
      'Price_Paid__c ' +
      'FROM Sales_History__c ';

    if (!whereParts.isEmpty()) {
      query += ' WHERE ' + String.join(whereParts, ' AND ');
    }

    // query += 'ORDER BY ' + sortField + ' ' + direction + ' NULLS LAST ';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<Sales_History__c> scope
  ) {
    for (Sales_History__c sh : scope) {
      if (sh.Account__c == null)
        continue;

      Id accId = sh.Account__c;

      if (!results.containsKey(accId)) {
        AggregatedRow row = new AggregatedRow();

        row.name = sh.Account__r.Name;
        row.firstName = sh.Account__r.First_Name__c;
        row.lastName = sh.Account__r.Last_Name__c;
        row.email = sh.Account__r.Email__c;
        row.phone = sh.Account__r.Phone;
        row.mobile = sh.Account__r.Mobile_Phone__c;
        row.street = sh.Account__r.BillingStreet;
        row.city = sh.Account__r.BillingCity;
        row.state = sh.Account__r.BillingState;
        row.postal = sh.Account__r.BillingPostalCode;
        row.country = sh.Account__r.BillingCountry;
        row.subsidiary = sh.Account__r.Subsidiary__r != null
          ? sh.Account__r.Subsidiary__r.Name
          : null;
        row.salesRep = sh.Account__r.Sales_Rep__c;
        row.birthdate = sh.Account__r.Birthdate__c;
        row.anniversary = sh.Account__r.Anniversary__c;
        row.ranking = sh.Account__r.Ranking__c;
        row.isNewCustomer = sh.Account__r.Is_New_Customer__c;
        row.accountSource = sh.Account__r.AccountSource;

        row.lifetimeSpend = sh.Account__r.Lifetime_Spend_Number__c;

        results.put(accId, row);
      }

      if (sh.Price_Paid__c != null) {
        results.get(accId).totalSpend += sh.Price_Paid__c;
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
    csvContent +=
      'Customer,First Name,Last Name,Email,Phone,Mobile,Street,City,State,Postal,Country,' +
      'Subsidiary,Sales Rep,Birthdate,Anniversary,Ranking,Is New Customer,Account Source,' +
      'Lifetime Spend,Total Spend\n';

    for (AggregatedRow row : results.values()) {
      csvContent +=
        escape(row.name) +
        ',' +
        escape(row.firstName) +
        ',' +
        escape(row.lastName) +
        ',' +
        escape(row.email) +
        ',' +
        escape(row.phone) +
        ',' +
        escape(row.mobile) +
        ',' +
        escape(row.street) +
        ',' +
        escape(row.city) +
        ',' +
        escape(row.state) +
        ',' +
        escape(row.postal) +
        ',' +
        escape(row.country) +
        ',' +
        escape(row.subsidiary) +
        ',' +
        escape(row.salesRep) +
        ',' +
        String.valueOf(row.birthdate) +
        ',' +
        String.valueOf(row.anniversary) +
        ',' +
        escape(row.ranking) +
        ',' +
        String.valueOf(row.isNewCustomer) +
        ',' +
        escape(row.accountSource) +
        ',' +
        String.valueOf(row.lifetimeSpend) +
        ',' +
        String.valueOf(row.totalSpend) +
        '\n';
    }

    ContentVersion cv = new ContentVersion();
    cv.Title = 'SalesHistoryExport.csv';
    cv.PathOnClient = 'SalesHistoryExport.csv';
    cv.VersionData = Blob.valueOf(csvContent);

    insert cv;

    Id requesterUserId = [
      SELECT CreatedById
      FROM AsyncApexJob
      WHERE Id = :bc.getJobId()
      LIMIT 1
    ]
    .CreatedById;

    ContentVersion insertedCv = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ];

    try {
      sendExportReadyNotification(
        requesterUserId,
        insertedCv.ContentDocumentId
      );
    } catch (Exception e) {
      System.debug('Notification failed: ' + e.getMessage());
    }
  }

  private String escape(String input) {
    if (input == null)
      return '';
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      input = '"' + input.replace('"', '""') + '"';
    }
    return input;
  }

  private void sendExportReadyNotification(Id userId, Id contentDocumentId) {
    CustomNotificationType cnt = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = 'Sales_History_Export'
      LIMIT 1
    ];

    Messaging.CustomNotification n = new Messaging.CustomNotification();
    n.setNotificationTypeId(cnt.Id);
    n.setTitle('Sales History Export Ready');
    n.setBody('Your SalesHistoryExport.csv file is ready to download.');
    if (contentDocumentId != null) {
      n.setTargetId(contentDocumentId);
    }

    n.send(new Set<String>{ String.valueOf(userId) });
  }
}
