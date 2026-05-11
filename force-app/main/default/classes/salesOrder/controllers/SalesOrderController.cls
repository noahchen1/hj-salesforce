public with sharing class SalesOrderController {
  @AuraEnabled
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
    String lineItemsJson
  ) {
    return SalesOrderService.saveSalesOrder(
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
