import { LightningElement, track, wire } from "lwc";
import getSalesHistory from "@salesforce/apex/SalesHistory.getSalesHistory";
import LightningAlert from "lightning/alert";

export default class SalesHistory extends LightningElement {
  constructor() {
    super();
    this.nextCursor = null;
    this.prevCursor = null;
    this.hasNext = false;
    this.hasPrev = false;
  }

  @track isLoading = false;
  @track sortBy = "trandate";
  @track sortDirection = "desc";
  @track rows = [];
  @track customer = null;
  @track pageSize = 25;
  @track direction = "NEXT";
  @track cursorJson = null;

  @wire(getSalesHistory, {
    customer: null,
    pageSize: "$pageSize",
    direction: "$direction",
    cursorJson: "$cursorJson",
    sortBy: "$sortBy",
    sortDirection: "$sortDirection"
  })
  wiredData({ data, error }) {
    if (error) {
      LightningAlert.open({
        message:
          "There's a problem when loading the page, please contact administrators!",
        theme: "error",
        label: "Error!"
      });

      console.error(data.error);

      return;
    }

    if (data) {
      this.rows = data.rows || [];
      this.nextCursor = data.nextCursor;
      this.prevCursor = data.prevCursor;
      this.hasNext = !!data.hasNext;
      this.hasPrev = !!data.hasPrev;
    }
  }

  get columns() {
    return [
      { label: "Id", fieldName: "id" },
      { label: "Item", fieldName: "item" },
      { label: "Quantity", fieldName: "quantity", type: "number" },
      {
        label: "Amount",
        fieldName: "amount",
        type: "currency",
        sortable: true
      },
      { label: "Vendor", fieldName: "preferredVendor" },
      { label: "Location", fieldName: "location" },
      { label: "Department", fieldName: "department" },
      { label: "Division", fieldName: "division" },
      {
        label: "Date",
        fieldName: "trandate",
        type: "date-local",
        sortable: true
      }
    ];
  }

  handleNext() {
    if (!this.hasNext) return;

    this.direction = "NEXT";
    this.cursorJson = this.nextCursor ? JSON.stringify(this.nextCursor) : null;
  }

  handlePrev() {
    if (!this.hasPrev) return;

    this.direction = "PREV";
    this.cursorJson = this.prevCursor ? JSON.stringify(this.prevCursor) : null;
  }

  handleSort(e) {
    this.direction = "NEXT";
    this.cursorJson = null;
    this.sortBy = e.detail.fieldName;
    this.sortDirection = e.detail.sortDirection;
  }

  get disableNext() {
    return !this.hasNext || this.isLoading;
  }

  get disablePrev() {
    return !this.hasPrev || this.isLoading;
  }
}
