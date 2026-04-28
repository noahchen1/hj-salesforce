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

      return SalesOrderResHandler.handleApiResponse(response);
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

    breadwinner_ns__BW_Sales_Order__c orderRow = [
      SELECT breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE Id = :salesOrderId
      LIMIT 1
    ];

    if (
      orderRow == null || String.isBlank(orderRow.breadwinner_ns__InternalId__c)
    ) {
      throw new AuraHandledException('Could not locate existing order.');
    }

    String internalId = orderRow.breadwinner_ns__InternalId__c;

    Map<String, Object> requestJSONMap = SalesOrderPayloadBuilder.buildReadRequest(
      internalId
    );

    Map<String, Object> reqObj = SalesOrderPayloadBuilder.buildReadPayload(
      requestJSONMap
    );

    Map<String, Object> resp = NetSuiteClient.call(reqObj);

    return SalesOrderResHandler.handleReadResponse(resp);
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
}