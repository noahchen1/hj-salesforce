public with sharing class OpenRepairsController {
  @AuraEnabled(cacheable=true)
  public static List<breadwinner_ns__BW_Sales_Order__c> getOpenRepairs(
    String salesRep,
    String name,
    String station,
    Integer limitSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    try {
      Map<String, String> sortFieldMap = new Map<String, String>{
        'date' => 'breadwinner_ns__CreatedDate__c',
        'name' => 'Name',
        'total' => 'breadwinner_ns__Total__c',
        'station' => 'ncf_body_repair_station__c',
        'type' => 'ncf_body1__c',
        'daysOpen' => 'Days_Open__c',
        'customer' => 'breadwinner_ns__Entity__r.Name'
      };

      String sortField = sortFieldMap.containsKey(sortBy)
        ? sortFieldMap.get(sortBy)
        : 'breadwinner_ns__CreatedDate__c';

      String direction = String.isNotBlank(sortDirection) &&
        sortDirection.toLowerCase() == 'asc'
        ? 'ASC'
        : 'DESC';

      String query =
        'SELECT Id, breadwinner_ns__CreatedDate__c, Name, breadwinner_ns__Entity__r.Name, breadwinner_ns__Total__c, ' +
        'ncf_body_repair_station__c, ncf_body1__c, Days_Open__c, breadwinner_ns__Status__c, breadwinner_ns__InternalId__c ' +
        'FROM breadwinner_ns__BW_Sales_Order__c WHERE ncf_body_repair_order__c = TRUE';

      if (String.isNotBlank(name)) {
        query += ' AND breadwinner_ns__Entity__r.Name = :name';
      }

      if (String.isNotBlank(salesRep)) {
        query += ' AND breadwinner_ns__SalesRepName__c = :salesRep';
      }

      if (String.isNotBlank(station)) {
        query += ' AND ncf_body_repair_station__c = :station';
      }

      query += ' ORDER BY ' + sortField + ' ' + direction + ' NULLS LAST';
      query += ' LIMIT :limitSize OFFSET :offsetSize';

      return Database.query(query);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
