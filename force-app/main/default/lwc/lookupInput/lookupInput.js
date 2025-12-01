import { LightningElement, track, api } from "lwc";

export default class LookupInput extends LightningElement {
  @api label = "Search";
  @api placeholder = "Type to search...";
  @track searchKey = "";
  @track results = [];
  @track showResults = false;

  async handleInputChange(event) {
    this.searchKey = event.target.value;
    if (this.searchKey.length >= this.minLength) {
      this.dispatchEvent(
        new CustomEvent("search", {
          detail: { searchKey: this.searchKey }
        })
      );
    } else {
      this.results = [];
      this.showResults = false;
    }
  }

  @api
  setResults(results) {
    this.results = results;
    this.showResults = results && results.length > 0;
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

// handleCustomerSearch(event) {
//   const searchKey = event.detail.searchKey;
//   this.template.querySelector('c-lookup-input').setResults(results);
// }

// handleCustomerSelect(event) {
//   const { id, name } = event.detail;
// }
