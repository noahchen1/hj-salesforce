public with sharing class SalesHistory {
  @AuraEnabled(cacheable=true)
  public static List<AggregateResult> getSalesHistory(
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
    Integer pageSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    System.debug('birthdayStartMonth: ' + birthdayStartMonth);
    System.debug('birthdayStartDay: ' + birthdayStartDay);
    System.debug('birthdayEndMonth: ' + birthdayEndMonth);
    System.debug('birthdayEndDay: ' + birthdayEndDay);

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
      whereParts.add('Account__r.Name = :customer ');
    }

    if (String.isNotBlank(salesRep)) {
      whereParts.add('Account__r.Sales_Rep__c = :salesrep ');
    }

    if (String.isNotBlank(item)) {
      whereParts.add('Item_Name__c = :item ');
    }

    if (String.isNotBlank(division)) {
      whereParts.add('Division__c = :division ');
    }

    if (String.isNotBlank(department)) {
      whereParts.add('Department__c = :department ');
    }

    if (String.isNotBlank(groupcode)) {
      whereParts.add('Group_Code__c = :groupcode ');
    }

    if (String.isNotBlank(vendor)) {
      whereParts.add('Vendor__c = :vendor ');
    }

    if (String.isNotBlank(vendorItemNum)) {
      whereParts.add('Vendor_Item_Number__c = :vendorItemNum ');
    }

    if (isServiceOnly == true) {
      whereParts.add('Account__r.Is_Service_Only__c = true ');
    }

    if (isNewCustomer == true) {
      whereParts.add('Account__r.Is_New_Customer__c = true ');
    }

    if (purchaseStartDate != null) {
      whereParts.add('Order_Date__c >= :purchaseStartDate ');
    }

    if (purchaseEndDate != null) {
      whereParts.add('Order_Date__c <= :purchaseEndDate ');
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
      'Account__r.Name customer, ' +
      'Account__r.First_Name__c first_name, ' +
      'Account__r.Last_Name__c last_name, ' +
      'Account__r.Email__c email, ' +
      'Account__r.Phone phone, ' +
      'Account__r.Mobile_Phone__c mobile, ' +
      'Account__r.BillingStreet street, ' +
      'Account__r.BillingCity city, ' +
      'Account__r.BillingState state, ' +
      'Account__r.BillingPostalCode zip, ' +
      'Account__r.BillingCountry country, ' +
      'Account__r.Subsidiary__r.Name subsidiary, ' +
      'Account__r.Sales_Rep__c sales_rep, ' +
      'Account__r.Birthdate__c birthday, ' +
      'Account__r.Anniversary__c anniversary, ' +
      'Account__r.Ranking__c ranking, ' +
      'Account__r.Is_New_Customer__c is_new_customer, ' +
      'Account__r.AccountSource account_source, ' +
      'MAX(Account__r.Lifetime_Spend_Number__c) lifetime_spend, ' +
      'SUM(Price_Paid__c) total_spend ' +
      'FROM Sales_History__c ';

    if (!whereParts.isEmpty()) {
      System.debug(
        'conditions: ' + ' WHERE ' + String.join(whereParts, ' AND ')
      );
      query += ' WHERE ' + String.join(whereParts, ' AND ');
    }

    query +=
      'GROUP BY ' +
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
      'Account__r.AccountSource ' +
      'ORDER BY ' +
      sortField +
      ' ' +
      direction +
      ' NULLS LAST ' +
      'LIMIT :pageSize OFFSET :offsetSize';

    System.debug('query: ' + query);

    List<AggregateResult> results = Database.query(query);

    return results;
  }
}
