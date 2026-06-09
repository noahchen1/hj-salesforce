import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { formatAddress, toCountryEnum, isBlank } from "c/utils";
import getLocationAddress from "@salesforce/apex/DataService.getLocationAddress";

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

function isAddressStateEmpty(state) {
  if (!state) {
    return true;
  }

  return Object.values(EMPTY_ADDRESS).every((_, keyIndex) => {
    const fieldName = Object.keys(EMPTY_ADDRESS)[keyIndex];

    return isBlank(state[fieldName]);
  });
}

function isAddressSnapshotEmpty(snapshot) {
  if (!snapshot) {
    return true;
  }

  const hasHeaderSelection =
    !isBlank(snapshot.selectedShippingAddress) ||
    !isBlank(snapshot.selectedBillingAddress);

  const hasFormattedAddress =
    !isBlank(snapshot.shippingAddress) || !isBlank(snapshot.billingAddress);

  const hasAddressState =
    !isAddressStateEmpty(snapshot.shippingAddressState) ||
    !isAddressStateEmpty(snapshot.billingAddressState);

  return !(hasHeaderSelection || hasFormattedAddress || hasAddressState);
}

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
    country: toCountryEnum(getFieldValue(data, COUNTRY))
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

function buildStateFromLocation(data) {
  return {
    ...EMPTY_ADDRESS,
    addressee: data?.addressee || "",
    addr1: data?.address_1 || "",
    city: data?.city || "",
    state: data?.state || "",
    zip: data?.zip || "",
    country: toCountryEnum(data?.country)
  };
}

function formatFromLocation(data) {
  return (
    data?.addressText ||
    formatAddress({
      contact: data?.addressee,
      addr1: data?.address_1,
      city: data?.city,
      state: data?.state,
      zip: data?.zip,
      country: data?.country
    })
  );
}

export default class SalesOrderAddress extends LightningElement {
  @api addressOptions = [];
  @api orderType = [];
  location = null;

  isInStorePickup = false;
  selectedShippingAddress = "";
  selectedBillingAddress = "";
  defaultShippingAddress = "";
  defaultBillingAddress = "";
  shippingAddress = "";
  billingAddress = "";
  shippingAddressState = { ...EMPTY_ADDRESS };
  billingAddressState = { ...EMPTY_ADDRESS };
  previousAddressSnapshot = null;
  isInStorePickupDisabled = false;

  emitAddressStateChange() {
    this.dispatchEvent(
      new CustomEvent("addressstatechange", {
        detail: {
          shippingAddressState: { ...this.shippingAddressState },
          billingAddressState: { ...this.billingAddressState }
        }
      })
    );
  }

  get hasPreviousAddressSnapshot() {
    return !isAddressSnapshotEmpty(this.previousAddressSnapshot);
  }

  get isAddressSelectorDisabled() {
    return this.isInStorePickup;
  }

  get isSpecialOrder() {
    return this.orderType === "special";
  }

  @api
  get selectedLocation() {
    return this.location;
  }

  set selectedLocation(value) {
    this.location = value;

    if (this.isSpecialOrder && value) {
      this.isInStorePickup = true;
      this.applyInStorePickupAddress();
    }
  }

  cacheCurrentAddressSnapshot() {
    this.previousAddressSnapshot = {
      selectedShippingAddress: this.selectedShippingAddress,
      selectedBillingAddress: this.selectedBillingAddress,
      shippingAddress: this.shippingAddress,
      billingAddress: this.billingAddress,
      shippingAddressState: { ...this.shippingAddressState },
      billingAddressState: { ...this.billingAddressState }
    };
  }

  restorePreviousAddressSnapshot() {
    if (!this.hasPreviousAddressSnapshot) {
      const hasDefaultShipping = !isBlank(this.defaultShippingAddress);
      const hasDefaultBilling = !isBlank(this.defaultBillingAddress);

      if (!hasDefaultShipping) {
        this.selectedShippingAddress = "";
        this.shippingAddress = "";
        this.shippingAddressState = { ...EMPTY_ADDRESS };
      } else {
        this.selectedShippingAddress = "";
        this.selectedShippingAddress = this.defaultShippingAddress;
      }

      if (!hasDefaultBilling) {
        this.selectedBillingAddress = "";
        this.billingAddress = "";
        this.billingAddressState = { ...EMPTY_ADDRESS };
      } else {
        this.selectedBillingAddress = "";
        this.selectedBillingAddress = this.defaultBillingAddress;
      }

      this.emitAddressStateChange();
      return;
    }

    this.selectedShippingAddress =
      this.previousAddressSnapshot.selectedShippingAddress;
    this.selectedBillingAddress =
      this.previousAddressSnapshot.selectedBillingAddress;
    this.shippingAddress = this.previousAddressSnapshot.shippingAddress;
    this.billingAddress = this.previousAddressSnapshot.billingAddress;
    this.shippingAddressState = {
      ...this.previousAddressSnapshot.shippingAddressState
    };
    this.billingAddressState = {
      ...this.previousAddressSnapshot.billingAddressState
    };
    this.previousAddressSnapshot = null;
    this.emitAddressStateChange();
  }

