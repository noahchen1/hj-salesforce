import { LightningElement, wire, track } from "lwc";
import getOpenSpecialOrders from "@salesforce/apex/OpenSpecialOrdersController.getOpenSpecialOrders";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchVendor from "@salesforce/apex/FilterDataController.searchVendor";
import getSpecialOrderItemTypes from "@salesforce/apex/DropdownDataController.getSpecialOrderItemTypes";
import getSpecialOrderStatuses from "@salesforce/apex/DropdownDataController.getSpecialOrderStatuses";
import getLocations from "@salesforce/apex/DropdownDataController.getLocations";
import searchVendorNum from "@salesforce/apex/FilterDataController.searchVendorNum";

export default class OpenSpecialOrders extends LightningElement {
  @track salesRep = "";
  @track customer = "";
  @track vendor = "";
  @track pageNumber = 1;
  @track pageSize = 20;
  @track itemTypeOptions = [];
  @track itemType = "";
  @track statusOptions = [];
  @track status = "";
  @track locationOptions = [];
  @track location = "";
  @track vendornum = "";
  @track showActiveOrdersOnly = true;
  @track comments = "";
  @track hideRolexOrTudor = [];
  @track sortBy = "needByDate";
  @track sortDirection = "desc";

  @wire(getOpenSpecialOrders, {
    salesRep: "$salesRep",
    customer: "$customer",
    vendor: "$vendor",
    location: "$location",
    status: "$status",
    itemType: "$itemType",
    vendornum: "$vendornum",
    showActiveOrdersOnly: "$showActiveOrdersOnly",
    comments: "$comments",
    hideRolexOrTudor: "$hideRolexOrTudor",
    limitSize: "$pageSize",
    offsetSize: "$offset",
    sortBy: "$sortBy",
    sortDirection: "$sortDirection"
  })
  wiredData;

  @wire(getSpecialOrderItemTypes)
  handleItemTypes(result) {
    this.processPicklistWire(result, "itemTypeOptions");
  }

  @wire(getSpecialOrderStatuses)
  handleStatuses(result) {
    this.processPicklistWire(result, "statusOptions");
  }

  @wire(getLocations)
  handleLocations(result) {
    this.processPicklistWire(result, "locationOptions");
  }

  get hideRolexOrTudorOptions() {
    return [
      { label: "Show All", value: "Show All", selected: true },
      {
        label: "ROLEX WATCH U.S.A., INC",
        value: "ROLEX WATCH U.S.A., INC",
        selected: false
      },
      { label: "TUDOR USA", value: "TUDOR USA", selected: false }
    ];
  }

  handleComboboxChange(e) {
    const name = e.target.name;

    this[name] = e.target.value;
  }

  handleCommentsChange(e) {
    this.comments = e.target.value;
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

  handleActiveOrdersCheck(e) {
    this.showActiveOrdersOnly = e.target.checked;
  }

  get offset() {
    return (this.pageNumber - 1) * this.pageSize;
  }

  get isPrevDisabled() {
    return this.pageNumber === 1;
  }

  get isNextDisabled() {
    return this.rows.length < this.pageSize;
  }

  get rows() {
    const data = this.wiredData?.data || [];
    const mappedData = data.map((r) => {
      const so = r.breadwinner_ns__Sales_Order__r || {};
      const entity = so.breadwinner_ns__Entity__r || {};
      const soLink = `https://5405357-sb1.app.netsuite.com/app/accounting/transactions/salesord.nl?id=${so.breadwinner_ns__InternalId__c}`;
      const needByDateObj = new Date(so.ncf_body_special_order_date__c);
      const today = new Date();
      const rowStyle =
        today.getTime() >= needByDateObj.getTime()
          ? "slds-text-color_error"
          : "";

      return {
        id: so.Id,
        nsId: so.breadwinner_ns__InternalId__c,
        document: soLink,
        documentLabel: so.Name,
        customer: entity.Name || "",
        specialDate: this.formateDate(so.ncf_body_special_date__c),
        needByDate: this.formateDate(so.ncf_body_special_order_date__c),
        salesRep: so.breadwinner_ns__SalesRepName__c,
        status: so.ncf_body_special_statuses__c,
        notes: so.ncf_body_special_comments__c,
        sku: r.ncf_col_special_sku__c,
        quotedPrice: r.ncf_col_special_quoted_price__c,
        vendorItemNum: r.ncf_col_special_order_number__c,
        rowStyle
      };
    });

    return mappedData;
  }

  get columns() {
    const base = [
      { label: "Customer", fieldName: "customer", sortable: true },
      { label: "Date", fieldName: "specialDate", sortable: true },
      {
        label: "Document",
        fieldName: "document",
        type: "url",
        typeAttributes: {
          label: { fieldName: "documentLabel" },
          target: "_blank"
        },
        sortable: true
      },
      { label: "Ns Id", fieldName: "nsId", sortable: false },
      { label: "Need By Date", fieldName: "needByDate", sortable: true },
      { label: "Sales Rep", fieldName: "salesRep", sortable: true },
      { label: "Status", fieldName: "status", sortable: true },
      { label: "Notes", fieldName: "notes", sortable: false },
      { label: "HJ SKU", fieldName: "sku", sortable: false },
      { label: "Vendor Item Num", fieldName: "vendorItemNum", sortable: false },
      { label: "Quoted Price", fieldName: "quotedPrice", sortable: true }
    ];

    return base.map((col) => {
      return {
        ...col,
        cellAttributes: {
          class: { fieldName: "rowStyle" }
        }
      };
    });
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
    } else if (type === "vendor") {
      searchFn = searchVendor;
    } else if (type === "vendornum") {
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

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const selectedName = e.detail.name;
    this[type] = selectedName;
    this.pageNumber = 1;
  }

  handleHideRolexOrTudorChange(e) {
    this.hideRolexOrTudor = e.detail.value.filter((v) => v !== "Show All");
  }

  handleSort(e) {
    this.sortBy = e.detail.fieldName;
    this.sortDirection = e.detail.sortDirection;
  }

  nextPage() {
    this.pageNumber += 1;
  }

  prevPage() {
    if (this.pageNumber > 1) {
      this.pageNumber -= 1;
    }
  }

  formateDate = (date) => (date ? new Date(date).toLocaleDateString() : "");
}
