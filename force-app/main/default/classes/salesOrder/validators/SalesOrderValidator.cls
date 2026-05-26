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
    String inquiryType,
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
    String inquiryId,
    String inquiryModel,
    String inquiryName,
    String inquiryLink,
    Boolean inquiryIsPrority,
    String lineItemsJson
  ) {
    SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
      orderType
    );

    if (!orderTypeContext.isSupported()) {
      throw Helpers.buildAuraException('Unsupported orderType: ' + orderType);
    }

    if (
      String.isBlank(custNsInternalId) ||
      orderDate == null ||
      String.isBlank(salesRep1) ||
      String.isBlank(subsidiary) ||
      String.isBlank(location) ||
      String.isBlank(lineItemsJson)
    ) {
      throw Helpers.buildAuraException('Missing required parameters.');
    }

    if (
      (orderTypeContext.isSpecialOrder || orderTypeContext.isInquiryOrder) &&
      (specialDate == null ||
      needByDate == null ||
      String.isBlank(specialOrderItemType) ||
      (isVendorRequiredItemType(specialOrderItemType) &&
      String.isBlank(specialOrderVendor)) ||
      String.isBlank(specialOrderMemoOrSold))
    ) {
      throw Helpers.buildAuraException(
        'Missing required special order parameters.'
      );
    }

    if (
      orderTypeContext.isInquiryOrder &&
      (String.isBlank(inquiryId) ||
      String.isBlank(inquiryModel) ||
      String.isBlank(inquiryName) ||
      String.isBlank(inquiryLink) ||
      String.isBlank(inquiryType))
    ) {
      throw Helpers.buildAuraException('Missing required inquiry parameters.');
    }

    List<SalesOrderDataModel.LineItem> items = SalesOrderMapper.deserializeLineItems(
      lineItemsJson
    );

    if (items == null || items.isEmpty()) {
      throw Helpers.buildAuraException('At least one line item is required.');
    }

    for (Integer i = 0; i < items.size(); i++) {
      SalesOrderDataModel.LineItem item = items.get(i);

      Boolean isStoreDiscount = item.item == '186466'; //Store Discount

      if (item == null || String.isBlank(item.item)) {
        throw Helpers.buildAuraException(
          'Line item ' + (i + 1) + ': item is required.'
        );
      }

      if (!orderTypeContext.isInquiryOrder && String.isBlank(item.rate)) {
        throw Helpers.buildAuraException(
          'Line item ' + (i + 1) + ': rate is required.'
        );
      }

      if (!orderTypeContext.isInquiryOrder && String.isBlank(item.amount)) {
        throw Helpers.buildAuraException(
          'Line item ' + (i + 1) + ': amount is required.'
        );
      }

      if (!isStoreDiscount && String.isBlank(item.quantity)) {
        throw Helpers.buildAuraException(
          'Line item ' + (i + 1) + ': quantity is required.'
        );
      }

      if (
        !isStoreDiscount &&
        orderTypeContext.isSpecialOrder &&
        String.isBlank(item.quotedPrice)
      ) {
        throw Helpers.buildAuraException(
          'Line item ' +
            (i + 1) +
            ': quotedPrice is required for special orders.'
        );
      }
    }
  }

  public static void validateRawResponse(Map<String, Object> response) {
    if (response == null) {
      throw Helpers.buildAuraException('No response returned from NetSuite.');
    }

    Boolean validRequest = (Boolean) response.get('validRequest');
    if (validRequest == null || !validRequest) {
      throw Helpers.buildAuraException(
        'Invalid request: NetSuite rejected the payload.'
      );
    }

    String responseJsonStr = (String) response.get('responseJSON');
    if (String.isBlank(responseJsonStr)) {
      throw Helpers.buildAuraException(
        'NetSuite returned an empty response body.'
      );
    }
  }

  public static void validateTypedBody(
    SalesOrderResModel.ResponseJson response
  ) {
    if (response == null) {
      throw Helpers.buildAuraException('Unable to parse NetSuite response.');
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      throw Helpers.buildAuraException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );
    }

    if (response.status != '200') {
      throw Helpers.buildAuraException(
        'Unexpected response status: ' + response.status
      );
    }

    if (response.salesOrders == null || response.salesOrders.isEmpty()) {
      throw Helpers.buildAuraException('No sales order returned in response.');
    }
  }
}
