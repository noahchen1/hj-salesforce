import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { formatAddress } from "c/utils";

import ADDRESS_INTERNAL_ID from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__InternalId__c";
import ADDRESS_TEXT from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__AddrText__c";
import ADDRESS_1 from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Addr1__c";
import ADDRESS_2 from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Addr2__c";
import ADDRESS_3 from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Addr3__c";
import ADDRESSEE from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Addressee__c";
import ATTENTION from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Attention__c";
import CITY from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__City__c";
import STATE from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__State__c";
import ZIP from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Zip__c";
import COUNTRY from "@salesforce/schema/breadwinner_ns__BW_Address__c.breadwinner_ns__Country__c";

const ADDRESS_FIELDS = [
  ADDRESS_INTERNAL_ID,
  ADDRESS_TEXT,
  ADDRESSEE,
  ADDRESS_1,
  ADDRESS_2,
  ADDRESS_3,
  ATTENTION,
  CITY,
  STATE,
  ZIP,
  COUNTRY
];

const EMPTY_ADDRESS = Object.freeze({
  internalId: "",
  addressee: "",
  attention: "",
  addr1: "",
  addr2: "",
  addr3: "",
  city: "",
  state: "",
  zip: "",
  country: ""
});

function buildStateFromRecord(data) {
  return {
    internalId: getFieldValue(data, ADDRESS_INTERNAL_ID),
    addressee: getFieldValue(data, ADDRESSEE),
    attention: getFieldValue(data, ATTENTION),
    addr1: getFieldValue(data, ADDRESS_1),
    addr2: getFieldValue(data, ADDRESS_2),
    addr3: getFieldValue(data, ADDRESS_3),
    city: getFieldValue(data, CITY),
    state: getFieldValue(data, STATE),
    zip: getFieldValue(data, ZIP),
    country: getFieldValue(data, COUNTRY)
  };
}

function formatFromRecord(data) {
  return formatAddress({
    contact: getFieldValue(data, ADDRESSEE),
    addr1: getFieldValue(data, ADDRESS_1),
    addr2: getFieldValue(data, ADDRESS_2),
    addr3: getFieldValue(data, ADDRESS_3),
    city: getFieldValue(data, CITY),
    state: getFieldValue(data, STATE),
    zip: getFieldValue(data, ZIP),
    country: getFieldValue(data, COUNTRY)
  });
}

export default class SalesOrderAddress extends LightningElement {
  @api addressOptions = [];

  selectedShippingAddress = "";
  selectedBillingAddress = "";
  shippingAddress = "";
  billingAddress = "";
  shippingAddressState = { ...EMPTY_ADDRESS };
  billingAddressState = { ...EMPTY_ADDRESS };

  @api
  applyDefaults(defaultShipping, defaultBilling) {
    this.selectedShippingAddress = defaultShipping || "";
    this.selectedBillingAddress = defaultBilling || "";
  }

  @api
  loadFromOrderData(data) {
    this.shippingAddressState = {
      ...EMPTY_ADDRESS,
      ...(data.shippingAddress || {})
    };
    this.billingAddressState = {
      ...EMPTY_ADDRESS,
      ...(data.billingAddress || {})
    };

    this.shippingAddress = formatAddress({
      contact: data.shippingAddress?.addressee,
      addr1: data.shippingAddress?.addr1,
      addr2: data.shippingAddress?.addr2,
      addr3: data.shippingAddress?.addr3,
      city: data.shippingAddress?.city,
      state: data.shippingAddress?.state,
      zip: data.shippingAddress?.zip,
      country: data.shippingAddress?.country
    });

    this.billingAddress = formatAddress({
      contact: data.billingAddress?.addressee,
      addr1: data.billingAddress?.addr1,
      addr2: data.billingAddress?.addr2,
      addr3: data.billingAddress?.addr3,
      city: data.billingAddress?.city,
      state: data.billingAddress?.state,
      zip: data.billingAddress?.zip,
      country: data.billingAddress?.country
    });
  }

  @api
  getAddressState() {
    return {
      shippingAddressState: { ...this.shippingAddressState },
      billingAddressState: { ...this.billingAddressState }
    };
  }

  @api
  reset() {
    this.selectedShippingAddress = "";
    this.selectedBillingAddress = "";
    this.shippingAddress = "";
    this.billingAddress = "";
    this.shippingAddressState = { ...EMPTY_ADDRESS };
    this.billingAddressState = { ...EMPTY_ADDRESS };
  }

  @wire(getRecord, {
    recordId: "$selectedShippingAddress",
    fields: ADDRESS_FIELDS
  })
  wiredShippingAddressData({ data, error }) {
    if (data) {
      this.shippingAddressState = buildStateFromRecord(data);
      this.shippingAddress = formatFromRecord(data);
    } else if (error) {
      this.shippingAddressState = { ...EMPTY_ADDRESS };
      this.shippingAddress = "";
      console.error("Error fetching shipping address", error);
    } else {
      this.shippingAddressState = { ...EMPTY_ADDRESS };
      this.shippingAddress = "";
    }
  }

  @wire(getRecord, {
    recordId: "$selectedBillingAddress",
    fields: ADDRESS_FIELDS
  })
  wiredBillingAddressData({ data, error }) {
    if (data) {
      this.billingAddressState = buildStateFromRecord(data);
      this.billingAddress = formatFromRecord(data);
    } else if (error) {
      this.billingAddressState = { ...EMPTY_ADDRESS };
      this.billingAddress = "";
      console.error("Error fetching billing address", error);
    } else {
      this.billingAddressState = { ...EMPTY_ADDRESS };
      this.billingAddress = "";
    }
  }

  handleComboboxChange(e) {
    this[e.target.name] = e.target.value;
  }
}