  async applyInStorePickupAddress() {
    if (!this.location) {
      return;
    }

    if (!this.hasPreviousAddressSnapshot) {
      this.cacheCurrentAddressSnapshot();
    }

    try {
      const results = await getLocationAddress({ nsLocationId: this.location });

      if (!this.isInStorePickup) {
        return;
      }

      const locationState = buildStateFromLocation(results);
      const locationText = formatFromLocation(results);

      this.selectedShippingAddress = "";
      this.selectedBillingAddress = "";
      this.shippingAddressState = { ...locationState };
      this.billingAddressState = { ...locationState };
      this.shippingAddress = locationText;
      this.billingAddress = locationText;
      this.emitAddressStateChange();
    } catch (error) {
      console.error("Error fetching in-store pickup address", error);
    }
  }

  @api
  applyDefaults(defaultShipping, defaultBilling) {
    this.selectedShippingAddress = defaultShipping || "";
    this.selectedBillingAddress = defaultBilling || "";
  }

  @api
  setDefaults(defaultShipping, defaultBilling) {
    this.defaultBillingAddress = defaultBilling || "";
    this.defaultShippingAddress = defaultShipping || "";
  }

  @api
  loadFromOrderData(data) {
    this.shippingAddressState = {
      ...EMPTY_ADDRESS,
      ...(data.shippingAddress || {}),
      country: toCountryEnum(data.shippingAddress?.country)
    };
    this.billingAddressState = {
      ...EMPTY_ADDRESS,
      ...(data.billingAddress || {}),
      country: toCountryEnum(data.billingAddress?.country)
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
    this.emitAddressStateChange();
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
    this.isInStorePickup = false;
    this.selectedShippingAddress = "";
    this.selectedBillingAddress = "";
    this.shippingAddress = "";
    this.billingAddress = "";
    this.defaultBillingAddress = null;
    this.defaultShippingAddress = null;
    this.shippingAddressState = { ...EMPTY_ADDRESS };
    this.billingAddressState = { ...EMPTY_ADDRESS };
    this.previousAddressSnapshot = null;
    this.emitAddressStateChange();
  }

  @wire(getRecord, {
    recordId: "$selectedShippingAddress",
    fields: ADDRESS_FIELDS
  })
  wiredShippingAddressData({ data, error }) {
    if (this.isInStorePickup) {
      return;
    }

    if (data) {
      this.shippingAddressState = buildStateFromRecord(data);
      this.shippingAddress = formatFromRecord(data);
      this.emitAddressStateChange();
    } else if (error) {
      this.shippingAddressState = { ...EMPTY_ADDRESS };
      this.shippingAddress = "";
      console.error("Error fetching shipping address", error);
      this.emitAddressStateChange();
    } else {
      this.shippingAddressState = { ...EMPTY_ADDRESS };
      this.shippingAddress = "";
      this.emitAddressStateChange();
    }
  }

  @wire(getRecord, {
    recordId: "$selectedBillingAddress",
    fields: ADDRESS_FIELDS
  })
  wiredBillingAddressData({ data, error }) {
    if (this.isInStorePickup) {
      return;
    }

    if (data) {
      this.billingAddressState = buildStateFromRecord(data);
      this.billingAddress = formatFromRecord(data);
      this.emitAddressStateChange();
    } else if (error) {
      this.billingAddressState = { ...EMPTY_ADDRESS };
      this.billingAddress = "";
      console.error("Error fetching billing address", error);
      this.emitAddressStateChange();
    } else {
      this.billingAddressState = { ...EMPTY_ADDRESS };
      this.billingAddress = "";
      this.emitAddressStateChange();
    }
  }

  handleComboboxChange(e) {
    if (this.isInStorePickup) {
      return;
    }

    this[e.target.name] = e.target.value;
    this.emitAddressStateChange();
  }

  async handleInputChange(e) {
    const isCheckBox = e.target.type === "checkbox";
    const type = e.target.dataset.type;
    const value = isCheckBox ? e.target.checked : e.target.value;

    this[type] = value;

    if (type !== "isInStorePickup") {
      return;
    }

    if (value) {
      this.isInStorePickupDisabled = true;
      await this.applyInStorePickupAddress();

      this.isInStorePickupDisabled = false;
      return;
    }

    this.restorePreviousAddressSnapshot();
  }
}
