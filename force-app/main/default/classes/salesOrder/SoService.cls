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
    @AuraEnabled
    public String line;
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

  @AuraEnabled(cacheable=true)
  public static String getObjectName(Id recordId) {
    return recordId.getSObjectType().getDescribe().getName();
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
  public static Id getNsCompanyFromAccount(Id accountId) {
    breadwinner_ns__BW_Company__c nsCompany = [
      SELECT Id
      FROM breadwinner_ns__BW_Company__c
      WHERE breadwinner_ns__Salesforce_Account__c = :accountId
    ];

    return nsCompany.Id;
  }

  @AuraEnabled(cacheable=false)
  public static SalesOrderEditData getOrderData(Id salesOrderId) {
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

    Map<String, Object> filters = new Map<String, Object>{
      'internalId' => orderRow.breadwinner_ns__InternalId__c
    };
    Map<String, Object> filterMap = new Map<String, Object>{
      'where' => new Map<String, Object>{ 'keyValueMap' => filters }
    };
    Map<String, Object> requestJSONMap = new Map<String, Object>{
      'customParameters' => filterMap
    };

    Map<String, Object> reqObj = new Map<String, Object>{
      'version' => '1.0',
      'action' => 'readSalesOrder',
      'requestJSON' => JSON.serialize(requestJSONMap)
    };

    Map<String, Object> resp = breadwinner_ns.BreadwinnerNetSuiteAPI.call(
      reqObj
    );

    if (resp == null) {
      throw new AuraHandledException('No response returned from NetSuite.');
    }

    Object rawResponseJson = resp.get('responseJSON');
    String responseJsonStr = rawResponseJson instanceof String
      ? (String) rawResponseJson
      : JSON.serialize(rawResponseJson);

    SoResModel.ResponseJson response = (SoResModel.ResponseJson) JSON.deserialize(
      responseJsonStr,
      SoResModel.ResponseJson.class
    );

    if (response == null) {
      throw new AuraHandledException('Unable to parse NetSuite response.');
    }

    if (response.errors != null && !response.errors.isEmpty()) {
      throw new AuraHandledException(
        'NetSuite returned errors: ' + JSON.serialize(response.errors)
      );
    }

    if (response.status != '200') {
      throw new AuraHandledException(
        'Unexpected response status: ' + response.status
      );
    }

    if (response.salesOrders == null || response.salesOrders.isEmpty()) {
      throw new AuraHandledException('No sales order returned in response.');
    }

    SoResModel.SalesOrder so = response.salesOrders[0];
    SalesOrderEditData result = new SalesOrderEditData();

    result.internalId = so.internalId;
    result.customerName = so.entity == null ? null : so.entity.name;
    result.customerNsId = so.entity == null ? null : so.entity.internalId;
    result.orderDate = toDateOnlyFromUnixSeconds(so.tranDate);
    result.memo = so.memo;

    result.salesRep1Name = so.salesRep == null ? null : so.salesRep.name;
    result.salesRep1NsId = so.salesRep == null ? null : so.salesRep.internalId;

    result.subsidiaryNsId = so.subsidiary == null
      ? null
      : so.subsidiary.internalId;
    result.locationNsId = so.location == null ? null : so.location.internalId;

    String salesRep2Name;
    String salesRep2NsId;
    if (so.customFieldList != null && so.customFieldList.customField != null) {
      for (SoResModel.CustomField cf : so.customFieldList.customField) {
        if (cf != null && cf.scriptId == 'custbody_salesrep2') {
          salesRep2Name = cf.valueLookup == null
            ? cf.value
            : cf.valueLookup.name;
          salesRep2NsId = cf.valueLookup == null
            ? null
            : cf.valueLookup.internalId;
          break;
        }
      }
    }
    result.salesRep2Name = salesRep2Name;
    result.salesRep2NsId = salesRep2NsId;

    Map<String, String> itemNamesByInternalId = new Map<String, String>();
    Set<String> itemInternalIds = new Set<String>();
    if (so.itemList != null && so.itemList.item != null) {
      for (SoResModel.SalesOrderItem it : so.itemList.item) {
        if (
          it != null &&
          it.item != null &&
          String.isNotBlank(it.item.internalId)
        ) {
          itemInternalIds.add(it.item.internalId);
        }
      }
    }

    if (!itemInternalIds.isEmpty()) {
      for (breadwinner_ns__BW_Item__c itemRow : [
        SELECT Name, breadwinner_ns__InternalId__c
        FROM breadwinner_ns__BW_Item__c
        WHERE breadwinner_ns__InternalId__c IN :itemInternalIds
      ]) {
        itemNamesByInternalId.put(
          itemRow.breadwinner_ns__InternalId__c,
          itemRow.Name
        );
      }
    }

    Integer rowNum = 1;
    if (so.itemList != null && so.itemList.item != null) {
      for (SoResModel.SalesOrderItem it : so.itemList.item) {
        if (it == null) {
          continue;
        }

        LineItem dto = new LineItem();
        dto.id = rowNum;
        dto.item = it.item == null ? null : it.item.internalId;
        dto.itemName = dto.item == null
          ? null
          : itemNamesByInternalId.get(dto.item);
        dto.quantity = it.quantity == null ? null : String.valueOf(it.quantity);
        dto.rate = it.rate;
        dto.amount = it.amount == null ? null : String.valueOf(it.amount);
        dto.line = it.line == null ? null : it.line;

        result.lineItems.add(dto);
        rowNum++;
      }
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
      itemList.put('replaceAll', false);
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

      if (!String.isBlank(lineItem.line)) {
        itemMap.put('line', lineItem.line);
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

  private static String toDateOnlyFromUnixSeconds(Long unixSeconds) {
    if (unixSeconds == null) {
      return null;
    }

    DateTime epoch = DateTime.newInstanceGmt(1970, 1, 1, 0, 0, 0);
    DateTime asUtc = epoch.addSeconds(
      Integer.valueOf(String.valueOf(unixSeconds))
    );

    // Matches lightning-input type="date" expected format
    return asUtc.formatGmt('yyyy-MM-dd');
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
