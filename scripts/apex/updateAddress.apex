// Map<String, Object> filters = new Map<String, Object>();
// filters.put('internalId', '315029');

// Map<String, Object> filterMap = new Map<String, Object>();
// filterMap.put('where', new Map<String, Object>{ 'keyValueMap' => filters });

// Map<String, Object> requestJSONMap = new Map<String, Object>();
// requestJSONMap.put('customParameters', filterMap);

// String reqJSON = JSON.serialize(requestJSONMap);

// Map<String, Object> reqObj = new Map<String, Object>();
// reqObj.put('version', '1.0');
// reqObj.put('action', 'readCustomer');
// reqObj.put('requestJSON', reqJSON);

// Map<String, Object> resp = breadwinner_ns.BreadwinnerNetSuiteAPI.call(reqObj);
// System.debug(resp);

//------------------------update---------------------------//

Map<String, Object> nsCustomer = new Map<String, Object>();
nsCustomer.put('internalId', '43321');

//  Initialize the Customer Addresses
List<Object> addressBookList = new List<Object>();
Map<String, Object> addressBook = new Map<String, Object>();
Map<String, Object> addressbookAddress = new Map<String, Object>();
addressbookAddress.put('addr1', '610 W Custis Ave');
addressbookAddress.put('addr2', 'APT 50');
addressbookAddress.put('city', 'Alexandria');
addressbookAddress.put('state', 'VA');
addressbookAddress.put('country', '_unitedStates');
addressbookAddress.put('zip', '22301');

addressBook.put('addressbookAddress', addressbookAddress);
addressBook.put('internalId', '298822');
addressBookList.add(addressBook);

nsCustomer.put(
  'addressbookList',
  new Map<String, Object>{
    'addressbook' => addressBookList,
    'replaceAll' => false
  }
);

//  Initialize the RequestJSON Data to be passed.
Map<String, Object> requestJSONMap = new Map<String, Object>();
requestJSONMap.put('customers', new List<Object>{ nsCustomer });
String reqJSON = JSON.serialize(requestJSONMap);

Map<String, Object> reqObj = new Map<String, Object>();
reqObj.put('version', '1.0');
reqObj.put('action', 'updateCustomer');
reqObj.put('requestJSON', reqJSON);

//  Place a request to Breadwinner Global API
Map<String, Object> resp = breadwinner_ns.BreadwinnerNetSuiteAPI.call(reqObj);
System.debug(resp);

//-----------add new address-----------------//


Map<String, Object> nsCustomer = new Map<String, Object>();
nsCustomer.put('internalId', '11934');

//  Initialize the Customer Addresses
List<Object> addressBookList = new List<Object>();
Map<String, Object> addressBook = new Map<String, Object>();
Map<String, Object> addressbookAddress = new Map<String, Object>();
addressbookAddress.put('addr1', '610 W Custis Ave');
addressbookAddress.put('addr2', 'APT 50');
addressbookAddress.put('city', 'Alexandria');
addressbookAddress.put('state', 'VA');
addressbookAddress.put('country', '_unitedStates');
addressbookAddress.put('zip', '22301');

addressBook.put('addressbookAddress', addressbookAddress);
addressBookList.add(addressBook);

nsCustomer.put(
  'addressbookList',
  new Map<String, Object>{
    'addressbook' => addressBookList,
    'replaceAll' => false
  }
);

//  Initialize the RequestJSON Data to be passed.
Map<String, Object> requestJSONMap = new Map<String, Object>();
requestJSONMap.put('customers', new List<Object>{ nsCustomer });
String reqJSON = JSON.serialize(requestJSONMap);

Map<String, Object> reqObj = new Map<String, Object>();
reqObj.put('version', '1.0');
reqObj.put('action', 'updateCustomer');
reqObj.put('requestJSON', reqJSON);

//  Place a request to Breadwinner Global API
Map<String, Object> resp = breadwinner_ns.BreadwinnerNetSuiteAPI.call(reqObj);
System.debug(resp);