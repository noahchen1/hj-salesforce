import { LightningElement, api } from "lwc";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchVendor from "@salesforce/apex/FilterDataController.searchVendor";
import searchNetsuiteContact from "@salesforce/apex/FilterDataController.searchNetsuiteContact";
import { VENDOR_REQUIRED_ITEM_TYPES } from "c/salesOrderUtils";

export default class SalesOrderBody extends LightningElement {
  @api subsidiaryOptions = [];
  @api locationOptions = [];
  @api date;
  @api subsidiary;
  @api location;
  @api memo;
  @api orderType;
  @api paymentTerm;
  @api specialDate;
  @api needByDate;
  @api specialOrderItemType;
  @api specialOrderVendor;
  @api specialOrderRequestedVendor;
  @api specialOrderComments;
  @api specialOrderNotes;
  @api specialOrderMemoOrSold;
  @api isOrderTypeDisabled;
  @api isSubsidiaryDisbaled;
  @api specialOrderStatus;
  @api repairType;
  @api repairStation;
  @api repairPerson;
  @api repairLocation;
  @api repairVendor;
  @api phoneNumber;
  @api isEstimateRequired;
  @api isEstimateRequiredOverAmt;
  @api requiredAmt;
  @api shipRepairTo;
  @api repairDescription;
  @api extendedDescription;
  @api dateOpened;
  @api datePromised;

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

  @api
  get paymentTermOptions() {
    return [
      { label: "NET 10", value: "87" },
      { label: "NET 120", value: "90" },
      { label: "NET 150", value: "98" },
      { label: "NET 180", value: "99" },
      { label: "NET 210", value: "100" },
      { label: "NET 240", value: "101" },
      { label: "NET 30", value: "81" },
      { label: "NET 45", value: "94" },
      { label: "NET 5", value: "120" },
      { label: "NET 75", value: "133" },
      { label: "NET 90", value: "95" },
      { label: "NO TERM", value: "149" },
      { label: "Net 15", value: "1" },
      { label: "Net 20", value: "166" },
      { label: "Net 30", value: "2" },
      { label: "Net 60", value: "3" },
      { label: "Net 7", value: "160" }
    ];
  }

  @api
  get repairTypeOptions() {
    return [
      { label: "Select", value: "" },
      { label: "Appraisal", value: "5" },
      { label: "CPO", value: "14" },
      { label: "Custom", value: "2" },
      { label: "Engraving", value: "9" },
      { label: "Inventory Work", value: "12" },
      { label: "Jewelry Repair", value: "3" },
      { label: "New Purchase", value: "7" },
      { label: "Rolex Overhaul", value: "6" },
      { label: "Stock Repair", value: "8" },
      { label: "Strap Order", value: "11" },
      { label: "Warranty", value: "10" },
      { label: "Watch Battery", value: "4" },
      { label: "Watch Repair", value: "1" }
    ];
  }

