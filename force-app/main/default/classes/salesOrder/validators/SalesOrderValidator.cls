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

  public static void validateRawResponse(Map<String, Object> response) {
    if (response == null) {
      throw new AuraHandledException('No response returned from NetSuite.');
    }

    Boolean validRequest = (Boolean) response.get('validRequest');
    if (validRequest == null || !validRequest) {
      throw new AuraHandledException(
        'Invalid request: NetSuite rejected the payload.'
      );
    }

    String responseJsonStr = (String) response.get('responseJSON');
    if (String.isBlank(responseJsonStr)) {
      throw new AuraHandledException(
        'NetSuite returned an empty response body.'
      );
    }
  }

  public static void validateTypedBody(
    SalesOrderResModel.ResponseJson response
  ) {
    if (response == null) {
      throw new AuraHandledException('Unable to parse NetSuite response.');
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      throw new AuraHandledException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );
    }

    if (response.status != '200') {
      throw new AuraHandledException(
        'Unexpected response status: ' + response.status
      );
    }

    if (response.salesOrders == null || response.salesOrders.isEmpty()) {
      throw new AuraHandledException('No sales order returned in response.');
    }
  }
}
