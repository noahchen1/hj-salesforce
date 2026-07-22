/**
 * Quick, code-based report registry. Move definitions to Custom Metadata when
 * the report shapes stabilize.
 */
public with sharing class ReportDefinitions {
  public class Definition {
    @AuraEnabled public Boolean isActive = true;
    @AuraEnabled public String title;
    @AuraEnabled public String sourceObject;
    @AuraEnabled public String selectFieldsJson;
    @AuraEnabled public String baseFiltersJson;
    @AuraEnabled public String runtimeFiltersJson;
    @AuraEnabled public String sortFieldsJson;
    @AuraEnabled public String defaultSort;
    @AuraEnabled public String groupByFieldsJson;
    @AuraEnabled public String uiFiltersJson;
    @AuraEnabled public String columnsJson;
  }

  public static Definition get(String reportKey) {
    if (reportKey == 'Open_Repairs')
      return openRepairs();
    if (reportKey == 'Sales_History')
      return salesHistory();
    return null;
  }

  private static Definition openRepairs() {
    Definition report = new Definition();
    report.title = 'Open Repairs';
    
    report.sourceObject = 'breadwinner_ns__BW_Sales_Order__c';
    report.selectFieldsJson = '["Id","Name","breadwinner_ns__CreatedDate__c","breadwinner_ns__Entity__r.Name","breadwinner_ns__Total__c","ncf_body_repair_station__c","ncf_body1__c","Days_Open__c","breadwinner_ns__InternalId__c"]';
    report.baseFiltersJson = '[{"field":"ncf_body_repair_order__c","operator":"=","value":true},{"field":"breadwinner_ns__Status__c","operator":"NOT IN","value":["Closed","Billed","Cancelled"]}]';
    report.runtimeFiltersJson = '[{"key":"customer","field":"breadwinner_ns__Entity__r.Name","operator":"="},{"key":"salesRep","field":"breadwinner_ns__SalesRepName__c","operator":"="},{"key":"station","field":"ncf_body_repair_station__c","operator":"="}]';
    report.sortFieldsJson = '{"date":"breadwinner_ns__CreatedDate__c","name":"Name","total":"breadwinner_ns__Total__c","station":"ncf_body_repair_station__c","type":"ncf_body1__c","daysOpen":"Days_Open__c","customer":"breadwinner_ns__Entity__r.Name"}';
    report.defaultSort = 'breadwinner_ns__CreatedDate__c';
    report.uiFiltersJson = '[{"key":"salesRep","label":"Sales Rep","type":"lookup","lookupProvider":"salesRep","placeholder":"Enter Name"},{"key":"customer","label":"Customer","type":"lookup","lookupProvider":"customer","placeholder":"Enter Name"},{"key":"station","label":"Repair Station","type":"lookup","lookupProvider":"repairStation","placeholder":"Enter Name"}]';
    report.columnsJson = '[{"label":"Date","fieldName":"date","source":"breadwinner_ns__CreatedDate__c","type":"date-local","sortable":true},{"label":"Document","fieldName":"document","type":"url","urlTemplate":"https://5405357.app.netsuite.com/app/accounting/transactions/salesord.nl?id={{breadwinner_ns__InternalId__c}}","labelSource":"Name"},{"label":"Customer","fieldName":"customer","source":"breadwinner_ns__Entity__r.Name","sortable":true},{"label":"Total","fieldName":"total","source":"breadwinner_ns__Total__c","type":"currency","sortable":true},{"label":"Repair Station","fieldName":"station","source":"ncf_body_repair_station__c","sortable":true},{"label":"Repair Type","fieldName":"type","source":"ncf_body1__c","sortable":true},{"label":"Days Open","fieldName":"daysOpen","source":"Days_Open__c","type":"number","sortable":true}]';

    return report;
  }

  private static Definition salesHistory() {
    Definition report = new Definition();
    report.title = 'Transaction History';
    report.sourceObject = 'Sales_History__c';
    report.selectFieldsJson = '["Account__r.Name customer","Account__r.Birthdate__c birthday","SUM(Price_Paid__c) total_spend"]';
    report.runtimeFiltersJson = '[{"key":"customer","field":"Account__r.Name","operator":"="},{"key":"salesRep","field":"Account__r.Sales_Rep__c","operator":"="},{"key":"purchaseStartDate","field":"Order_Date__c","operator":">=","valueType":"Date"},{"key":"purchaseEndDate","field":"Order_Date__c","operator":"<=","valueType":"Date"}]';
    report.sortFieldsJson = '{"totalSpend":"SUM(Price_Paid__c)","birthday":"Account__r.Birthdate__c"}';
    report.defaultSort = 'SUM(Price_Paid__c)';
    report.groupByFieldsJson = '["Account__r.Name","Account__r.Birthdate__c"]';
    report.columnsJson = '[{"label":"Customer","fieldName":"customer","source":"customer","sortable":true},{"label":"Birthday","fieldName":"birthday","source":"birthday","type":"date-local","sortable":true},{"label":"Total Spend","fieldName":"totalSpend","source":"total_spend","type":"currency","sortable":true}]';
    return report;
  }
}
