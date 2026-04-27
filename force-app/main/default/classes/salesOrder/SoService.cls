public with sharing class SoService {
  public class LineItem {
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String item;
    @AuraEnabled
    public String itemName;
    @AuraEnabled
    public String quantity;
    @AuraEnabled
    public String rate;
    @AuraEnabled
    public String amount;
  }

  public class SalesOrderEditData {
    @AuraEnabled
    public String internalId;
    @AuraEnabled
    public Id customerId;
    @AuraEnabled
    public String customerName;
    @AuraEnabled
    public String customerNsId;
    @AuraEnabled
    public String orderDate;
    @AuraEnabled
    public String salesRep1Name;
    @AuraEnabled
    public String salesRep1NsId;
    @AuraEnabled
    public String salesRep2Name;
    @AuraEnabled
    public String salesRep2NsId;
    @AuraEnabled
    public String subsidiaryNsId;
    @AuraEnabled
    public String locationNsId;
    @AuraEnabled
    public String memo;
    @AuraEnabled
    public List<LineItem> lineItems = new List<LineItem>();
  }

  @AuraEnabled(cacheable=false)
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

  @AuraEnabled(cacheable=false)
  public static SalesOrderEditData getOrderData(Id salesOrderId) {
    if (salesOrderId == null) {
      throw new AuraHandledException('Sales order Id is required.');
    }

    SalesOrderEditData result = new SalesOrderEditData();

    List<breadwinner_ns__BW_Sales_Order__c> orders = [
      SELECT
        Id,
        breadwinner_ns__InternalId__c,
        breadwinner_ns__Entity__c,
        breadwinner_ns__Entity__r.Name,
        breadwinner_ns__Entity__r.breadwinner_ns__InternalId__c,
        breadwinner_ns__TranDate__c,
        breadwinner_ns__Memo__c,
        breadwinner_ns__SalesRepName__c,
        ncf_body_salesrep2__c,
        breadwinner_ns__LocationName__c
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE Id = :salesOrderId
      LIMIT 1
    ];

    if (orders.isEmpty()) {
      throw new AuraHandledException('Sales order not found.');
    }

    breadwinner_ns__BW_Sales_Order__c order = orders[0];

    result.internalId = order.breadwinner_ns__InternalId__c;
    result.customerId = order.breadwinner_ns__Entity__c;
    result.customerName = order.breadwinner_ns__Entity__r?.Name;
    result.customerNsId = order.breadwinner_ns__Entity__r
      ?.breadwinner_ns__InternalId__c;
    result.orderDate = String.valueOf(order.breadwinner_ns__TranDate__c);
    result.memo = order.breadwinner_ns__Memo__c;

    Map<String, String> repNsIds = resolveSalesRepNsIds(
      order.breadwinner_ns__SalesRepName__c,
      order.ncf_body_salesrep2__c
    );

    result.salesRep1Name = order.breadwinner_ns__SalesRepName__c;
    result.salesRep1NsId = repNsIds.get('rep1');
    result.salesRep2Name = order.ncf_body_salesrep2__c;
    result.salesRep2NsId = repNsIds.get('rep2');

    Map<String, String> locationData = resolveLocationAndSubsidiary(
      order.breadwinner_ns__LocationName__c
    );
    result.locationNsId = locationData.get('locationNsId');
    result.subsidiaryNsId = locationData.get('subsidiaryNsId');

    List<breadwinner_ns__BW_Line_Item__c> lines = [
      SELECT
        Id,
        breadwinner_ns__Item__r.Name,
        breadwinner_ns__Item__r.breadwinner_ns__InternalId__c,
        breadwinner_ns__Quantity__c,
        breadwinner_ns__Amount__c,
        breadwinner_ns__Rate__c
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE breadwinner_ns__Sales_Order__c = :salesOrderId
      ORDER BY CreatedDate ASC
    ];

    Integer rowNum = 1;

    for (breadwinner_ns__BW_Line_Item__c line : lines) {
      LineItem dto = new LineItem();
      dto.id = rowNum;
      dto.item = line.breadwinner_ns__Item__r?.breadwinner_ns__InternalId__c;
      dto.itemName = line.breadwinner_ns__Item__r?.Name;
      dto.quantity = String.valueOf(line.breadwinner_ns__Quantity__c);
      dto.amount = String.valueOf(line.breadwinner_ns__Amount__c);
      dto.rate = String.valueOf(line.breadwinner_ns__Rate__c);

      result.lineItems.add(dto);

      rowNum++;
    }

    return result;
  }

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
    try {
      validateParams(
        customer,
        orderDate,
        salesRep1,
        subsidiary,
        location,
        lineItemsJson

      );
      Boolean isUpdate = String.isNotBlank(internalId);

      List<LineItem> lineItems = deserializeLineItems(lineItemsJson);

      Map<String, Object> salesOrderRequest = buildSalesOrderRequest(
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

      Map<String, Object> requestPayload = buildApiPayload(
        salesOrderRequest,
        isUpdate
      );

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder request: ' + JSON.serialize(requestPayload)
      );

      Map<String, Object> response = breadwinner_ns.BreadwinnerNetSuiteAPI.call(
        requestPayload
      );

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder response: ' + JSON.serialize(response)
      );

      return handleApiResponse(response);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'SoService.saveSalesOrder failed: ' + e.getMessage()
      );
      System.debug(LoggingLevel.ERROR, e.getStackTraceString());
      throw e;
    }
  }

  private static Map<String, Object> buildApiPayload(
    Map<String, Object> salesOrderRequest,
    Boolean isUpdate
  ) {
    List<Object> salesOrders = new List<Object>{ salesOrderRequest };

    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'salesOrders' => salesOrders
    };

    String requestJson = JSON.serialize(requestJsonMap);

    return isUpdate
      ? new Map<String, Object>{
          'version' => '1.0',
          'action' => 'updateSalesOrder',
          'RequestJSON' => requestJson
        }
      : new Map<String, Object>{
          'version' => '1.0',
          'action' => 'createSalesOrder',
          'RequestJSON' => requestJson
        };
  }

  private static Map<String, Object> buildSalesOrderRequest(
    String internalId,
    String customer,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String memo,
    List<LineItem> lineItems,
    Boolean isUpdate
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    requestMap.put('customForm', lookupByInternalId('115'));
    requestMap.put('entity', lookupByInternalId(customer));
    requestMap.put('salesRep', lookupByInternalId(salesRep1));
    requestMap.put('subsidiary', lookupByInternalId(subsidiary));
    requestMap.put('location', lookupByInternalId(location));
    requestMap.put('tranDate', toUnixSeconds(orderDate));

    if (String.isNotBlank(internalId)) {
      requestMap.put('internalId', internalId);
    }

    if (String.isNotBlank(memo)) {
      requestMap.put('memo', memo);
    }

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => buildCustomFields(salesRep2) }
    );

    Map<String, Object> itemList = new Map<String, Object>{
      'item' => buildItemList(lineItems, location)
    };

    if (isUpdate) {
      itemList.put('replaceAll', true);
    }

    requestMap.put('itemList', itemList);

    return requestMap;
  }

  private static List<Object> buildCustomFields(String salesRep2) {
    List<Object> customFields = new List<Object>();

    customFields.add(
      new Map<String, Object>{
        'fieldType' => 'select',
        'scriptId' => 'cseg1',
        'valueLookup' => lookupByInternalId('1')
      }
    );

    if (!String.isBlank(salesRep2)) {
      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'select',
          'scriptId' => 'custbody_salesrep2',
          'valueLookup' => lookupByInternalId(salesRep2)
        }
      );
    }

    return customFields;
  }

  private static List<Object> buildItemList(
    List<LineItem> lineItems,
    String location
  ) {
    List<Object> items = new List<Object>();

    for (LineItem lineItem : lineItems) {
      if (lineItem == null || String.isBlank(lineItem.item)) {
        continue;
      }

      Map<String, Object> itemMap = new Map<String, Object>{
        'item' => lookupByInternalId(lineItem.item),
        'location' => lookupByInternalId(location),
        'price' => lookupByInternalId('-1'),
        'rate' => lineItem.rate
      };

      if (!String.isBlank(lineItem.quantity)) {
        itemMap.put('quantity', lineItem.quantity);
      }

      items.add(itemMap);
    }

    return items;
  }

  private static Map<String, Object> lookupByInternalId(String internalId) {
    return new Map<String, Object>{ 'internalId' => internalId };
  }

  private static Long toUnixSeconds(Date sourceDate) {
    DateTime asDateTime = DateTime.newInstance(
      sourceDate,
      Time.newInstance(0, 0, 0, 0)
    );

    return asDateTime.getTime() / 1000;
  }

  private static void validateParams(
    String customer,
    Date orderDate,
    String salesRep1,
    String subsidiary,
    String location,
    String lineItemsJson
  ) {
    if (
      String.isBlank(customer) ||
      orderDate == null ||
      String.isBlank(salesRep1) ||
      String.isBlank(subsidiary) ||
      String.isBlank(location) ||
      String.isBlank(lineItemsJson)
    ) {
      throw new AuraHandledException('Missing required parameters.');
    }

    List<LineItem> items = deserializeLineItems(lineItemsJson);

    if (items == null || items.isEmpty()) {
      throw new AuraHandledException('At least one line item is required.');
    }

    Boolean hasValidItem = false;

    for (LineItem item : items) {
      if (item != null && !String.isBlank(item.item)) {
        hasValidItem = true;
        break;
      }
    }

    if (!hasValidItem) {
      throw new AuraHandledException(
        'At least one valid line item is required.'
      );
    }
  }

  private static List<LineItem> deserializeLineItems(String lineItemsJson) {
    try {
      return (List<LineItem>) JSON.deserialize(
        lineItemsJson,
        List<LineItem>.class
      );
    } catch (Exception e) {
      throw new AuraHandledException('Invalid line item payload.');
    }
  }

  private static Map<String, String> resolveSalesRepNsIds(
    String rep1Name,
    String rep2Name
  ) {
    Map<String, String> output = new Map<String, String>{
      'rep1' => null,
      'rep2' => null
    };

    Set<String> namesToQuery = new Set<String>();

    if (String.isNotBlank(rep1Name)) {
      namesToQuery.add(rep1Name.trim());
    }

    if (String.isNotBlank(rep2Name)) {
      namesToQuery.add(rep2Name.trim());
    }

    if (namesToQuery.isEmpty()) {
      return output;
    }

    Map<String, String> byName = new Map<String, String>();
    for (breadwinner_ns__BW_Employee__c emp : [
      SELECT Name, breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Employee__c
      WHERE Name IN :namesToQuery
      LIMIT 50
    ]) {
      if (!byName.containsKey(emp.Name)) {
        byName.put(emp.Name, emp.breadwinner_ns__InternalId__c);
      }
    }

    if (String.isNotBlank(rep1Name)) {
      output.put('rep1', byName.get(rep1Name.trim()));
    }

    if (String.isNotBlank(rep2Name)) {
      output.put('rep2', byName.get(rep2Name.trim()));
    }

    return output;
  }

  private static Map<String, String> resolveLocationAndSubsidiary(
    String locationName
  ) {
    Map<String, String> output = new Map<String, String>{
      'locationNsId' => null,
      'subsidiaryNsId' => null
    };

    if (String.isBlank(locationName)) {
      return output;
    }

    List<breadwinner_ns__BW_Location__c> locations = [
      SELECT
        breadwinner_ns__InternalId__c,
        breadwinner_ns__Subsidiary__r.breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Location__c
      WHERE Name = :locationName
      LIMIT 1
    ];

    if (locations.isEmpty()) {
      return output;
    }

    output.put('locationNsId', locations[0].breadwinner_ns__InternalId__c);
    output.put(
      'subsidiaryNsId',
      locations[0].breadwinner_ns__Subsidiary__r?.breadwinner_ns__InternalId__c
    );

    return output;
  }

  private static String handleApiResponse(Map<String, Object> response) {
    if (response == null) {
      throw new AuraHandledException('No response returned from NetSuite.');
    }

    Boolean validRequest = (Boolean) response.get('validRequest');
    if (validRequest == null || !validRequest) {
      throw new AuraHandledException(
        'Invalid request: NetSuite rejected the payload.'
      );
    }

    String responseJsonStr = (String) response.get('responseJSON');
    if (String.isBlank(responseJsonStr)) {
      throw new AuraHandledException(
        'NetSuite returned an empty response body.'
      );
    }

    Map<String, Object> responseBody;
    try {
      responseBody = (Map<String, Object>) JSON.deserializeUntyped(
        responseJsonStr
      );
    } catch (Exception e) {
      throw new AuraHandledException('Unable to parse NetSuite response.');
    }

    List<Object> errors = (List<Object>) responseBody.get('errors');
    if (errors != null && !errors.isEmpty()) {
      String errorMsg = JSON.serialize(errors);

      System.debug(
        LoggingLevel.ERROR,
        'SoService.saveSalesOrder NetSuite errors: ' + errorMsg
      );

      throw new AuraHandledException('Order creation failed: ' + errorMsg);
    }

    String status = String.valueOf(responseBody.get('status'));
    if (status != '200') {
      throw new AuraHandledException('Unexpected response status: ' + status);
    }

    List<Object> salesOrders = (List<Object>) responseBody.get('salesOrders');
    if (salesOrders != null && !salesOrders.isEmpty()) {
      Map<String, Object> createdOrder = (Map<String, Object>) salesOrders[0];
      String tranId = String.valueOf(createdOrder.get('tranId'));
      String internalId = String.valueOf(createdOrder.get('internalId'));

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder created order: ' +
          tranId +
          ' internalId: ' +
          internalId
      );

      return internalId;
    }

    throw new AuraHandledException('No sales order returned in response.');
  }
}
