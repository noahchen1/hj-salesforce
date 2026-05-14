import { LightningElement, api } from "lwc";

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

  @api
  get toggleFields() {
    return this.areFieldsVisible;
  }

  set toggleFields(value) {
    console.log(value);
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
