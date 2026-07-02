public with sharing class SalesOrderPayloadBuilder {
  public static Map<String, Object> buildSaveRequest(
    SalesOrderParamModel.SalesOrderSaveParam saveParams,
    SalesOrderDataModel.Address shippingAddress,
    SalesOrderDataModel.Address billingAddress,
    List<SalesOrderDataModel.LineItem> lineItems,
    String inquiryTranNumber,
    Boolean isUpdate
  ) {
    Map<String, Object> requestMap = new Map<String, Object>();

    SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
      saveParams.orderType
    );

    if (orderTypeContext.isSpecialOrder || orderTypeContext.isInquiryOrder) {
      requestMap.put('customForm', lookupByInternalId('275'));
    } else if (orderTypeContext.isRepairOrder) {
      requestMap.put('customForm', lookupByInternalId('158'));
    } else {
      requestMap.put('customForm', lookupByInternalId('115'));
    }

    if (orderTypeContext.isInquiryOrder) {
      requestMap.put('tranid', inquiryTranNumber);
    }

    requestMap.put('entity', lookupByInternalId(saveParams.custNsInternalId));
    requestMap.put('salesRep', lookupByInternalId(saveParams.salesRep1));
    requestMap.put('subsidiary', lookupByInternalId(saveParams.subsidiary));
    requestMap.put('location', lookupByInternalId(saveParams.location));
    requestMap.put('terms', lookupByInternalId(saveParams.termsNsInternalId));
    requestMap.put('tranDate', Helpers.toUnixSeconds(Date.today()));

    if (saveParams.dateOpened != null) {
      requestMap.put('startDate', Helpers.toUnixSeconds(saveParams.dateOpened));
    }

    if (saveParams.datePromised != null) {
      requestMap.put('endDate', Helpers.toUnixSeconds(saveParams.datePromised));
    }

    if (String.isNotBlank(saveParams.soNsInternalId)) {
      requestMap.put('internalId', saveParams.soNsInternalId);
    }

    if (String.isNotBlank(saveParams.memo)) {
      requestMap.put('memo', saveParams.memo);
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
      new Map<String, Object>{ 'customField' => buildCustomFields(saveParams) }
    );

    Map<String, Object> itemList = new Map<String, Object>{
      'item' => buildItemList(
        saveParams.orderType,
        lineItems,
        saveParams.location
      )
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
    SalesOrderParamModel.SalesOrderSaveParam saveParams
  ) {
    List<Object> customFields = new List<Object>();

    SalesOrderTypeContext orderTypeContext = SalesOrderTypeContext.fromOrderType(
      saveParams.orderType
    );

    String salesRep2 = saveParams.salesRep2;
    Date specialOrderDate = saveParams.specialDate;
    Date needByDate = saveParams.needByDate;
    String specialOrderItemType = saveParams.specialOrderItemType;
    String specialOrderVendor = saveParams.specialOrderVendor;
    String specialOrderRequestedVendor = saveParams.specialOrderRequestedVendor;
    String specialOrderComments = saveParams.specialOrderComments;
    String specialOrderNotes = saveParams.specialOrderNotes;
    String specialOrderMemoOrSold = saveParams.specialOrderMemoOrSold;
    String repairType = saveParams.repairType;
    String repairStation = saveParams.repairStation;
    String repairPerson = saveParams.repairPerson;
    String repairLocation = saveParams.repairLocation;
    String repairVendor = saveParams.repairVendor;
    String shipRepairTo = saveParams.shipRepairTo;
    String phoneNumber = saveParams.phoneNumber;
    String itemValue = saveParams.itemValue;
    String repairDescription = saveParams.repairDescription;
    String extendedDescription = saveParams.extendedDescription;
    Date dateOpened = saveParams.dateOpened;
    Date datePromised = saveParams.datePromised;
    Boolean isEstimateRequired = saveParams.isEstimateRequired;
    Boolean isEstimateRequiredOverAmt = saveParams.isEstimateRequiredOverAmt;
    String requiredAmt = saveParams.requiredAmt;
    String inquiryModel = saveParams.inquiryModel;
    String inquiryName = saveParams.inquiryName;
    String inquiryLink = saveParams.inquiryLink;
    String inquiryPersonalMsg = saveParams.inquiryPersonalMsg;
    Boolean inquiryIsSendEmail = saveParams.inquiryIsSendEmail;
    Boolean inquiryIsPrority = saveParams.inquiryIsPrority;
    Boolean inquiryIsOpenDial = saveParams.inquiryIsOpenDial;
    String inquiryId = saveParams.inquiryId;
    String fileIds = saveParams.fileIds;

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

      if (String.isNotBlank(specialOrderVendor)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_special_order_vendor',
            'valueLookup' => lookupByInternalId(specialOrderVendor)
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
            'scriptId' => 'custbody_inquiry_priority_ckbox',
            'value' => inquiryIsPrority
          }
        );
      }

      if (inquiryIsOpenDial != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'boolean',
            'scriptId' => 'custbody_rolex_open_dial_ckbox',
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

      if (inquiryIsSendEmail != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'boolean',
            'scriptId' => 'custbody_initial_email_check',
            'value' => inquiryIsSendEmail
          }
        );
      }
    }

    if (orderTypeContext.isRepairOrder) {
      customFields.add(
        new Map<String, Object>{
          'fieldType' => 'boolean',
          'scriptId' => 'custbody_repair_order',
          'value' => true
        }
      );

      if (String.isNotBlank(repairType)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody1',
            'valueLookup' => lookupByInternalId(repairType)
          }
        );
      }

      if (String.isNotBlank(repairStation)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_repair_station',
            'valueLookup' => lookupByInternalId(repairStation)
          }
        );
      }

      if (String.isNotBlank(repairPerson)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_repair_person',
            'valueLookup' => lookupByInternalId(repairPerson)
          }
        );
      }

      if (String.isNotBlank(repairLocation)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_repair_location',
            'valueLookup' => lookupByInternalId(repairLocation)
          }
        );
      }

      if (String.isNotBlank(repairVendor)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_repair_vendor',
            'valueLookup' => lookupByInternalId(repairVendor)
          }
        );
      }

      if (String.isNotBlank(shipRepairTo)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'select',
            'scriptId' => 'custbody_shiprepairto',
            'valueLookup' => lookupByInternalId(shipRepairTo)
          }
        );
      }

      if (String.isNotBlank(phoneNumber)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_contact_number',
            'value' => phoneNumber
          }
        );
      }

      if (String.isNotBlank(itemValue)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody2',
            'value' => itemValue
          }
        );
      }

      if (String.isNotBlank(repairDescription)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_repair_description',
            'value' => repairDescription
          }
        );
      }

      if (String.isNotBlank(extendedDescription)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_extended_description',
            'value' => extendedDescription
          }
        );
      }

      if (dateOpened != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'date',
            'scriptId' => 'startdate',
            'value' => Helpers.toUnixSeconds(dateOpened)
          }
        );
      }

      if (datePromised != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'date',
            'scriptId' => 'enddate',
            'value' => Helpers.toUnixSeconds(datePromised)
          }
        );
      }

      if (isEstimateRequired != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'boolean',
            'scriptId' => 'custbody_estimate_req',
            'value' => isEstimateRequired
          }
        );
      }

      if (isEstimateRequiredOverAmt != null) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'boolean',
            'scriptId' => 'custbody_estimate_over_amt',
            'value' => isEstimateRequiredOverAmt
          }
        );
      }

      if (String.isNotBlank(requiredAmt)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_over_amt',
            'value' => requiredAmt
          }
        );
      }

      if (String.isNotBlank(fileIds)) {
        customFields.add(
          new Map<String, Object>{
            'fieldType' => 'string',
            'scriptId' => 'custbody_sf_file_ids',
            'value' => fileIds
          }
        );
      }
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
        'rate' => String.isBlank(lineItem.rate) ? '0' : lineItem.rate
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
