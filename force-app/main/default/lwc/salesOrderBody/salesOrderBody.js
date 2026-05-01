import { LightningElement, api } from "lwc";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";

export default class SalesOrderBody extends LightningElement {
  @api subsidiaryOptions = [];
  @api locationOptions = [];
  @api date;
  @api subsidiary;
  @api location;
  @api memo;
  @api orderType;
  @api specialDate;
  @api needByDate;
  @api isOrderTypeDisabled;

  get isLocationDisabled() {
    return !this.subsidiary;
  }

  get orderTypeOptions() {
    return [
      { label: "Sales Order", value: "sales" },
      { label: "Special Order", value: "special" },
      { label: "Repair Order", value: "repair" }
    ];
  }

  get isSalesOrder() {
    return this.orderType === "sales";
  }

  get isSpecialOrder() {
    return this.orderType === "special";
  }

  get isRepairOrder() {
    return this.orderType === "repair";
  }

  @api
  setLookupValue(type, name) {
    const lookup = this.template.querySelector(
      `c-lookup-input[data-type="${type}"]`
    );

    if (lookup) lookup.setSelected(name);
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;

    const searchFn = type === "customer" ? searchCustomer : searchSalesRep;

    if (searchKey.length > 1) {
      input.setLoading(true);
      try {
        const results = await searchFn({ input: searchKey });
        input.setResults(results);
      } catch (error) {
        console.error(error);
        input.setResults([]);
      } finally {
        input.setLoading(false);
      }
    } else {
      input.setResults([]);
      this.dispatchEvent(
        new CustomEvent("fieldclear", { detail: { field: type } })
      );
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const { id, nsId } = e.detail;

    if (type === "customer") {
      this.dispatchEvent(
        new CustomEvent("customerselect", { detail: { id, nsId } })
      );
    } else {
      this.dispatchEvent(
        new CustomEvent("salesrepselect", { detail: { type, nsId } })
      );
    }
  }

  handleInputChange(e) {
    const type = e.target.dataset.type;
    this.dispatchEvent(
      new CustomEvent("fieldchange", {
        detail: { field: type, value: e.target.value }
      })
    );
  }

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;
    this.dispatchEvent(
      new CustomEvent("comboboxchange", { detail: { name, value } })
    );
  }
}
