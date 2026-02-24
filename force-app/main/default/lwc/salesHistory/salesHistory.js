import { LightningElement, track, wire } from "lwc";
import getSalesHistory from "@salesforce/apex/SalesHistory.getSalesHistory";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchItem from "@salesforce/apex/FilterDataController.searchItem";
import getDivisions from "@salesforce/apex/DropdownDataController.getDivisions";
import getDepartments from "@salesforce/apex/DropdownDataController.getDepartments";
import getGroupCodes from "@salesforce/apex/DropdownDataController.getGroupCodes";

export default class SalesHistory extends LightningElement {
  @track isLoading = true;
  @track customer = null;
  @track salesRep = null;
  @track item = null;
  @track pageNumber = 1;
  @track pageSize = 25;
  @track sortBy = "totalSpend";
  @track sortDirection = "desc";
  @track tableDataLoaded = false;
  @track divisionOptions = [];
  @track division = "";
  @track departmentOptions = [];
  @track department = "";
  @track groupcodeOptions = [];
  @track groupcode = "";

  tableData = [];
  wireError;

  @wire(getDivisions)
  handleDivisions(results) {
    this.processPicklistWire(results, "divisionOptions");
  }

  @wire(getDepartments)
  handleDepartments(results) {
    this.processPicklistWire(results, "departmentOptions");
  }

  @wire(getGroupCodes)
  handleGroupCodes(results) {
    this.processPicklistWire(results, "groupcodeOptions");
  }

  @wire(getSalesHistory, {
    customer: "$customer",
    salesRep: "$salesRep",
    item: "$item",
    division: "$division",
    department: "$department",
    groupcode: "$groupcode",
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
      this.wireError = error;
      this.isLoading = false;
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

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;

    const input = this.template.querySelector(
      `c-lookup-input[data-type="${type}"]`
    );

    let searchFn;

    if (type === "salesRep") {
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

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    this[name] = value;
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const selectedName = e.detail.name;

    this[type] = selectedName;
    this.pageNumber = 1;
  }

  get disableNext() {
    return !this.hasNext || this.isLoading;
  }

  get disablePrev() {
    return !this.hasPrev || this.isLoading;
  }
}
