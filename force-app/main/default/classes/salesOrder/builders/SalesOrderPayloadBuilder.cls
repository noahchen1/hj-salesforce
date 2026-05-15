public with sharing class SalesOrderPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
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
    String inquiryModel,
    String inquiryName,
    String inquiryLink,
    String inquiryPersonalMsg,
    Boolean inquiryIsPrority,
    Boolean inquiryIsOpenDial,
    String inquiryTranNumber,
    String inquiryId,
    SalesOrderDataModel.Address shippingAddress,
    SalesOrderDataModel.Address billingAddress,
    List<SalesOrderDataModel.LineItem> lineItems,
    Boolean isUpdate
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
      orderType
    );

    if (orderTypeContext.isSpecialOrder || orderTypeContext.isInquiryOrder) {
      requestMap.put('customForm', lookupByInternalId('275'));
    } else {
      requestMap.put('customForm', lookupByInternalId('115'));
    }

    if (orderTypeContext.isInquiryOrder) {
      requestMap.put('tranid', inquiryTranNumber);
    }

    requestMap.put('entity', lookupByInternalId(custNsInternalId));
    requestMap.put('salesRep', lookupByInternalId(salesRep1));
    requestMap.put('subsidiary', lookupByInternalId(subsidiary));
    requestMap.put('location', lookupByInternalId(location));
    requestMap.put('terms', lookupByInternalId(termsNsInternalId));
    requestMap.put('tranDate', Helpers.toUnixSeconds(orderDate));

    if (String.isNotBlank(soNsInternalId)) {
      requestMap.put('internalId', soNsInternalId);
    }

    if (String.isNotBlank(memo)) {
      requestMap.put('memo', memo);
    }

    Map<String, Object> shippingAddressDetails = buildAddressDetails(
      shippingAddress
    );

    if (!shippingAddressDetails.isEmpty()) {
      requestMap.put('shippingAddress', shippingAddressDetails);
    }

    Map<String, Object> billingAddressDetails = buildAddressDetails(
      billingAddress
    );

    if (!billingAddressDetails.isEmpty()) {
      requestMap.put('billingAddress', billingAddressDetails);
    }

    requestMap.put(
      'customFieldList',
      new Map<String, Object>{
        'customField' => buildCustomFields(
          orderType,
          salesRep2,
          specialDate,
          needByDate,
          specialOrderItemType,
          specialOrderVendor,
          specialOrderRequestedVendor,
          specialOrderComments,
          specialOrderNotes,
          specialOrderMemoOrSold,
          inquiryModel,
          inquiryName,
          inquiryLink,
          inquiryPersonalMsg,
          inquiryIsPrority,
          inquiryIsOpenDial,
          inquiryId
        )
      }
    );

    Map<String, Object> itemList = new Map<String, Object>{
      'item' => buildItemList(orderType, lineItems, location)
    };

    if (isUpdate) {
      itemList.put('replaceAll', true);
    }

    requestMap.put('itemList', itemList);

    return requestMap;
  }

  public static Map<String, Object> buildSavePayload(
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

  public static Map<String, Object> buildReadRequest(String soNsInternalId) {
    Map<String, Object> filters = new Map<String, Object>{
      'internalId' => soNsInternalId
    };

    Map<String, Object> filterMap = new Map<String, Object>{
      'where' => new Map<String, Object>{ 'keyValueMap' => filters }
    };

    Map<String, Object> requestJSONMap = new Map<String, Object>{
      'customParameters' => filterMap
    };

    return requestJSONMap;
  }

  public static Map<String, Object> buildReadPayload(
    Map<String, Object> request
  ) {
    return new Map<String, Object>{
      'version' => '1.0',
      'action' => 'readSalesOrder',
      'requestJSON' => JSON.serialize(request)
    };
  }

  private static Map<String, Object> lookupByInternalId(String internalId) {
    return new Map<String, Object>{ 'internalId' => internalId };
  }

  private static List<Object> buildCustomFields(
    String orderType,
    String salesRep2,
    Date specialOrderDate,
    Date needByDate,
    String specialOrderItemType,
    String specialORderVendor,
    String specialOrderRequestedVendor,
    String specialOrderComments,
    String specialOrderNotes,
    String specialOrderMemoOrSold,
    String inquiryModel,
    String inquiryName,
    String inquiryLink,
    String inquiryPersonalMsg,
    Boolean inquiryIsPrority,
    Boolean inquiryIsOpenDial,
    String inquiryId
  ) {
    List<Object> customFields = new List<Object>();

    SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
      orderType
    );

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

    if (orderTypeContext.isSpecialOrder || orderTypeContext.isInquiryOrder) {
      if (specialOrderDate != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'date',
            'scriptId' => 'custbody_special_date',
            'value' => Helpers.toUnixSeconds(specialOrderDate)
          }
        );
      }

      if (needByDate != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'date',
            'scriptId' => 'custbody_special_order_date',
            'value' => Helpers.toUnixSeconds(needByDate)
          }
        );
      }

      if (String.isNotBlank(specialOrderItemType)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_special_item_type',
            'valueLookup' => lookupByInternalId(specialOrderItemType)
          }
        );
      }

      if (String.isNotBlank(specialORderVendor)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_special_order_vendor',
            'valueLookup' => lookupByInternalId(specialORderVendor)
          }
        );
      }

      if (String.isNotBlank(specialOrderRequestedVendor)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_special_pref_vendor',
            'value' => specialOrderRequestedVendor
          }
        );
      }

      if (String.isNotBlank(specialOrderComments)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_special_comments',
            'value' => specialOrderComments
          }
        );
      }

      if (String.isNotBlank(specialOrderNotes)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_special_merch_note',
            'value' => specialOrderNotes
          }
        );
      }

      if (String.isNotBlank(specialOrderMemoOrSold)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_special_memo_sold',
            'valueLookup' => lookupByInternalId(specialOrderMemoOrSold)
          }
        );
      }
    }

    if (orderTypeContext.isInquiryOrder) {
      if (String.isNotBlank(inquiryModel)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_inquiry_model',
            'value' => inquiryModel
          }
        );
      }

      if (String.isNotBlank(inquiryName)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_inquiry_description',
            'value' => inquiryName
          }
        );
      }

      if (String.isNotBlank(inquiryLink)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_inquiry_link',
            'value' => inquiryLink
          }
        );
      }

      if (inquiryIsPrority != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'boolean',
            'scriptId' => 'custbody_inquiry_is_priority',
            'value' => inquiryIsPrority
          }
        );
      }

      if (inquiryIsOpenDial != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'boolean',
            'scriptId' => 'custbody_inquiry_is_open_dial',
            'value' => inquiryIsOpenDial
          }
        );
      }

      if (String.isNotBlank(inquiryPersonalMsg)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_inquiry_personalization',
            'value' => inquiryPersonalMsg
          }
        );
      }

      if (String.isNotBlank(inquiryId)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_inquiry_id',
            'value' => inquiryId
          }
        );
      }

      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'boolean',
          'scriptId' => 'custbody_is_inquiry_ckbox',
          'value' => true
        }
      );

      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'boolean',
          'scriptId' => 'custbody_initial_email_check',
          'value' => true
        }
      );
    }

    return customFields;
  }

  private static List<Object> buildItemList(
    String orderType,
    List<SalesOrderDataModel.LineItem> lineItems,
    String location
  ) {
    List<Object> items = new List<Object>();

    SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
      orderType
    );

    for (SalesOrderDataModel.LineItem lineItem : lineItems) {
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

      if (orderTypeContext.isSpecialOrder || orderTypeContext.isInquiryOrder) {
        List<Object> customFields = new List<Object>();

        if (String.isNotBlank(lineItem.specialOrderItem)) {
          customFields.add(
            new Map<String, Object>{
              'fieldType' => 'string',
              'scriptId' => 'custcol_special_sku',
              'value' => lineItem.specialOrderItem
            }
          );
        }

        if (String.isNotBlank(lineItem.specialOrderVendorNum)) {
          customFields.add(
            new Map<String, Object>{
              'fieldType' => 'string',
              'scriptId' => 'custcol_special_order_number',
              'value' => lineItem.specialOrderVendorNum
            }
          );
        }

        if (String.isNotBlank(lineItem.quotedPrice)) {
          customFields.add(
            new Map<String, Object>{
              'fieldType' => 'string',
              'scriptId' => 'custcol_special_quoted_price',
              'value' => lineItem.quotedPrice
            }
          );
        }

        itemMap.put(
          'customFieldList',
          new Map<String, Object>{ 'customField' => customFields }
        );
      }

      items.add(itemMap);
    }

    return items;
  }

  private static Map<String, Object> buildAddressDetails(
    SalesOrderDataModel.Address address
  ) {
    Map<String, Object> addressDetails = new Map<String, Object>();

    if (address == null) {
      return addressDetails;
    }

    putIfNotBlank(addressDetails, 'attention', address.attention);
    putIfNotBlank(addressDetails, 'addressee', address.addressee);
    putIfNotBlank(addressDetails, 'addr1', address.addr1);
    putIfNotBlank(addressDetails, 'addr2', address.addr2);
    putIfNotBlank(addressDetails, 'addr3', address.addr3);
    putIfNotBlank(addressDetails, 'city', address.city);
    putIfNotBlank(addressDetails, 'state', address.state);
    putIfNotBlank(addressDetails, 'country', address.country);
    putIfNotBlank(addressDetails, 'zip', address.zip);

    return addressDetails;
  }

  private static void putIfNotBlank(
    Map<String, Object> target,
    String key,
    String value
  ) {
    if (String.isNotBlank(value)) {
      target.put(key, value);
    }
  }
}
