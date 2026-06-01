import { LightningElement, wire } from "lwc";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";

export default class NsAddressForm extends LightningElement {
  isLoading = false;
  country = null;
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

  get isSelectableState() {
    return this.stateOptions.length > 0;
  }

  get isStateDisabled() {
    return this.country === null;
  }

  // renderedCallback() {
  //   console.log(JSON.stringify(this.objectInfo));
  // }

  handleComboboxChange(e) {
    const { name, value } = e.target;
    this[name] = value;

    if (name === "country") {
      this.state = null;
      this.buildStateOptions();
    }
  }

  saveAddress() {
    console.log("saving in progress!");
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
}
