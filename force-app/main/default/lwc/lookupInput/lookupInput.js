import { LightningElement, track, api } from "lwc";

export default class LookupInput extends LightningElement {
  @api label = "";
  @api placeholder = "Type to search...";
  @track searchKey = "";
  @track results = [];
  @track showResults = false;
  @track dropdownStyle = "";
  @track isLoading = false;
  debounceTimer;

  @api
  setResults(results) {
    this.results = results;
    this.showResults = results && results.length > 0;
  }

  @api
  setLoading(loadingState) {
    this.isLoading = loadingState;
  }

  get showResultsOrLoading() {
    return this.showResults || this.isLoading;
  }

  get variant() {
    return this.label?.trim() ? "standard" : "label-hidden";
  }

  renderedCallback() {
    const input = this.template.querySelector("lightning-input");

    if (input) {
      const width = input.offsetWidth;

      this.dropdownStyle = `width: ${width}px;`;
    }
  }

  handleInputChange(event) {
    this.searchKey = event.target.value;

    if (this.searchKey.length <= 1) {
      this.results = [];
      this.showResults = false;
    }

    clearTimeout(this.debounceTimer);

    this.debounceTimer = setTimeout(() => {
      this.dispatchEvent(
        new CustomEvent("search", {
          detail: { searchKey: this.searchKey }
        })
      );
    }, 400);
  }

  handleFocus(e) {
    this.dispatchEvent(
      new CustomEvent("focus", {
        target: e.target
      })
    );
  }

  handleSelect(event) {
    const id = event.target.dataset.id;
    const name = event.target.dataset.name;
    const nsId = event.target.dataset.nsid;
    this.showResults = false;
    this.searchKey = name;
    this.dispatchEvent(
      new CustomEvent("select", {
        detail: { id, name, nsId }
      })
    );
  }

  disconnectedCallback() {
    clearTimeout(this.debounceTimer);
  }
}
