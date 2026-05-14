import { LightningElement, wire } from "lwc";
import getLocations from "@salesforce/apex/DropdownDataController.getLocations";
import { processPicklistData } from "c/salesOrderUtils";

export default class InquiryFormBody extends LightningElement {
  location = "";
  locationOptions = [];

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

  async handleLookupSearch() {}

  handleLookupSelect() {}

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
