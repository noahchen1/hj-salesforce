import { LightningElement, wire, api } from "lwc";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import saveCustomer from "@salesforce/apex/CustomerController.saveCustomer";
import getObjectName from "@salesforce/apex/SalesOrderController.getObjectName";
import getCustomerData from "@salesforce/apex/CustomerController.getCustomerData";
import getValue from "@salesforce/apex/DataService.getValue";
import { isBlank, formatCountry, toCountryEnum } from "c/utils";

export default class NsAddressForm extends LightningElement {
  @api recordId;

  custNsInternalId = null;
  addressNsInternalId = null;
  isLoading = false;
  country = null;
  countryEnum = null;
  attention = null;
  addressee = null;
  zipcode = null;
  city = null;
  state = null;
  address1 = null;
  address2 = null;

  countryOptions = [];
  stateOptions = [];

  allStateValues = [];
  stateControllerValues = {};

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  objectInfo;

  @wire(getPicklistValuesByRecordType, {
    objectApiName: ACCOUNT_OBJECT,
    recordTypeId: "$objectInfo.data.defaultRecordTypeId"
  })
  wiredPicklists({ data, error }) {
    if (data) {
      const countryField = data.picklistFieldValues.BillingCountryCode;
      const stateField = data.picklistFieldValues.BillingStateCode;

      this.countryOptions = countryField.values.map((v) => ({
        label: v.label,
        value: v.value
      }));

      this.allStateValues = stateField.values;
      this.stateControllerValues = stateField.controllerValues;

      this.buildStateOptions();
    } else if (error) {
      console.error(error);
    }
  }

  @wire(getObjectName, { recordId: "$recordId" })
  async handleObjName({ data, error }) {
    if (data) {
      if (data === "Account") {
        console.log("launching from account!");
      } else {
        try {
          const results = await getValue({
            recordName: "breadwinner_ns__BW_Address__c",
            fieldNames: [
              "breadwinner_ns__Entity_InternalId__c",
              "breadwinner_ns__InternalId__c"
            ],
            recordId: this.recordId
          });

          if (results.breadwinner_ns__Entity_InternalId__c) {
            this.custNsInternalId =
              results.breadwinner_ns__Entity_InternalId__c;
          }

          if (results.breadwinner_ns__InternalId__c) {
            this.addressNsInternalId = results.breadwinner_ns__InternalId__c;
          }

          this.loadAddress();
        } catch (err) {
          console.error(err);
        }
      }
    } else if (error) {
      console.error("Error fetching record type", error);
    }
  }

  get isSelectableState() {
    return this.stateOptions.length > 0;
  }

  get isStateDisabled() {
    return this.country === null;
  }

  handleComboboxChange(e) {
    const { name, value } = e.target;

    this[name] = value;

    if (name === "country") {
      const selected = this.countryOptions.find((opt) => opt.value === value);
      const selectedText = selected ? selected.label : null;

      this.countryEnum = toCountryEnum(selectedText);
      this.state = null;
      this.buildStateOptions();
    }
  }

  handleInputChange(e) {
    const type = e.target.dataset.type;
    const value = e.target.value;

    this[type] = value;
  }

  async loadAddress() {
    try {
      const data = await getCustomerData({
        custNsInternalId: this.custNsInternalId
      });

      const selectedAddresses = data.Addresses.filter(
        (address) => address.internalId === this.addressNsInternalId
      );

      if (selectedAddresses.length > 0) {
        const selectedAddress = selectedAddresses[0];

        this.addressee = selectedAddress.addressee;
        this.address1 = selectedAddress.addr1;
        this.address2 = selectedAddress.addr2;
        this.zipcode = selectedAddress.zip;
        this.city = selectedAddress.city;
        this.attention = selectedAddress.attention;

        this.setCountryAndState(selectedAddress.country, selectedAddress.state);
      }
    } catch (err) {
      console.error(err.message);
    }
  }

  async saveAddress() {
    try {
      const addressPaylod = {
        internalId: this.addressNsInternalId,
        country: this.countryEnum,
        attention: this.attention,
        addressee: this.addressee,
        zip: this.zipcode,
        city: this.city,
        state: this.state,
        addr1: this.address1,
        addr2: this.address2
      };

      console.log(JSON.stringify(addressPaylod));

      const result = await saveCustomer({
        custNsInternalId: this.custNsInternalId,
        addressJson: JSON.stringify(addressPaylod)
      });

      console.log(JSON.stringify(result));
    } catch (err) {
      console.error("Failed to save customer!");
      console.error(err);
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);

      throw err;
    }
  }

  buildStateOptions() {
    if (!this.country || !this.stateControllerValues[this.country]) {
      this.stateOptions = [];
      this.state = null;

      return;
    }

    const countryKey = this.stateControllerValues[this.country];

    this.stateOptions = this.allStateValues
      .filter((state) => state.validFor.includes(countryKey))
      .map((state) => ({ label: state.label, value: state.value }));
  }

  setCountryAndState(country, state) {
    if (isBlank(country) || this.countryOptions.length === 0) {
      return;
    }

    const normalizedCountry = formatCountry(country);

    const countryOption = this.countryOptions.find(
      (option) => option.label === normalizedCountry
    );

    if (countryOption) {
      this.country = countryOption.value;
      this.countryEnum = toCountryEnum(countryOption.label);
      this.buildStateOptions();
    }

    if (!isBlank(state)) {
      console.log(JSON.stringify(this.stateOptions));
      if (!this.isSelectableState) {
        this.state = state;

        return;
      }

      const stateOption = this.stateOptions.find(
        (option) => option.value === state
      );

      if (stateOption) {
        this.state = stateOption.value;
      }
    }
  }
}
