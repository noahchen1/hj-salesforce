public with sharing class SalesHistory {
  @AuraEnabled(cacheable=true)
  public static List<AggregateResult> getSalesHistory(
    String customer,
    String salesRep,
    String item,
    String division,
    String department,
    String groupcode,
    Integer pageSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
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

    List<AggregateResult> results = Database.query(query);

    return results;
  }
}
