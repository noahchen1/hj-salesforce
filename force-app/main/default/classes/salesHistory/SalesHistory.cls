public with sharing class SalesHistory {
  public class LineDetails {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String tranNumber;
    @AuraEnabled
    public String customer;
    @AuraEnabled
    public String salesRep;
    @AuraEnabled
    public String item;
    @AuraEnabled
    public Decimal quantity;
    @AuraEnabled
    public Decimal amount;
    @AuraEnabled
    public String preferredVendor;
    @AuraEnabled
    public String location;
    @AuraEnabled
    public String department;
    @AuraEnabled
    public String division;
    @AuraEnabled
    public Date birthday;
    @AuraEnabled
    public Date anniversary;
    @AuraEnabled
    public String leadsource;
    @AuraEnabled
    public Boolean isNewCustomer;
    @AuraEnabled
    public Boolean isServiceOnly;
    @AuraEnabled
    public String ranking;
  }

  @AuraEnabled(cacheable=true)
  public static List<LineDetails> getSalesHistory(
    String customer,
    Integer limitSize,
    Integer offsetSize
  ) {
    String nsQuery =
      'SELECT ' +
      'breadwinner_ns__Transaction_Type__c, ' +
      'breadwinner_ns__Item__r.Name, ' +
      'breadwinner_ns__Quantity__c, ' +
      'breadwinner_ns__Amount__c, ' +
      'breadwinner_ns__Item__r.ncf_item9__c, ' +
      'breadwinner_ns__LocationName__c, ' +
      'breadwinner_ns__ClassName__c, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__DepartmentName__c, ' +
      'breadwinner_ns__Invoice__r.Name, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.Name, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.ncf_entity_anniversary__c, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.ncf_entity_birthdate__c, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.ncf_entity_hamiltonleadsource__c, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.ncf_entity2__c, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.ncf_entity_is_new_customer__c, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.ncf_entity_is_service_only__c, ' +
      'breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r.breadwinner_ns__SalesRepName__c, ' +
      'breadwinner_ns__Credit_Memo__r.Name, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.Name, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.ncf_entity_anniversary__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.ncf_entity_birthdate__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.ncf_entity_hamiltonleadsource__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.ncf_entity2__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.ncf_entity_is_new_customer__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.ncf_entity_is_service_only__c, ' +
      'breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r.breadwinner_ns__SalesRepName__c ' +
      'FROM breadwinner_ns__BW_Line_Item__c ' +
      'WHERE breadwinner_ns__Transaction_Type__c IN (\'Invoice\', \'CreditMemo\') ';

    if (String.isNotBlank(customer)) {
      nsQuery += ' AND breadwinner_ns__ParentCompanyIDName__c = :customer';
    }

    // query += ' ORDER BY ' + sortField + ' ' + direction + ' NULLS LAST';
    nsQuery += ' LIMIT :limitSize OFFSET :offsetSize';

    try {
      List<breadwinner_ns__BW_Line_Item__c> lines = Database.query(nsQuery);

      List<LineDetails> results = new List<LineDetails>();

      for (breadwinner_ns__BW_Line_Item__c r : lines) {
        LineDetails row = new LineDetails();
        row.id = r.Id;
        row.item = r.breadwinner_ns__Item__r != null
          ? r.breadwinner_ns__Item__r.Name
          : null;
        row.quantity = r.breadwinner_ns__Quantity__c;
        row.amount = r.breadwinner_ns__Amount__c;
        row.preferredVendor = r.breadwinner_ns__Item__r != null
          ? r.breadwinner_ns__Item__r.ncf_item9__c
          : null;
        row.location = r.breadwinner_ns__LocationName__c;
        row.division = r.breadwinner_ns__ClassName__c;
        row.department = r.breadwinner_ns__Item__r != null
          ? r.breadwinner_ns__Item__r.breadwinner_ns__DepartmentName__c
          : null;

        SObject tran = r.breadwinner_ns__Invoice__r != null
          ? (SObject) r.breadwinner_ns__Invoice__r
          : (SObject) r.breadwinner_ns__Credit_Memo__r;

        SObject entity = (r.breadwinner_ns__Invoice__r != null &&
          r.breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r != null)
          ? (SObject) r.breadwinner_ns__Invoice__r.breadwinner_ns__Entity__r
          : (r.breadwinner_ns__Credit_Memo__r != null
              ? (SObject) r.breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__r
              : null);

        row.tranNumber = (String) tran?.get('Name');
        row.customer = (String) entity?.get('Name');
        row.salesRep = (String) entity?.get('breadwinner_ns__SalesRepName__c');
        row.anniversary = (Date) entity?.get('ncf_entity_anniversary__c');
        row.birthday = (Date) entity?.get('ncf_entity_birthdate__c');
        row.leadsource = (String) entity
          ?.get('ncf_entity_hamiltonleadsource__c');

        row.isNewCustomer = (Boolean) entity
          ?.get('ncf_entity_is_new_customer__c');
        row.isServiceOnly = (Boolean) entity
          ?.get('ncf_entity_is_service_only__c');
        row.ranking = (String) entity?.get('ncf_entity2__c');

        results.add(row);
      }

      System.debug('results: ' + results);
      return results;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
