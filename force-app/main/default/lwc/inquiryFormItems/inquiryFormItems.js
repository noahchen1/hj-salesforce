import { LightningElement, api } from "lwc";

export default class InquiryFormItems extends LightningElement {
  @api sectionTitle = "Watch Fields";
  @api modelLabel;
  @api isModelRequired;
  @api nameLabel;
  @api isNameRequired;
  @api linkLabel;
  @api isLinkRequired;

  model = "";
  name = "";
  link = "";
  isPriority = false;
  isOpenDial = false;
  showFieldsToggle = false;

  @api
  get toggleFieldsVisible() {
    return this.showFieldsToggle;
  }

  set toggleFieldsVisible(value) {
    this.showFieldsToggle = value;
  }

  // renderedCallback() {
  //   console.log(JSON.stringify(this.showFieldsToggle));
  //   console.log("getter below:");
  //   console.log(JSON.stringify(this.areFieldsVisisble));
  // }

  handleInputChange(e) {
    const type = e.target.dataset.type;
    const value = e.target.value;

    this[type] = value;
  }

  handleHeaderClick() {
    this.showFieldsToggle = !this.showFieldsToggle;
  }
}
