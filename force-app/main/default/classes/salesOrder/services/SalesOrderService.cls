public with sharing class SalesOrderService {
  public static String saveSalesOrder(
    SalesOrderParamModel.SalesOrderSaveParam saveParams
  ) {
    try {
      SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
        saveParams.orderType
      );

      SalesOrderValidator.validateParams(
        saveParams.orderType,
        saveParams.inquiryType,
        saveParams.custNsInternalId,
        saveParams.orderDate,
        saveParams.salesRep1,
        saveParams.subsidiary,
        saveParams.location,
        saveParams.specialDate,
        saveParams.needByDate,
        saveParams.specialOrderItemType,
        saveParams.specialOrderVendor,
        saveParams.specialOrderMemoOrSold,
        saveParams.inquiryId,
        saveParams.inquiryModel,
        saveParams.inquiryName,
        saveParams.inquiryLink,
        saveParams.inquiryIsPrority,
        saveParams.lineItemsJson
      );

      Boolean isUpdate = String.isNotBlank(saveParams.soNsInternalId);
      String inquiryTranNumber;

      if (orderTypeContext.isInquiryOrder) {
        inquiryTranNumber = buildNextInquiryTranNumber(
          saveParams.custNsInternalId,
          saveParams.inquiryType
        );
      }

      List<SalesOrderDataModel.LineItem> lineItems = SalesOrderMapper.deserializeLineItems(
        saveParams.lineItemsJson
      );

      SalesOrderDataModel.Address shippingAddress = SalesOrderMapper.deserializeAddress(
        saveParams.shippingAddressJson
      );

      SalesOrderDataModel.Address billingAddress = SalesOrderMapper.deserializeAddress(
        saveParams.billingAddressJson
      );

      Map<String, Object> salesOrderRequest = SalesOrderPayloadBuilder.buildSaveRequest(
        saveParams,
        shippingAddress,
        billingAddress,
        lineItems,
        inquiryTranNumber,
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

    System.debug(
      LoggingLevel.INFO,
      'SoService.getOrderData response: ' + JSON.serialize(resp)
    );

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

  private static String buildNextInquiryTranNumber(
    String custNsInternalId,
    String inquiryTypeValue
  ) {
    Boolean isRolex = inquiryTypeValue == String.valueOf(InquiryType.ROLEX);
    String prefix = isRolex ? 'SOR' : 'SOT';
    String startingNum = prefix + custNsInternalId;
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

  public static List<ContentVersion> getAttachedFiles(
    String concatenatedUrls
  ) {
    List<ContentVersion> cvs = new List<ContentVersion>();
    Set<String> fileNames = new Set<String>();

    if (String.isBlank(concatenatedUrls)) {
      return cvs;
    }

    Http http = new Http();

    for (String rawUrl : concatenatedUrls.split(',')) {
      String url = rawUrl.trim();

      if (String.isBlank(url)) {
        continue;
      }

      HttpRequest req = new HttpRequest();
      req.setEndpoint(url);
      req.setMethod('GET');

      HttpResponse res = http.send(req);

      if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
        System.debug(
          'File download failed. Status=' + res.getStatus() + ', URL=' + url
        );

        continue;
      }

      String fileName = Helpers.getFileNameFromContentDisposition(
        res.getHeader('Content-Disposition')
      );

      if (String.isBlank(fileName)) {
        fileName = 'downloaded-file';
      }

      String title = Helpers.getTitleFromFileName(fileName);

      ContentVersion cv = new ContentVersion();
      cv.Title = title;
      cv.PathOnClient = fileName;
      cv.VersionData = res.getBodyAsBlob();
      cv.IsMajorVersion = true;

      cvs.add(cv);
      fileNames.add(fileName);
    }

    if (!cvs.isEmpty()) {
      Map<String, Id> existingDocumentIdsByFileName = new Map<String, Id>();

      for (ContentVersion existingCv : [
        SELECT ContentDocumentId, PathOnClient
        FROM ContentVersion
        WHERE IsLatest = TRUE AND PathOnClient IN :fileNames
        ORDER BY CreatedDate DESC
      ]) {
        if (
          !existingDocumentIdsByFileName.containsKey(existingCv.PathOnClient)
        ) {
          existingDocumentIdsByFileName.put(
            existingCv.PathOnClient,
            existingCv.ContentDocumentId
          );
        }
      }

      for (ContentVersion cv : cvs) {
        Id existingDocumentId = existingDocumentIdsByFileName.get(
          cv.PathOnClient
        );

        if (existingDocumentId != null) {
          cv.ContentDocumentId = existingDocumentId;
        }

        insert cv;

        if (!existingDocumentIdsByFileName.containsKey(cv.PathOnClient)) {
          ContentVersion insertedCv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
          ];

          existingDocumentIdsByFileName.put(
            cv.PathOnClient,
            insertedCv.ContentDocumentId
          );
        }
      }
    }

    return cvs;
  }
}
