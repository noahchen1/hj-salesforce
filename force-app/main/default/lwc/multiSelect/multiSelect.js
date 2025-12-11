import { LightningElement, api } from "lwc";

export default class MultiSelect extends LightningElement {
  @api label;
  @api name;
  @api options = [];

  handleChange(e) {
    const selected = Array.from(e.target.selectedOptions).map((o) => o.value);
    this.dispatchEvent(
      new CustomEvent("change", { detail: { value: selected } })
    );
  }
}
