import { LightningElement, track, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import getLocations from "@salesforce/apex/DropdownDataController.getLocations";
import searchItem from "@salesforce/apex/FilterDataController.searchItem";

export default class SalesOrderForm extends LightningElement {
  recordId;
  customer = "";
  salesRep1 = "";
  salesRep2 = "";
  item = "";
  location = "";
  locationOptions = [];

  @wire(CurrentPageReference)
  getStateParameters(pageRef) {
    if (pageRef) {
      this.recordId = pageRef.state?.c__recordId;
    }
  }

  @wire(getLocations)
  handleLocations(results) {
    this.processPicklistWire(results, "locationOptions");
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = this.template.querySelector(
      `c-lookup-input[data-type="${type}"]`
    );

    let searchFn;

    if (type === "salesRep1" || type === "salesRep2") {
      searchFn = searchSalesRep;
    } else if (type === "customer") {
      searchFn = searchCustomer;
    } else if (type === "item") {
      searchFn = searchItem;
    }

    if (searchKey.length > 1 && searchFn) {
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
      this[type] = "";
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const selectedName = e.detail.name;
    this[type] = selectedName;
  }

  handleComboboxChange(e) {
    const name = e.target.name;

    this[name] = e.target.value;
  }

  processPicklistWire({ data, error }, target) {
    if (data) {
      this[target] = [
        { label: "All", value: "" },
        ...data.map(({ label, value }) => ({ label, value }))
      ];
    } else if (error) {
      console.error(`Error fetching ${target}: `, error);
    }
  }

  renderedCallback() {
    console.log("component rerendered");
  }
}
