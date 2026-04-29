public with sharing class SalesOrderService {
  public static String saveSalesOrder(
    String internalId,
    String customer,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String memo,
    String lineItemsJson
  ) {
    try {
      SalesOrderValidator.validateParams(
        customer,
        orderDate,
        salesRep1,
        subsidiary,
        location,
        lineItemsJson
      );

      Boolean isUpdate = String.isNotBlank(internalId);

      List<SalesOrderDataModel.LineItem> lineItems = SalesOrderMapper.deserializeLineItems(
        lineItemsJson
      );

      Map<String, Object> salesOrderRequest = SalesOrderPayloadBuilder.buildSaveRequest(
        internalId,
        customer,
        orderDate,
        salesRep1,
        salesRep2,
        subsidiary,
        location,
        memo,
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

      return so.internalId;
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

    String internalId = orderRow.breadwinner_ns__InternalId__c;

    Map<String, Object> requestJSONMap = SalesOrderPayloadBuilder.buildReadRequest(
      internalId
    );

    Map<String, Object> reqObj = SalesOrderPayloadBuilder.buildReadPayload(
      requestJSONMap
    );

    Map<String, Object> resp = NetSuiteClient.call(reqObj);

    return SalesOrderResHandler.handleResponse(resp);
  }

  public static Map<String, Object> getNsCompanyFromAccount(Id accountId) {
    List<breadwinner_ns__BW_Company__c> companies = [
      SELECT Id, breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Company__c
      WHERE breadwinner_ns__Salesforce_Account__c = :accountId
      LIMIT 1
    ];

    if (companies.isEmpty()) {
      return null;
    }

    breadwinner_ns__BW_Company__c nsCompany = companies[0];

    return new Map<String, Object>{
      'companyId' => nsCompany.Id,
      'internalId' => nsCompany.breadwinner_ns__InternalId__c
    };
  }

  public static String getObjectName(Id recordId) {
    return recordId.getSObjectType().getDescribe().getName();
  }

  public static Id getOrder(String internalId) {
    List<breadwinner_ns__BW_Sales_Order__c> orders = [
      SELECT Id
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE breadwinner_ns__InternalId__c = :internalId
      LIMIT 1
    ];

    if (orders.isEmpty()) {
      return null;
    }

    return orders[0].Id;
  }
}