  @api
  get repairStationOptions() {
    return [
      { label: "Select", value: "" },
      { label: "1 Incoming Drawer", value: "6" },
      { label: "Appraisal", value: "44" },
      { label: "Call Box", value: "17" },
      { label: "Engraving", value: "113" },
      { label: "Estimate Approved by Client", value: "23" },
      { label: "Finished", value: "128" },
      { label: "In Estimate", value: "30" },
      { label: "Insignia Division", value: "31" },
      { label: "Inventory Work (99)", value: "8" },
      { label: "Jewelers Lab", value: "114" },
      { label: "Jewelry Service Coordination", value: "56" },
      { label: "Manager - Issue with Repair", value: "41" },
      { label: "Outside Vendor", value: "48" },
      { label: "Oversized", value: "120" },
      { label: "Oversized Basement", value: "50" },
      { label: "Ready for Pick Up", value: "52" },
      { label: "Ready to Ship", value: "40" },
      { label: "Requested Back RNW", value: "79" },
      { label: "Return No Work", value: "53" },
      { label: "Returned", value: "129" },
      { label: "Rolex Boutique", value: "117" },
      { label: "Ship - Approved by Client", value: "46" },
      { label: "Ship - Waiting for Customer Approval", value: "80" },
      { label: "Store 5 Box Ready to Send Over", value: "121" },
      { label: "Store 9 Box Ready to Send Over", value: "59" },
      { label: "Store 99 Box Ready to Send Over", value: "60" },
      { label: "Store9", value: "130" },
      { label: "Strap Ordered", value: "61" },
      { label: "Transfer to Store 2 from Store 3", value: "125" },
      { label: "Transfer to Store 2 from Store 4", value: "126" },
      { label: "Transfer to Store 2 from Store 4", value: "63" },
      { label: "Transfer to Store 2 from Store 9", value: "124" },
      { label: "Transfer to Store 3 from Store 2", value: "64" },
      { label: "Transfer to Store 3 from Store 4", value: "65" },
      { label: "Transfer to Store 3 from Store 9", value: "66" },
      { label: "Transfer to Store 4 from Store 2", value: "67" },
      { label: "Transfer to Store 4 from Store 3", value: "122" },
      { label: "Transfer to Store 4 from Store 3", value: "68" },
      { label: "Transfer to Store 4 from Store 99", value: "69" },
      { label: "Transfer to Store 5 from Store 3", value: "70" },
      { label: "Transfer to Store 9 from Store 2", value: "127" },
      { label: "Transfer to Store 9 from Store 4", value: "123" },
      { label: "Transfer to Store 99 from Store 2", value: "71" },
      { label: "Transfer to Store 99 from Store 3", value: "72" },
      { label: "Transfer to Store 99 from Store 4", value: "73" },
      { label: "Unclaimed", value: "47" },
      { label: "Waiting for Estimate Approval", value: "77" },
      { label: "Waiting for Hank", value: "27" },
      { label: "Waiting for Jewelry Part", value: "78" },
      { label: "Watch - Battery", value: "112" },
      { label: "Watch - Done and in Final Testing", value: "82" },
      { label: "Watch - In Service", value: "118" },
      { label: "Watch - Polish", value: "115" },
      { label: "Watch - Waiting for Part", value: "81" },
      { label: "With Sales", value: "119" }
    ];
  }

  @api
  get repairLocationOptions() {
    return [
      { label: "Select", value: "" },
      { label: "In-House", value: "1" },
      { label: "Outsourced", value: "2" }
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

  get isVendorRequiredItemType() {
    return VENDOR_REQUIRED_ITEM_TYPES.has(this.specialOrderItemType);
  }

  get isSpecialOrderVendorRequired() {
    return this.isVendorRequiredItemType;
  }

  get isSpecialOrderVendorDisabled() {
    return !this.isVendorRequiredItemType;
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
        : ["salesRep1", "salesRep2", "repairPerson"].includes(type)
          ? searchSalesRep
          : ["specialOrderVendor", "repairVendor"].includes(type)
            ? searchVendor
            : type === "shipRepairTo"
              ? searchNetsuiteContact
              : null;

    if (searchKey.length > 1) {
      if (!searchFn) {
        input.setResults([]);
        return;
      }

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

  @api
  validateFields() {
    const inputs = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("lightning-combobox"),
      ...this.template.querySelectorAll("lightning-textarea"),
      ...this.template.querySelectorAll("c-lookup-input")
    ];

    let isValid = true;

    inputs.forEach((field) => {
      const fieldIsValid = field.reportValidity();

      if (!fieldIsValid) {
        isValid = false;
      }
    });

    return isValid;
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
        new CustomEvent("fieldchange", { detail: { field: type, value: nsId } })
      );
    }
  }

  handleInputChange(e) {
    const isCheckBox = e.target.type === "checkbox";
    const type = e.target.dataset.type;
    const value = isCheckBox ? e.target.checked : e.target.value;

    this.dispatchEvent(
      new CustomEvent("fieldchange", {
        detail: { field: type, value: value }
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
