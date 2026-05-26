public with sharing class SalesOrderService {
  public static String saveSalesOrder(
    String orderType,
    String soNsInternalId,
    String custNsInternalId,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String termsNsInternalId,
    String memo,
    Date specialDate,
    Date needByDate,
    String specialOrderItemType,
    String specialOrderVendor,
    String specialOrderRequestedVendor,
    String specialOrderComments,
    String specialOrderNotes,
    String specialOrderMemoOrSold,
    String shippingAddressJson,
    String billingAddressJson,
    String inquiryId,
    String inquiryModel,
    String inquiryName,
    String inquiryLink,
    String inquiryPersonalMsg,
    Boolean inquiryIsSendEmail,
    Boolean inquiryIsPrority,
    Boolean inquiryIsOpenDial,
    String lineItemsJson
  ) {
    try {
      SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
        orderType
      );

      SalesOrderValidator.validateParams(
        orderType,
        custNsInternalId,
        orderDate,
        salesRep1,
        subsidiary,
        location,
        specialDate,
        needByDate,
        specialOrderItemType,
        specialOrderVendor,
        specialOrderMemoOrSold,
        inquiryId,
        inquiryModel,
        inquiryName,
        inquiryLink,
        inquiryIsPrority,
        lineItemsJson
      );

      Boolean isUpdate = String.isNotBlank(soNsInternalId);
      String inquiryTranNumber;

      if (orderTypeContext.isInquiryOrder) {
        inquiryTranNumber = buildNextInquiryTranNumber(custNsInternalId);
      }

      List<SalesOrderDataModel.LineItem> lineItems = SalesOrderMapper.deserializeLineItems(
        lineItemsJson
      );

      SalesOrderDataModel.Address shippingAddress = SalesOrderMapper.deserializeAddress(
        shippingAddressJson
      );

      SalesOrderDataModel.Address billingAddress = SalesOrderMapper.deserializeAddress(
        billingAddressJson
      );

      Map<String, Object> salesOrderRequest = SalesOrderPayloadBuilder.buildSaveRequest(
        orderType,
        soNsInternalId,
        custNsInternalId,
        orderDate,
        salesRep1,
        salesRep2,
        subsidiary,
        location,
        termsNsInternalId,
        memo,
        specialDate,
        needByDate,
        specialOrderItemType,
        specialOrderVendor,
        specialOrderRequestedVendor,
        specialOrderComments,
        specialOrderNotes,
        specialOrderMemoOrSold,
        inquiryModel,
        inquiryName,
        inquiryLink,
        inquiryPersonalMsg,
        inquiryIsSendEmail,
        inquiryIsPrority,
        inquiryIsOpenDial,
        inquiryTranNumber,
        inquiryId,
        shippingAddress,
        billingAddress,
        lineItems,
        isUpdate
      );

      Map<String, Object> requestPayload = SalesOrderPayloadBuilder.buildSavePayload(
        salesOrderRequest,
        isUpdate
      );

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder request: ' + JSON.serialize(requestPayload)
      );

      Map<String, Object> response = NetSuiteClient.call(requestPayload);

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder response: ' + JSON.serialize(response)
      );

      SalesOrderDataModel.SalesOrderData so = SalesOrderResHandler.handleResponse(
        response
      );

      return so.soNsInternalId;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'SoService.saveSalesOrder failed: ' + e.getMessage()
      );

      System.debug(LoggingLevel.ERROR, e.getStackTraceString());

      throw e;
    }
  }

  public static SalesOrderDataModel.SalesOrderData getOrderData(
    Id salesOrderId
  ) {
    if (salesOrderId == null) {
      throw new AuraHandledException('Sales order Id is required.');
    }

    List<breadwinner_ns__BW_Sales_Order__c> orderRows = [
      SELECT breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE Id = :salesOrderId
      LIMIT 1
    ];

    if (
      orderRows.isEmpty() ||
      String.isBlank(orderRows[0].breadwinner_ns__InternalId__c)
    ) {
      throw new AuraHandledException('Could not locate existing order.');
    }

    breadwinner_ns__BW_Sales_Order__c orderRow = orderRows[0];

    String soNsInternalId = orderRow.breadwinner_ns__InternalId__c;

    Map<String, Object> requestJSONMap = SalesOrderPayloadBuilder.buildReadRequest(
      soNsInternalId
    );

    Map<String, Object> reqObj = SalesOrderPayloadBuilder.buildReadPayload(
      requestJSONMap
    );

    Map<String, Object> resp = NetSuiteClient.call(reqObj);

    return SalesOrderResHandler.handleResponse(resp);
  }

  public static Map<String, Object> getNsCompanyFromAccount(Id accountId) {
    List<breadwinner_ns__BW_Company__c> companies = [
      SELECT
        Name,
        Id,
        breadwinner_ns__InternalId__c,
        ncf_entity_call_perferred__c,
        ncf_entity_email_perferred__c,
        ncf_entity_text_msg_perferred__c
      FROM breadwinner_ns__BW_Company__c
      WHERE breadwinner_ns__Salesforce_Account__c = :accountId
      LIMIT 1
    ];

    if (companies.isEmpty()) {
      return null;
    }

    breadwinner_ns__BW_Company__c nsCompany = companies[0];

    return new Map<String, Object>{
      'name' => nsCompany.Name,
      'companyId' => nsCompany.Id,
      'internalId' => nsCompany.breadwinner_ns__InternalId__c,
      'isEmailPreferred' => nsCompany.ncf_entity_email_perferred__c,
      'isCallPreferred' => nsCompany.ncf_entity_call_perferred__c,
      'isMessagePreferred' => nsCompany.ncf_entity_text_msg_perferred__c
    };
  }

  public static String getObjectName(Id recordId) {
    return recordId.getSObjectType().getDescribe().getName();
  }

  public static Id getOrder(String soNsInternalId) {
    List<breadwinner_ns__BW_Sales_Order__c> orders = [
      SELECT Id
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE breadwinner_ns__InternalId__c = :soNsInternalId
      LIMIT 1
    ];

    if (orders.isEmpty()) {
      return null;
    }

    return orders[0].Id;
  }

  public static void notifyOrderStatus(
    Boolean isSuccess,
    String soNsInternalId,
    Id orderRecordId,
    String errorMessage
  ) {
    List<CustomNotificationType> notificationTypes = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = 'Sales_Order_Save_Status'
      LIMIT 1
    ];

    if (notificationTypes.isEmpty()) {
      return;
    }

    String status = isSuccess ? 'Saved' : 'Failed';
    String body = isSuccess
      ? 'Sales order ' + status + '. Internal ID: ' + soNsInternalId
      : 'Sales order ' + status + '. ' + errorMessage;

    Messaging.CustomNotification notification = new Messaging.CustomNotification();
    notification.setTitle('Sales Order Save ' + status);
    notification.setBody(body);
    notification.setNotificationTypeId(notificationTypes[0].Id);

    if (orderRecordId != null) {
      notification.setTargetId(orderRecordId);
    }

    notification.send(new Set<String>{ UserInfo.getUserId() });
  }

  private static String buildNextInquiryTranNumber(String custNsInternalId) {
    String startingNum = 'SOR' + custNsInternalId;
    String likePattern = startingNum + '%';

    List<breadwinner_ns__BW_Sales_Order__c> existingOrders = [
      SELECT Name
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE Name LIKE :likePattern
      ORDER BY Name DESC
    ];

    if (existingOrders.isEmpty()) {
      return startingNum + '1';
    }

    Integer maxNum = 0;
    for (breadwinner_ns__BW_Sales_Order__c order : existingOrders) {
      String suffix = order.Name.removeStart(startingNum);
      if (suffix.isNumeric()) {
        Integer num = Integer.valueOf(suffix);

        if (num > maxNum) {
          maxNum = num;
        }
      }
    }
    return startingNum + (maxNum + 1);
  }

  public static String getInquiryId(String custNsInternalId) {
    if (String.isBlank(custNsInternalId)) {
      return null;
    }

    Integer maxNumericSuffix = -1;
    String latestInquiryId;

    for (breadwinner_ns__BW_Sales_Order__c existingOrder : [
      SELECT ncf_body_inquiry_id__c
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE
        breadwinner_ns__Salesforce_Account__r.NetSuiteInternalId__c = :custNsInternalId
        AND ncf_body_inquiry_id__c != NULL
      ORDER BY ncf_body_inquiry_id__c DESC
    ]) {
      String inquiryId = existingOrder.ncf_body_inquiry_id__c;
      Integer underscoreIndex = inquiryId.indexOf('_');
      String numericPart = underscoreIndex >= 0
        ? inquiryId.substring(underscoreIndex + 1)
        : inquiryId;

      if (numericPart.isNumeric()) {
        Integer numericValue = Integer.valueOf(numericPart);
        if (numericValue > maxNumericSuffix) {
          maxNumericSuffix = numericValue;
          latestInquiryId = inquiryId;
        }
      }
    }

    if (String.isBlank(latestInquiryId)) {
      return custNsInternalId + '_1';
    }

    Integer underscoreIndex = latestInquiryId.indexOf('_');
    if (
      underscoreIndex < 0 ||
      underscoreIndex == latestInquiryId.length() - 1
    ) {
      return latestInquiryId;
    }

    String prefix = latestInquiryId.substring(0, underscoreIndex);
    String numericPart = latestInquiryId.substring(underscoreIndex + 1);
    if (!numericPart.isNumeric()) {
      return latestInquiryId;
    }

    Integer nextNumericValue = Integer.valueOf(numericPart) + 1;
    return prefix + '_' + String.valueOf(nextNumericValue);
  }
}
