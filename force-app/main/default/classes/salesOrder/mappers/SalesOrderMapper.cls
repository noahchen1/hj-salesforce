public with sharing class SalesOrderMapper {
  public static List<SalesOrderDataModel.LineItem> deserializeLineItems(
    String lineItemsJson
  ) {
    try {
      return (List<SalesOrderDataModel.LineItem>) JSON.deserialize(
        lineItemsJson,
        List<SalesOrderDataModel.LineItem>.class
      );
    } catch (Exception e) {
      throw new AuraHandledException('Invalid line item payload.');
    }
  }
}