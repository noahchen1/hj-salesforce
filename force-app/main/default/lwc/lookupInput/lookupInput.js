import { LightningElement, track, api } from "lwc";

export default class LookupInput extends LightningElement {
  @api label = "Search";
  @api placeholder = "Type to search...";
  @track searchKey = "";
  @track results = [];
  @track showResults = false;
  @track dropdownStyle = "";

  @api
  setResults(results) {
    this.results = results;
    this.showResults = results && results.length > 0;
  }

  renderedCallback() {
    const input = this.template.querySelector("lightning-input");

    if (input) {
      const width = input.offsetWidth;

      this.dropdownStyle = `width: ${width}px;`;
    }
  }

  async handleInputChange(event) {
    this.searchKey = event.target.value;

    if (this.searchKey.length <= 1) {
      this.results = [];
      this.showResults = false;
    }

    this.dispatchEvent(
      new CustomEvent("search", {
        detail: { searchKey: this.searchKey }
      })
    );
  }

  handleSelect(event) {
    const id = event.target.dataset.id;
    const name = event.target.dataset.name;
    this.showResults = false;
    this.searchKey = name;
    this.dispatchEvent(
      new CustomEvent("select", {
        detail: { id, name }
      })
    );
  }
}
