public with sharing class SalesOrderController {
  @AuraEnabled
  public static String saveSalesOrder(
    String soNsInternalId,
    String custNsInternalId,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String memo,
    String shippingAddressJson,
    String billingAddressJson,
    String lineItemsJson
  ) {
    return SalesOrderService.saveSalesOrder(
      soNsInternalId,
      custNsInternalId,
      orderDate,
      salesRep1,
      salesRep2,
      subsidiary,
      location,
      memo,
      shippingAddressJson,
      billingAddressJson,
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
  public static Id getOrder(String soNsInternalId) {
    return SalesOrderService.getOrder(soNsInternalId);
  }

  @AuraEnabled
  public static void notifyOrderSaveStatus(
    Boolean isSuccess,
    String soNsInternalId,
    Id orderRecordId,
    String errorMessage
  ) {
    SalesOrderService.notifyOrderStatus(
      isSuccess,
      soNsInternalId,
      orderRecordId,
      errorMessage
    );
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
