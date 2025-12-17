public with sharing class OpenSpecialOrdersController {
  @AuraEnabled(cacheable=true)
  public static List<breadwinner_ns__BW_Line_Item__c> getOpenSpecialOrders(
    String salesRep,
    String customer,
    String vendor,
    String location,
    String status,
    String itemType,
    String vendornum,
    Boolean showActiveOrdersOnly,
    String comments,
    List<String> hideRolexOrTudor,
    Integer limitSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    try {
      Map<String, String> sortFieldMap = new Map<String, String>{
        'customer' => 'breadwinner_ns__Sales_Order__r.breadwinner_ns__Entity__r.Name',
        'specialDate' => 'breadwinner_ns__Sales_Order__r.ncf_body_special_date__c',
        'document' => 'breadwinner_ns__Sales_Order__r.Name',
        'needByDate' => 'breadwinner_ns__Sales_Order__r.ncf_body_special_order_date__c',
        'salesRep' => 'breadwinner_ns__Sales_Order__r.breadwinner_ns__SalesRepName__c',
        'status' => 'breadwinner_ns__Sales_Order__r.ncf_body_special_statuses__c',
        'notes' => 'breadwinner_ns__Sales_Order__r.ncf_body_special_comments__c',
        'sku' => 'ncf_col_special_sku__c',
        'vendorItemNum' => 'ncf_col_special_order_number__c',
        'quotedPrice' => 'ncf_col_special_quoted_price__c'
      };

      String sortField = sortFieldMap.containsKey(sortBy)
        ? sortFieldMap.get(sortBy)
        : 'breadwinner_ns__Sales_Order__r.ncf_body_special_order_date__c';

      String direction = (String.isNotBlank(sortDirection) &&
        sortDirection.toLowerCase() == 'asc')
        ? 'ASC'
        : 'DESC';

      String query =
        'SELECT ' +
        'breadwinner_ns__Sales_Order__r.Id, ' +
        'breadwinner_ns__Sales_Order__r.Name, ' +
        'breadwinner_ns__Sales_Order__r.breadwinner_ns__Entity__r.Name, ' +
        'breadwinner_ns__Sales_Order__r.ncf_body_special_date__c, ' +
        'breadwinner_ns__Sales_Order__r.ncf_body_special_order_date__c, ' +
        'breadwinner_ns__Sales_Order__r.breadwinner_ns__SalesRepName__c, ' +
        'breadwinner_ns__Sales_Order__r.ncf_body_special_statuses__c, ' +
        'breadwinner_ns__Sales_Order__r.ncf_body_special_comments__c, ' +
        'ncf_col_special_sku__c, ' +
        'ncf_col_special_quoted_price__c, ' +
        'ncf_col_special_order_number__c ' +
        'FROM ' +
        'breadwinner_ns__BW_Line_Item__c ' +
        'WHERE ' +
        'breadwinner_ns__Sales_Order__r.ncf_body_special_item_type__c != NULL ' +
        'AND breadwinner_ns__Sales_Order__r.ncf_body_special_statuses__c NOT IN (\'Order Complete\', \'Canceled\')';

      if (String.isNotBlank(salesRep)) {
        query += ' AND breadwinner_ns__Sales_Order__r.breadwinner_ns__SalesRepName__c = :salesRep';
      }

      if (String.isNotBlank(customer)) {
        query += ' AND breadwinner_ns__Sales_Order__r.breadwinner_ns__Entity__r.Name = :customer';
      }

      if (String.isNotBlank(vendor)) {
        query += ' AND breadwinner_ns__Item__r.ncf_item9__c = :vendor';
      }

      if (String.isNotBlank(location)) {
        query += ' AND breadwinner_ns__Sales_Order__r.breadwinner_ns__LocationName__c = :location';
      }

      if (String.isNotBlank(status)) {
        query += ' AND breadwinner_ns__Sales_Order__r.ncf_body_special_statuses__c = :status';
      }

      if (String.isNotBlank(itemType)) {
        query += ' AND breadwinner_ns__Sales_Order__r.ncf_body_special_item_type__c = :itemType';
      }

      if (String.isNotBlank(vendornum)) {
        String vendornumUpper = vendornum.toUpperCase();

        query += ' AND ncf_col_special_order_number__c = :vendornumUpper';
      }

      if (showActiveOrdersOnly == true) {
        query += ' AND breadwinner_ns__Sales_Order__r.ncf_body_special_statuses__c != \'Inactive\'';
      }

      if (!hideRolexOrTudor.isEmpty()) {
        query += ' AND breadwinner_ns__Item__r.ncf_item9__c NOT IN :hideRolexOrTudor';
      }

      query += ' ORDER BY ' + sortField + ' ' + direction + ' NULLS LAST';
      query += ' LIMIT :limitSize OFFSET :offsetSize';

      List<breadwinner_ns__BW_Line_Item__c> items = Database.query(query);

      if (String.isNotBlank(comments)) {
        List<breadwinner_ns__BW_Line_Item__c> filtered = new List<breadwinner_ns__BW_Line_Item__c>();

        for (breadwinner_ns__BW_Line_Item__c item : items) {
          String notes = item.breadwinner_ns__Sales_Order__r.ncf_body_special_comments__c;

          if (notes != null && notes.containsIgnoreCase(comments)) {
            filtered.add(item);
          }
        }

        return filtered;
      }

      return items;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
