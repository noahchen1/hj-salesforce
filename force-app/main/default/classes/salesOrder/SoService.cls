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
  public static void saveSalesOrder(
    String customer,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String lineItemsJson
  ) {
    try {
      if (
        !checkParams(
          customer,
          orderDate,
          salesRep1,
          subsidiary,
          location,
          lineItemsJson
        )
      ) {
        throw new AuraHandledException('Missing Params');
      }

      List<lineItem> lineItems = (List<lineItem>) JSON.deserialize(
        lineItemsJson,
        List<lineItem>.class
      );

      List<Object> salesOrderList = new List<Object>();
      Map<String, Object> requestMap = buildRequestMap(
        customer,
        orderDate,
        salesRep1,
        salesRep2,
        subsidiary,
        location,
        lineItems
      );

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

      // Map<String, Object> respMap = breadwinner_ns.BreadwinnerNetSuiteAPI.call(
      //   finalReqMap
      // );

      // System.debug(
      //   LoggingLevel.INFO,
      //   'SoService.createSo response: ' + JSON.serialize(respMap)
      // );
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'SoService.createSo failed: ' + e.getMessage()
      );
      System.debug(LoggingLevel.ERROR, e.getStackTraceString());
      throw e;
    }
  }

  public static Map<String, Object> buildRequestMap(
    String customer,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    List<lineItem> lineItems
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    requestMap.put(
      'customForm',
      new Map<String, Object>{ 'internalId' => '115' }
    );

    requestMap.put(
      'entity',
      new Map<String, Object>{ 'internalId' => customer }
    );

    requestMap.put(
      'salesRep',
      new Map<String, Object>{ 'internalId' => salesRep1 }
    );

    requestMap.put(
      'subsidiary',
      new Map<String, Object>{ 'internalId' => subsidiary }
    );

    requestMap.put(
      'location',
      new Map<String, Object>{ 'internalId' => location }
    );

    List<Object> custCustomFieldList = new List<Object>();

    Map<String, Object> channelStream = new Map<String, Object>();
    channelStream.put('fieldType', 'select');
    channelStream.put('scriptId', 'cseg1');
    channelStream.put(
      'valueLookup',
      new Map<String, Object>{ 'internalId' => '1' }
    );

    custCustomFieldList.add(channelStream);

    if (!String.isBlank(salesRep2)) {
      Map<String, Object> salesRep2Map = new Map<String, Object>();
      salesRep2Map.put('fieldType', 'select');
      salesRep2Map.put('scriptId', 'custbody_salesrep2');
      salesRep2Map.put(
        'valueLookup',
        new Map<String, Object>{ 'internalId' => salesRep2 }
      );

      custCustomFieldList.add(salesRep2Map);
    }

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => custCustomFieldList }
    );

    List<Object> items = new List<Object>();

    for (lineItem li : lineItems) {
      Map<String, Object> lineItemMap = new Map<String, Object>();

      String item = li.item;

      lineItemMap.put('item', new Map<String, Object>{ 'internalId' => item });

      lineItemMap.put(
        'location',
        new Map<String, Object>{ 'internalId' => location }
      );

      lineItemMap.put('quantity', li.quantity);

      lineItemMap.put('price', new Map<String, Object>{ 'internalId' => '-1' });

      lineItemMap.put('rate', li.rate);

      items.add(lineItemMap);
    }

    Map<String, Object> lineItemList = new Map<String, Object>();
    lineItemList.put('item', items);

    requestMap.put('itemList', lineItemList);

    return requestMap;
  }

  private static Boolean checkParams(
    String customer,
    Date orderDate,
    String salesRep1,
    String subsidiary,
    String location,
    String lineItemsJson
  ) {
    System.debug('customer: ' + customer);

    if (
      String.isEmpty(customer) ||
      orderDate == null ||
      String.isEmpty(salesRep1) ||
      String.isEmpty(subsidiary) ||
      String.isEmpty(location) ||
      String.isEmpty(lineItemsJson)
    ) {
      return false;
    }

    List<lineItem> items;

    try {
      items = (List<lineItem>) JSON.deserialize(
        lineItemsJson,
        List<lineItem>.class
      );
    } catch (Exception ex) {
      return false;
    }

    if (items == null || items.isEmpty()) {
      return false;
    }

    for (lineItem li : items) {
      if (li != null && !String.isBlank(li.item)) {
        return true;
      }
    }

    return false;
  }
}
