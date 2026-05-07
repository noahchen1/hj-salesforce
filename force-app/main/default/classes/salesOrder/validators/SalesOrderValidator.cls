public with sharing class SalesOrderValidator {
  private static final Set<String> VENDOR_REQUIRED_ITEM_TYPES = new Set<String>{
    '1',
    '2',
    '4',
    '5',
    '6'
  };

  private static Boolean isVendorRequiredItemType(String specialOrderItemType) {
    return VENDOR_REQUIRED_ITEM_TYPES.contains(specialOrderItemType);
  }

  public static void validateParams(
    String orderType,
    String custNsInternalId,
    Date orderDate,
    String salesRep1,
    String subsidiary,
    String location,
    Date specialDate,
    Date needByDate,
    String specialOrderItemType,
    String specialOrderVendor,
    String specialOrderMemoOrSold,
    String lineItemsJson
  ) {
    Boolean isSalesOrder = orderType == 'sales';
    Boolean isSpecialOrder = orderType == 'special';

    if (!isSalesOrder && !isSpecialOrder) {
      return;
    }

    if (
      String.isBlank(custNsInternalId) ||
      orderDate == null ||
      String.isBlank(salesRep1) ||
      String.isBlank(subsidiary) ||
      String.isBlank(location) ||
      String.isBlank(lineItemsJson)
    ) {
      throw new AuraHandledException('Missing required parameters.');
    }

    if (
      isSpecialOrder &&
      (specialDate == null ||
      needByDate == null ||
      String.isBlank(specialOrderItemType) ||
      (isVendorRequiredItemType(specialOrderItemType) &&
      String.isBlank(specialOrderVendor)) ||
      String.isBlank(specialOrderMemoOrSold))
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
      if (
        item == null ||
        String.isBlank(item.item) ||
        String.isBlank(item.rate)
      ) {
        continue;
      }

      if (
        !isSpecialOrder ||
        (!String.isBlank(item.specialOrderVendorNum) &&
        !String.isBlank(item.specialOrderItem))
      ) {
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
