import { LightningElement, track, wire } from "lwc";
import getSalesHistory from "@salesforce/apex/SalesHistory.getSalesHistory";

export default class SalesHistory extends LightningElement {
  @track isLoading = true;
  @track customer = null;
  @track pageNumber = 1;
  @track pageSize = 25;
  @track sortBy = "totalSpend";
  @track sortDirection = "desc";
  @track tableDataLoaded = false;

  tableData = [];
  wireError;

  @wire(getSalesHistory, {
    customer: null,
    pageSize: "$pageSize",
    offsetSize: "$offset",
    sortBy: "$sortBy",
    sortDirection: "$sortDirection"
  })
  wiredSalesHistory({ data, error }) {
    if (data) {
      this.tableData = data;
      this.wireError = undefined;
      this.isLoading = false;
    } else if (error) {
      this.tableData = [];
      this.isLoading = false;
      this.wireError = error;
    }
  }

  get offset() {
    return (this.pageNumber - 1) * this.pageSize;
  }

  get rows() {
    const data = this.tableData || [];

    const mappedData = data.map((r) => {
      return {
        customer: r.customer,
        firstName: r.first_name,
        lastName: r.last_name,
        email: r.email,
        phone: r.phone,
        mobile: r.mobile,
        street: r.street,
        city: r.city,
        state: r.state,
        zip: r.zip,
        country: r.country,
        subsidiary: r.subsidiary,
        salesRep: r.sales_rep,
        birthday: r.birthday,
        anniversary: r.anniversary,
        ranking: r.ranking,
        isNewCustomer: r.is_new_customer,
        accountSource: r.account_source,
        lifetimeSpend: r.lifetime_spend,
        totalSpend: r.total_spend
      };
    });

    return mappedData;
  }

  get columns() {
    return [
      { label: "Customer", fieldName: "customer" },
      { label: "First Name", fieldName: "firstName" },
      { label: "Last Name", fieldName: "lastName" },
      { label: "Email", fieldName: "email" },
      { label: "Phone", fieldName: "phone" },
      { label: "Mobile", fieldName: "mobile" },
      { label: "Street", fieldName: "street" },
      { label: "Zip", fieldName: "zip" },
      { label: "Country", fieldName: "country" },
      { label: "Subsidiary", fieldName: "subsidiary" },
      { label: "Sales Rep", fieldName: "salesRep" },
      {
        label: "Birthday",
        fieldName: "birthday",
        type: "date-local",
        sortable: true
      },
      {
        label: "Anniversary",
        fieldName: "anniversary",
        type: "date-local"
      },
      { label: "Ranking", fieldName: "ranking" },
      { label: "New Customer", fieldName: "isNewCustomer" },
      { label: "Lead Source", fieldName: "accountSource" },
      { label: "Lifetime Spend", fieldName: "lifetimeSpend" },
      { label: "Total Spend", fieldName: "totalSpend", sortable: true }
    ];
  }

  checkLoadingState() {
    if (this.tableDataLoaded) {
      this.isLoading = false;
    }
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
