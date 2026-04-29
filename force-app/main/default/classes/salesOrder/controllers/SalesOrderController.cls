public with sharing class SalesOrderController {
  @AuraEnabled
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
    return SalesOrderService.saveSalesOrder(
      internalId,
      customer,
      orderDate,
      salesRep1,
      salesRep2,
      subsidiary,
      location,
      memo,
      lineItemsJson
    );
  }

  @AuraEnabled(cacheable=false)
  public static SalesOrderDataModel.SalesOrderData getOrderData(
    Id salesOrderId
  ) {
    return SalesOrderService.getOrderData(salesOrderId);
  }

  @AuraEnabled(cacheable=false)
  public static Id getOrder(String internalId) {
    return SalesOrderService.getOrder(internalId);
  }

  @AuraEnabled(cacheable=true)
  public static String getObjectName(Id recordId) {
    return SalesOrderService.getObjectName(recordId);
  }

  @AuraEnabled(cacheable=false)
  public static Map<String, Object> getNsCompanyFromAccount(Id accountId) {
    return SalesOrderService.getNsCompanyFromAccount(accountId);
  }
}
