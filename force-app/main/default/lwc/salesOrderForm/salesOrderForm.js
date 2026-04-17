import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import getLocations from "@salesforce/apex/DropdownDataController.getLocations";
import searchItem from "@salesforce/apex/FilterDataController.searchItem";
import BASE_PRICE from "@salesforce/schema/breadwinner_ns__BW_Item__c.Base_Price__c";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import createSo from "@salesforce/apex/SoService.createSo";

export default class SalesOrderForm extends LightningElement {
  recordId;
  customer = "";
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  locationOptions = [];
  rows = [
    {
      id: 1,
      item: "",
      quantity: "",
      rate: "",
      amount: "",
      showAction: true,
      disableRemove: true
    }
  ];
  statusOptions = [
    { label: "Pending", value: "Pending" },
    { label: "Approved", value: "Approved" },
    { label: "Backordered", value: "Backordered" }
  ];
  nextRowId = 2;
  selectedItemId;
  selectedItemRowIndex = null;

  @wire(CurrentPageReference)
  getStateParameters(pageRef) {
    if (pageRef) {
      this.recordId = pageRef.state?.c__recordId;
    }
  }

  @wire(getRecord, {
    recordId: "$selectedItemId",
    fields: [BASE_PRICE]
  })
  wiredItemRecord({ data, error }) {
    if (data && this.selectedItemRowIndex !== null) {
      const basePrice = getFieldValue(data, BASE_PRICE);
      const updatedRows = [...this.rows];

      if (updatedRows[this.selectedItemRowIndex]) {
        updatedRows[this.selectedItemRowIndex].quantity = 1;
        updatedRows[this.selectedItemRowIndex].rate = basePrice ?? "";
        updatedRows[this.selectedItemRowIndex].amount = basePrice ?? "";
        this.rows = updatedRows;
      }
    } else if (error) {
      console.error("Error fetching item base price", error);
    }
  }

  @wire(getLocations)
  handleLocations(results) {
    this.processPicklistWire(results, "locationOptions");
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;

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

  async handleLookupSelect(e) {
    try {
      const type = e.target.dataset.type;
      const selectedName = e.detail.name;

      if (type === "item") {
        const itemId = e.detail.id;
        const index = Number(e.target.dataset.index);
        const updatedRows = [...this.rows];

        if (updatedRows[index]) {
          updatedRows[index].item = selectedName;
          this.rows = updatedRows;
        }

        this.selectedItemRowIndex = index;
        this.selectedItemId = itemId;

        return;
      }

      this[type] = selectedName;
    } catch (error) {
      console.error(`Error occured when setting item for line item ${index}`);
      console.error(error);
    }
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

  handleRowChange(e) {
    const index = Number(e.target.dataset.index);
    const field = e.target.dataset.field;
    const value = e.target.value;
    const updatedRows = [...this.rows];

    updatedRows[index][field] = value;
    this.rows = updatedRows;
  }

  // renderedCallback() {
  //   console.log("component rerendered");
  // }

  addRow(e) {
    const index = Number(e.target.dataset.index);

    try {
      const newRow = {
        id: this.nextRowId++,
        item: "",
        quantity: "",
        rate: "",
        amount: "",
        showAction: false,
        disableRemove: false
      };

      const updatedRows = [...this.rows];
      updatedRows.splice(index + 1, 0, newRow);

      this.rows = updatedRows;
    } catch (error) {
      console.error(
        `Error occured when changing values for line item ${index}`
      );
      console.error(error);
    }
  }

  removeRow(e) {
    const index = Number(e.target.dataset.index);

    const updatedRows = [...this.rows];
    updatedRows.splice(index, 1);

    this.rows = updatedRows;
  }

  handleFocus(e) {
    const index = Number(e.target.dataset.index);
    const updatedRows = [...this.rows];

    updatedRows.forEach((row, idx) => {
      if (idx === index) {
        row.showAction = true;
      } else {
        row.showAction = false;
      }
    });

    this.rows = updatedRows;
  }

  async saveOrder() {
    console.log("save btn clicked!");

    try {
      await createSo();
      console.log("createSo completed");
    } catch (error) {
      console.error("createSo failed", error);
    }
  }
}
