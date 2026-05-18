import { LightningElement, api } from "lwc";
import getParentByVendorNum from "@salesforce/apex/DataService.getParentByVendorNum";

export default class InquiryFormItems extends LightningElement {
  @api sectionTitle = "Watch Fields";
  @api modelLabel;
  @api nameLabel;
  @api linkLabel;

  model = "";
  name = "";
  link = "";
  isPriority = false;
  isOpenDial = false;
  areFieldsVisible = false;
  isModelRequired = false;
  isNameRequired = false;
  isLinkRequired = false;

  rows = [
    {
      item: "",
      displayName: "",
      specialOrderItem: "",
      specialOrderVendorNum: "",
      quantity: "1",
      rate: "",
      amount: "",
      quotedPrice: ""
    }
  ];

  @api
  get toggleFields() {
    return this.areFieldsVisible;
  }

  set toggleFields(value) {
    this.areFieldsVisible = value;
  }

  @api
  get toggleRequireModel() {
    return this.isModelRequired;
  }

  set toggleRequireModel(value) {
    this.isModelRequired = value;
  }

  @api
  get toggleRequireName() {
    return this.isNameRequired;
  }

  set toggleRequireName(value) {
    this.isNameRequired = value;
  }

  @api
  get toggleRequireLink() {
    return this.isLinkRequired;
  }

  set toggleRequireLink(value) {
    this.isLinkRequired = value;
  }

  @api
  async getFields() {
    const itemResult = await getParentByVendorNum({ vendorNum: this.model });

    const rows = [
      {
        item: "213841",
        displayName: itemResult.displayName ?? "",
        specialOrderItem: itemResult.name ?? "",
        specialOrderVendorNum: this.model,
        quantity: "1",
        rate: itemResult.basePrice ?? "",
        amount: itemResult.basePrice ?? "",
        quotedPrice: itemResult.basePrice ?? ""
      }
    ];

    return {
      model: this.model,
      name: this.name,
      link: this.link,
      isPriority: this.isPriority,
      isOpenDial: this.isOpenDial,
      rows: rows
    };
  }

  @api
  validateFields() {
    const inputs = this.template.querySelectorAll("lightning-input");

    let isValid = true;

    inputs.forEach((field) => {
      const fieldIsValid = field.reportValidity();

      if (!fieldIsValid) {
        isValid = false;
      }
    });

    return isValid;
  }

  handleInputChange(e) {
    const type = e.target.dataset.type;
    const value = e.target.value;

    this[type] = value;
  }

  handleHeaderClick() {
    this.areFieldsVisible = !this.areFieldsVisible;
  }

  get toggleIcon() {
    return this.areFieldsVisible
      ? "utility:chevrondown"
      : "utility:chevronright";
  }
}
