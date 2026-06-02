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
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import LightningAlert from "lightning/alert";

import { isBlank, formatCountry, toCountryEnum } from "c/utils";

export default class NsAddressForm extends NavigationMixin(LightningElement) {
  @api recordId;

  custNsInternalId = null;
  addressNsInternalId = null;
  isLoading = true;
  country = "US";
  countryEnum = "_unitedStates";
  attention = null;
  addressee = null;
  zipcode = null;
  city = null;
  state = null;
  address1 = null;
  address2 = null;
  isDefaultBilling = false;
  isDefaultShipping = false;

  countryOptions = [];
  stateOptions = [];

  allStateValues = [];
  stateControllerValues = {};

  isCountryLoaded = false;
  isStateLoaded = false;
  isAddressLoaded = false;

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
      this.isCountryLoaded = true;
      this.checkLoadingState();
    } else if (error) {
      console.error(error);
    }
  }

  @wire(getObjectName, { recordId: "$recordId" })
  async handleObjName({ data, error }) {
    if (data) {
      if (data === "Account") {
        try {
          const results = await getValue({
            recordName: "Account",
            fieldNames: ["NetSuiteInternalId__c"],
            recordId: this.recordId
          });

          if (results.NetSuiteInternalId__c) {
            this.custNsInternalId = results.NetSuiteInternalId__c;
          }
        } catch (err) {
          console.error(err);
        } finally {
          this.isAddressLoaded = true;
          this.checkLoadingState();
        }
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
    const isCheckBox = e.target.type === "checkbox";
    const type = e.target.dataset.type;
    const value = isCheckBox ? e.target.checked : e.target.value;

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

      console.log(JSON.stringify(selectedAddresses));

      if (selectedAddresses.length > 0) {
        const selectedAddress = selectedAddresses[0];

        this.addressee = selectedAddress.addressee;
        this.address1 = selectedAddress.addr1;
        this.address2 = selectedAddress.addr2;
        this.zipcode = selectedAddress.zip;
        this.city = selectedAddress.city;
        this.attention = selectedAddress.attention;
        this.isDefaultBilling = selectedAddress.defaultBilling;
        this.isDefaultShipping = selectedAddress.defaultShipping;

        this.setCountryAndState(selectedAddress.country, selectedAddress.state);
      }
    } catch (err) {
      console.error(err.message);
    } finally {
      this.isAddressLoaded = true;
      this.checkLoadingState();
    }
  }

  async saveAddress() {
    if (this.isLoading) return;

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
        addr2: this.address2,
        defaultBilling: this.isDefaultBilling,
        defaultShipping: this.isDefaultShipping
      };

      console.log(JSON.stringify(addressPaylod));
      this.isLoading = true;

      const result = await saveCustomer({
        custNsInternalId: this.custNsInternalId,
        addressJson: JSON.stringify(addressPaylod)
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Address Saved",
          message: "Address saved successfully!",
          variant: "success"
        })
      );

      if (this.recordId) {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: { recordId: this.recordId, actionName: "view" }
        });
      }
    } catch (err) {
      console.error("Failed to save customer!");
      console.error(err);
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);
      LightningAlert.open({
        label: "Error!",
        message: `Address was not saved, cause: ${err?.body?.message || err?.message}`,
        theme: "error"
      });
    } finally {
      this.isLoading = false;
    }
  }

  buildStateOptions() {
    if (!this.country || !this.stateControllerValues[this.country]) {
      this.stateOptions = [];
      this.state = null;
      this.isStateLoaded = true;

      return;
    }

    const countryKey = this.stateControllerValues[this.country];

    this.stateOptions = this.allStateValues
      .filter((state) => state.validFor.includes(countryKey))
      .map((state) => ({ label: state.label, value: state.value }));

    this.isStateLoaded = true;
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
      this.isCountryLoaded = true;
    }

    if (!isBlank(state)) {
      if (!this.isSelectableState) {
        this.state = state;
        this.isStateLoaded = true;

        return;
      }

      const stateOption = this.stateOptions.find(
        (option) => option.value === state
      );

      if (stateOption) {
        this.state = stateOption.value;
      }

      this.isStateLoaded = true;
    }

    this.checkLoadingState();
  }

  checkLoadingState() {
    if (this.isCountryLoaded && this.isStateLoaded && this.isAddressLoaded) {
      this.isLoading = false;
    }
  }
}
