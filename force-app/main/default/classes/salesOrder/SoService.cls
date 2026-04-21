public with sharing class SoService {
  public class lineItem {
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String item;
    @AuraEnabled
    public String quantity;
    @AuraEnabled
    public String rate;
    @AuraEnabled
    public String amount;
  }

  @AuraEnabled
  public static void saveSalesOrder() {
    try {
      List<Object> salesOrderList = new List<Object>();
      Map<String, Object> requestMap = buildRequestMap();
      System.debug('requestMap: ' + JSON.serialize(requestMap));
      salesOrderList.add(requestMap);

      Map<String, Object> reqJSONMap = new Map<String, Object>();
      reqJSONMap.put('salesOrders', salesOrderList);
      String reqJSON = JSON.serialize(reqJSONMap);

      Map<String, Object> finalReqMap = new Map<String, Object>();
      finalReqMap.put('version', '1.0');
      finalReqMap.put('action', 'createSalesOrder');
      finalReqMap.put('RequestJSON', reqJSON);

      System.debug(LoggingLevel.INFO, 'SoService.createSo request: ' + reqJSON);

      Map<String, Object> respMap = breadwinner_ns.BreadwinnerNetSuiteAPI.call(
        finalReqMap
      );

      System.debug(
        LoggingLevel.INFO,
        'SoService.createSo response: ' + JSON.serialize(respMap)
      );
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'SoService.createSo failed: ' + e.getMessage()
      );
      System.debug(LoggingLevel.ERROR, e.getStackTraceString());
      throw e;
    }
  }

  public static Map<String, Object> buildRequestMap() {
    // String customer,
    // String salesRep1,
    // String salesRep2,
    // String location,
    // List<lineItem> lineItems
    Map<String, Object> requestMap = new Map<String, Object>();

    requestMap.put(
      'customForm',
      new Map<String, Object>{ 'internalId' => 115 }
    );

    requestMap.put(
      'entity',
      new Map<String, Object>{ 'internalId' => '11934' }
    );
    requestMap.put(
      'salesRep',
      new Map<String, Object>{ 'internalId' => '1487' }
    );
    requestMap.put(
      'subsidiary',
      new Map<String, Object>{ 'internalId' => '30' }
    );
    requestMap.put('location', new Map<String, Object>{ 'internalId' => '28' });
    // requestMap.put('cseg1', new Map<String, Object>{ 'internalId' => '1' });

    List<Object> custCustomFieldList = new List<Object>();
    Map<String, Object> custCustomField1 = new Map<String, Object>();
    custCustomField1.put('fieldType', 'select');
    custCustomField1.put('scriptId', 'cseg1');
    custCustomField1.put(
      'valueLookup',
      new Map<String, Object>{ 'internalId' => '1' }
    );
    custCustomFieldList.add(custCustomField1);

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => custCustomFieldList }
    );

    List<Object> lineItems = new List<Object>();
    Map<String, Object> lineItemMap = new Map<String, Object>();
    lineItemMap.put(
      'item',
      new Map<String, Object>{ 'internalId' => '166124' }
    );
    lineItemMap.put(
      'location',
      new Map<String, Object>{ 'internalId' => '28' }
    );
    lineItems.add(lineItemMap);

    Map<String, Object> lineItemList = new Map<String, Object>();
    lineItemList.put('item', lineItems);

    requestMap.put('itemList', lineItemList);

    return requestMap;
  }
}
