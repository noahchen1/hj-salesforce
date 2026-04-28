public with sharing class SalesOrderValidator {
  public static void validateParams(
    String customer,
    Date orderDate,
    String salesRep1,
    String subsidiary,
    String location,
    String lineItemsJson
  ) {
    if (
      String.isBlank(customer) ||
      orderDate == null ||
      String.isBlank(salesRep1) ||
      String.isBlank(subsidiary) ||
      String.isBlank(location) ||
      String.isBlank(lineItemsJson)
    ) {
      throw new AuraHandledException('Missing required parameters.');
    }

    List<SalesOrderDataModel.LineItem> items = SalesOrderMapper.deserializeLineItems(
      lineItemsJson
    );

    if (items == null || items.isEmpty()) {
      throw new AuraHandledException('At least one line item is required.');
    }

    Boolean hasValidItem = false;

    for (SalesOrderDataModel.LineItem item : items) {
      if (item != null && !String.isBlank(item.item)) {
        hasValidItem = true;
        break;
      }
    }

    if (!hasValidItem) {
      throw new AuraHandledException(
        'At least one valid line item is required.'
      );
    }
  }
}