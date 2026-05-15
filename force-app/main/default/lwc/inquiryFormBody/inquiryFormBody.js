import { LightningElement, wire, api } from "lwc";
import getLocations from "@salesforce/apex/DropdownDataController.getLocations";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import { processPicklistData } from "c/salesOrderUtils";

export default class InquiryFormBody extends LightningElement {
  customer = "";
  date = new Date().toISOString();
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  locationOptions = [];
  personalization = "";
  comments = "";

  isLoaded = false;
  isLocationLoaded = false;

  @wire(getLocations)
  handleLocations({ data, error }) {
    if (error) {
      console.error("Error fetching location options: ", error);

      this.locationOptions = [{ label: "Select", value: "" }];
      this.isLocationLoaded = true;
      this.checkLoadingState();
      return;
    }

    const { options } = processPicklistData(data);
    this.locationOptions = options;
    this.isLocationLoaded = true;
    this.checkLoadingState();
  }

  @api
  getFields() {
    return {
      customer: this.customer,
      date: this.date,
      salesRep1: this.salesRep1,
      salesRep2: this.salesRep2,
      location: this.location,
      personalization: this.personalization,
      comments: this.comments,
      needByDate: this.date
    };
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;
    const isSalesRepFields = type === "salesRep1" || type === "salesRep2";

    const searchFn =
      type === "customer"
        ? searchCustomer
        : isSalesRepFields
          ? searchSalesRep
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
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const { id, nsId } = e.detail;

    this[type] = nsId;
  }

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    this[name] = value;
  }

  handleInputChange(e) {
    const type = e.target.dataset.type;
    const value = e.target.value;

    this[type] = value;
  }

  checkLoadingState() {
    if (this.isLocationLoaded) {
      this.isLoading = false;
    }
  }
}
