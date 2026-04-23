import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import getSubsidiaries from "@salesforce/apex/DropdownDataController.getSubsidiaries";
import searchItem from "@salesforce/apex/FilterDataController.searchItem";
import BASE_PRICE from "@salesforce/schema/breadwinner_ns__BW_Item__c.Base_Price__c";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import saveSalesOrder from "@salesforce/apex/SoService.saveSalesOrder";
import getSubsidiaryLocations from "@salesforce/apex/DropdownDataController.getSubsidiaryLocations";
import checkOnHand from "@salesforce/apex/DataService.checkOnHand";
import LightningAlert from "lightning/alert";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class SalesOrderForm extends LightningElement {
  recordId;
  customer = "";
  date = new Date().toISOString();
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  locationOptions = [];
  subsidiary = "";
  subsidiaryOptions = [];
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

  get isLocationDisabled() {
    return !this.subsidiary;
  }

  @wire(getSubsidiaryLocations, { subsidiary: "$subsidiary" })
  handleLocations(results) {
    this.processPicklistWire(results, "locationOptions");
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

  get showTableOverlay() {
    return !(
      this.customer &&
      this.salesRep1 &&
      this.subsidiary &&
      this.location &&
      this.date
    );
  }

  async connectedCallback() {
    try {
      const [subsidiaries] = await Promise.all([getSubsidiaries()]);

      this.processPicklistWire({ data: subsidiaries }, "subsidiaryOptions");
    } catch (error) {
      console.error("Error fetching dropdown data:", error);
    }
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
      const selectedId = e.detail.id;
      const selectedNsId = e.detail.nsId;
      const index = Number(e.target.dataset.index);

      if (type === "item") {
        const itemIsAvailable = await checkOnHand({
          itemName: selectedName,
          nsLocationId: this.location,
          qtyRequested: 1
        });

        if (!itemIsAvailable) {
          await LightningAlert.open({
            label: "Warning!",
            message: "This item is not available at the selected location",
            theme: "warning"
          });
        }

        const updatedRows = [...this.rows];

        if (updatedRows[index]) {
          updatedRows[index].item = selectedNsId;
          this.rows = updatedRows;
        }

        this.selectedItemRowIndex = index;
        this.selectedItemId = selectedId;

        return;
      }

      if (type === "customer" || type === "salesRep1" || type === "salesRep2") {
        this[type] = selectedNsId;

        return;
      }

      this[type] = selectedName;
    } catch (err) {
      this.showErrors(err);
    }
  }

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    if (name === "subsidiary" && this.subsidiary !== value) {
      this.location = "";
    }

    this[name] = e.target.value;
  }

  processPicklistWire({ data, error }, target) {
    if (data) {
      this[target] = [
        { label: "Select", value: "" },
        ...data.map(({ label, value }) => ({ label, value }))
      ];
    } else if (error) {
      console.error(`Error fetching ${target}: `, error);
    }
  }

  async handleRowChange(e) {
    const index = Number(e.target.dataset.index);
    const field = e.target.dataset.field;
    const value = e.target.value;
    const updatedRows = [...this.rows];

    if (field === "quantity") {
      const itemName = updatedRows[index].item;

      const itemIsAvailable = await checkOnHand({
        itemName: itemName,
        nsLocationId: this.location,
        qtyRequested: value
      });

      if (!itemIsAvailable) {
        await LightningAlert.open({
          label: "Warning!",
          message: "This item is not available at the selected location",
          theme: "warning"
        });
      }
    }

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
    console.log(this.customer);
    console.log(this.date);
    console.log(this.salesRep1);
    console.log(this.subsidiary);
    console.log(this.location);
    console.log(JSON.stringify(this.rows));
    try {
      await saveSalesOrder({
        customer: this.customer,
        orderDate: this.date,
        salesRep1: this.salesRep1,
        salesRep2: this.salesRep2,
        subsidiary: this.subsidiary,
        location: this.location,
        lineItemsJson: JSON.stringify(this.rows)
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Response",
          message: "Order saved!",
          variant: "success"
        })
      );
    } catch (err) {
      console.error("createSo failed", err);

      LightningAlert.open({
        label: "Error!",
        message: `Order was not saved, cause: ${err?.body?.message}`,
        theme: "error"
      });
    }
  }

  handleDateChange(e) {
    this.date = e.target.value;
  }

  showErrors(err) {
    console.error(err.name);
    console.error(err.message);
    console.error(err.stack);
  }
}
