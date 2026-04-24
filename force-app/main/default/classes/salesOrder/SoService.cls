public with sharing class SoService {
  public class LineItem {
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

      List<LineItem> lineItems = deserializeLineItems(lineItemsJson);

      Map<String, Object> salesOrderRequest = buildSalesOrderRequest(
        customer,
        orderDate,
        salesRep1,
        salesRep2,
        subsidiary,
        location,
        memo,
        lineItems
      );

      Map<String, Object> requestPayload = buildApiPayload(salesOrderRequest);

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

      handleApiResponse(response);
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
    Map<String, Object> salesOrderRequest
  ) {
    List<Object> salesOrders = new List<Object>{ salesOrderRequest };

    Map<String, Object> requestJsonMap = new Map<String, Object>{
      'salesOrders' => salesOrders
    };

    String requestJson = JSON.serialize(requestJsonMap);

    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'createSalesOrder',
      'RequestJSON' => requestJson
    };
  }

  private static Map<String, Object> buildSalesOrderRequest(
    String customer,
    Date orderDate,
    String salesRep1,
    String salesRep2,
    String subsidiary,
    String location,
    String memo,
    List<LineItem> lineItems
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    requestMap.put('customForm', lookupByInternalId('115'));
    requestMap.put('entity', lookupByInternalId(customer));
    requestMap.put('salesRep', lookupByInternalId(salesRep1));
    requestMap.put('subsidiary', lookupByInternalId(subsidiary));
    requestMap.put('location', lookupByInternalId(location));

    if (String.isNotBlank(memo)) {
      requestMap.put('memo', memo);
    }

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{ 'customField' => buildCustomFields(salesRep2) }
    );

    requestMap.put(
      'itemList',
      new Map<String, Object>{ 'item' => buildItemList(lineItems, location) }
    );

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

  private static void handleApiResponse(Map<String, Object> response) {
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

      System.debug(
        LoggingLevel.INFO,
        'SoService.saveSalesOrder created order: ' + tranId
      );
    }
  }
}
