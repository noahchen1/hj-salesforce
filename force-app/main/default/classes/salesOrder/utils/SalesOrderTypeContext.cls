public with sharing class SalesOrderTypeContext {
  public Boolean isSalesOrder { get; private set; }
  public Boolean isSpecialOrder { get; private set; }
  public Boolean isInquiryOrder { get; private set; }
  public Boolean isRepairOrder { get; private set; }

  public SalesOrderTypeContext(String orderType) {
    String normalizedType = Helpers.normalizeString(orderType);

    isSalesOrder = normalizedType == String.valueOf(SalesOrderType.sales);
    isSpecialOrder = normalizedType == String.valueOf(SalesOrderType.special);
    isInquiryOrder = normalizedType == String.valueOf(SalesOrderType.inquiry);
    isRepairOrder = normalizedType == String.valueOf(SalesOrderType.repair);
  }

  public static SalesOrderTypeContext fromOrderType(String orderType) {
    return new SalesOrderTypeContext(orderType);
  }

  public Boolean isSupported() {
    return isSalesOrder || isSpecialOrder || isInquiryOrder || isRepairOrder;
  }
}
