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
      AuraHandledException e = new AuraHandledException(
        'Missing required parameters.'
      );

      e.setMessage('Missing required parameters.');

      throw e;
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
      AuraHandledException e = new AuraHandledException(
        'Missing required special order parameters.'
      );

      e.setMessage('Missing required special order parameters.');

      throw e;
    }

    List<SalesOrderDataModel.LineItem> items = SalesOrderMapper.deserializeLineItems(
      lineItemsJson
    );

    if (items == null || items.isEmpty()) {
      AuraHandledException e = new AuraHandledException(
        'At least one line item is required.'
      );

      e.setMessage('At least one line item is required.');

      throw e;
    }

    for (Integer i = 0; i < items.size(); i++) {
      SalesOrderDataModel.LineItem item = items.get(i);

      Boolean isStoreDiscount = item.item == '186466'; //Store Discount

      if (item == null || String.isBlank(item.item)) {
        AuraHandledException e = new AuraHandledException(
          'Line item ' + (i + 1) + ': item is required.'
        );

        e.setMessage('Line item ' + (i + 1) + ': item is required.');

        throw e;
      }

      if (String.isBlank(item.rate)) {
        AuraHandledException e = new AuraHandledException(
          'Line item ' + (i + 1) + ': rate is required.'
        );

        e.setMessage('Line item ' + (i + 1) + ': rate is required.');

        throw e;
      }

      if (String.isBlank(item.amount)) {
        AuraHandledException e = new AuraHandledException(
          'Line item ' + (i + 1) + ': amount is required.'
        );

        e.setMessage('Line item ' + (i + 1) + ': amount is required.');

        throw e;
      }

      if (!isStoreDiscount && String.isBlank(item.quantity)) {
        AuraHandledException e = new AuraHandledException(
          'Line item ' + (i + 1) + ': quantity is required.'
        );

        e.setMessage('Line item ' + (i + 1) + ': quantity is required.');

        throw e;
      }

      if (
        !isStoreDiscount &&
        isSpecialOrder &&
        String.isBlank(item.quotedPrice)
      ) {
        AuraHandledException e = new AuraHandledException(
          'Line item ' +
            (i + 1) +
            ': quotedPrice is required for special orders.'
        );

        e.setMessage(
          'Line item ' +
            (i + 1) +
            ': quotedPrice is required for special orders.'
        );

        throw e;
      }
    }
  }

  public static void validateRawResponse(Map<String, Object> response) {
    if (response == null) {
      AuraHandledException e = new AuraHandledException(
        'No response returned from NetSuite.'
      );

      e.setMessage('No response returned from NetSuite.');

      throw e;
    }

    Boolean validRequest = (Boolean) response.get('validRequest');
    if (validRequest == null || !validRequest) {
      AuraHandledException e = new AuraHandledException(
        'Invalid request: NetSuite rejected the payload.'
      );

      e.setMessage('Invalid request: NetSuite rejected the payload.');

      throw e;
    }

    String responseJsonStr = (String) response.get('responseJSON');
    if (String.isBlank(responseJsonStr)) {
      AuraHandledException e = new AuraHandledException(
        'NetSuite returned an empty response body.'
      );

      e.setMessage('NetSuite returned an empty response body.');

      throw e;
    }
  }

  public static void validateTypedBody(
    SalesOrderResModel.ResponseJson response
  ) {
    if (response == null) {
      AuraHandledException e = new AuraHandledException(
        'Unable to parse NetSuite response.'
      );

      e.setMessage('Unable to parse NetSuite response.');

      throw e;
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      AuraHandledException e = new AuraHandledException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );

      e.setMessage(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );

      throw e;
    }

    if (response.status != '200') {
      AuraHandledException e = new AuraHandledException(
        'Unexpected response status: ' + response.status
      );

      e.setMessage('Unexpected response status: ' + response.status);

      throw e;
    }

    if (response.salesOrders == null || response.salesOrders.isEmpty()) {
      AuraHandledException e = new AuraHandledException(
        'No sales order returned in response.'
      );

      e.setMessage('No sales order returned in response.');

      throw e;
    }
  }
}
