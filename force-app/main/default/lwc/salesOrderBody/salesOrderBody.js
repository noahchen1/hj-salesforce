import { LightningElement, api } from "lwc";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchVendor from "@salesforce/apex/FilterDataController.searchVendor";

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
  @api specialOrderItemType;
  @api specialOrderVendor;
  @api specialOrderRequestedVendor;
  @api specialOrderComments;
  @api specialOrderNotes;
  @api specialOrderMemoOrSold;
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

  get specialItemTypeOptions() {
    return [
      { label: "Bridal", value: "101" },
      { label: "Designer", value: "1" },
      { label: "Giftware", value: "2" },
      { label: "Jewelry", value: "3" },
      { label: "Watch", value: "4" },
      { label: "Watch Strap", value: "5" },
      { label: "Rolex", value: "6" },
      { label: "Patek", value: "7" }
    ];
  }

  get memoOrSoldOptions() {
    return [
      { label: "Memo", value: "1" },
      { label: "Sold", value: "2" }
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

    const searchFn =
      type === "customer"
        ? searchCustomer
        : ["salesRep1", "salesRep2"].includes(type)
          ? searchSalesRep
          : type === "specialOrderVendor"
            ? searchVendor
            : null;

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
    } else if (type === "salesRep1" || type === "salesRep2") {
      this.dispatchEvent(
        new CustomEvent("salesrepselect", { detail: { type, nsId } })
      );
    } else if (type === "specialOrderVendor") {
      this.dispatchEvent(
        new CustomEvent("specialordervendorselect", { detail: { type, nsId } })
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
