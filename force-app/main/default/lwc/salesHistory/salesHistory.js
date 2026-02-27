import { LightningElement, track, wire } from "lwc";
import getSalesHistory from "@salesforce/apex/SalesHistory.getSalesHistory";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchItem from "@salesforce/apex/FilterDataController.searchItem";
import getDivisions from "@salesforce/apex/DropdownDataController.getDivisions";
import getDepartments from "@salesforce/apex/DropdownDataController.getDepartments";
import getGroupCodes from "@salesforce/apex/DropdownDataController.getGroupCodes";
import searchVendor from "@salesforce/apex/FilterDataController.searchVendor";
import searchVendorNum from "@salesforce/apex/FilterDataController.searchVendorNum";
import getAllCampaigns from "@salesforce/apex/DropdownDataController.getAllCampaigns";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import enqueueAddAccountsToCampaign from "@salesforce/apex/SalesHistoryCampaignController.enqueueAddAccountsToCampaign";

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
  @track division = null;
  @track departmentOptions = [];
  @track department = null;
  @track groupcodeOptions = [];
  @track groupcode = null;
  @track purchaseStartDate = null;
  @track purchaseEndDate = null;
  @track vendor = null;
  @track vendorItemNum = null;
  @track birthdayStartMonth = "";
  @track birthdayStartDay = "";
  @track birthdayEndMonth = "";
  @track birthdayEndDay = "";
  @track isServiceOnly = false;
  @track isNewCustomer = false;
  @track isModalOpen = false;
  @track campaignOptions = [];
  @track selectedCampaign = null;

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

  @wire(getAllCampaigns)
  handleCampaigns(result) {
    this.processPicklistWire(result, "campaignOptions");
  }

  @wire(getSalesHistory, {
    customer: "$customer",
    salesRep: "$salesRep",
    item: "$item",
    division: "$division",
    department: "$department",
    groupcode: "$groupcode",
    purchaseStartDate: "$purchaseStartDate",
    purchaseEndDate: "$purchaseEndDate",
    birthdayStartMonth: "$birthdayStartMonth",
    birthdayStartDay: "$birthdayStartDay",
    birthdayEndMonth: "$birthdayEndMonth",
    birthdayEndDay: "$birthdayEndDay",
    vendor: "$vendor",
    vendorItemNum: "$vendorItemNum",
    isServiceOnly: "$isServiceOnly",
    isNewCustomer: "$isNewCustomer",
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

      console.error(error);
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

  get monthOptions() {
    return [
      { label: "All", value: "" },
      ...Array.from({ length: 12 }, (_, i) => {
        const mm = String(i + 1);
        return { label: mm, value: mm };
      })
    ];
  }

  get birthdayStartDayOptions() {
    return this.buildDayOptionsForMonth(this.birthdayStartMonth);
  }

  get birthdayEndDayOptions() {
    return this.buildDayOptionsForMonth(this.birthdayEndMonth);
  }

  buildDayOptionsForMonth(monthValue) {
    const maxDays = this.getMaxDaysForMonth(monthValue);

    return [
      { label: "All", value: "" },
      ...Array.from({ length: maxDays }, (_, i) => {
        const dd = String(i + 1);

        return { label: dd, value: dd };
      })
    ];
  }

  getMaxDaysForMonth(monthValue) {
    const monthNum = parseInt(monthValue, 10);

    if (!monthNum || monthNum < 1 || monthNum > 12) {
      return 31;
    }

    if (monthNum === 2) {
      return 29;
    }

    return [4, 6, 9, 11].includes(monthNum) ? 30 : 31;
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
    this.pageNumber += 1;
    this.isLoading = true;
  }

  handlePrev() {
    if (this.pageNumber > 1) {
      this.pageNumber -= 1;
      this.isLoading = true;
    }
  }

  handleSort(e) {
    this.sortBy = e.detail.fieldName;
    this.sortDirection = e.detail.sortDirection;
    this.isLoading = true;
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
    } else if (type === "vendor") {
      searchFn = searchVendor;
    } else if (type === "vendorItemNum") {
      searchFn = searchVendorNum;
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

  handleDateChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    this[name] = value;
  }

  handleInputChange(e) {
    const name = e.target.name;

    if (name === "isServiceOnly" || name === "isNewCustomer") {
      const checked = e.target.checked;

      this[name] = checked;
    } else {
      const value = e.target.value;

      this[name] = value;
    }

    if (name === "birthdayStartMonth") {
      const maxDays = this.getMaxDaysForMonth(this.birthdayStartMonth);
      const currentDay = parseInt(this.birthdayStartDay, 10);

      if (currentDay && currentDay > maxDays) {
        this.birthdayStartDay = "";
      }
    }

    if (name === "birthdayEndMonth") {
      const maxDays = this.getMaxDaysForMonth(this.birthdayEndMonth);
      const currentDay = parseInt(this.birthdayEndDay, 10);
      if (currentDay && currentDay > maxDays) {
        this.birthdayEndDay = "";
      }
    }

    if (name !== "selectedCampaign") {
      this.isLoading = true;
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const selectedName = e.detail.name;

    this[type] = selectedName;
    this.pageNumber = 1;
  }

  openCampaignModal() {
    this.isModalOpen = true;
  }

  closeCampaignModal() {
    this.isModalOpen = false;
  }

  async handleAddToCampaign() {
    console.log("clicked!");
    console.log(this.selectedCampaign);

    if (!this.selectedCampaign) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Missing Campaign",
          message: "Enter a Campaign Id First.",
          variant: "Warning"
        })
      );
    }

    try {
      const jobId = await enqueueAddAccountsToCampaign({
        campaignId: this.selectedCampaign,
        customer: this.customer,
        salesRep: this.salesRep,
        item: this.item,
        division: this.division,
        department: this.department,
        groupcode: this.groupcode,
        purchaseStartDate: this.purchaseStartDate,
        purchaseEndDate: this.purchaseEndDate,
        birthdayStartMonth: this.birthdayStartMonth,
        birthdayStartDay: this.birthdayStartDay,
        birthdayEndMonth: this.birthdayEndMonth,
        birthdayEndDay: this.birthdayEndDay,
        vendor: this.vendor,
        vendorItemNum: this.vendorItemNum,
        isServiceOnly: this.isServiceOnly,
        isNewCustomer: this.isNewCustomer,
        sortBy: this.sortBy,
        sortDirection: this.sortDirection
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Batch Started",
          message: `Accounts are being added. Job Id: ${jobId}`,
          variant: "success"
        })
      );
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: e?.body?.message || "Failed to start add-to-campaign job.",
          variant: "error"
        })
      );
    } finally {
      this.isModalOpen = false;
    }
  }

  get isPrevDisabled() {
    return this.pageNumber === 1;
  }

  get isNextDisabled() {
    return this.rows.length < this.pageSize;
  }
}
