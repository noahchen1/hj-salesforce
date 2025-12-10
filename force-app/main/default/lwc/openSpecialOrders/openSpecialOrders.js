import { LightningElement, wire, track } from "lwc";
import getOpenSpecialOrders from "@salesforce/apex/OpenSpecialOrdersController.getOpenSpecialOrders";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchVendor from "@salesforce/apex/FilterDataController.searchVendor";
import searchLocation from "@salesforce/apex/FilterDataController.searchLocation";

export default class OpenSpecialOrders extends LightningElement {
  @track salesRep = "";
  @track customer = "";
  @track vendor = "";
  @track location = "";
  @track pageNumber = 1;
  @track pageSize = 20;

  @wire(getOpenSpecialOrders, {
    salesRep: "$salesRep",
    customer: "$customer",
    vendor: "$vendor",
    location: "$location",
    limitSize: "$pageSize",
    offsetSize: "$offset"
  })
  wiredData;

  get offset() {
    return (this.pageNumber - 1) * this.pageSize;
  }

  get rows() {
    const data = this.wiredData?.data || [];

    return data.map((r) => {
      const so = r.breadwinner_ns__Sales_Order__r || {};
      const entity = so.breadwinner_ns__Entity__r || {};

      return {
        id: so.Id,
        document: so.Name,
        customer: entity.Name || "",
        specialDate: this.formateDate(so.ncf_body_special_date__c),
        needByDate: this.formateDate(so.ncf_body_special_order_date__c),
        salesRep: so.breadwinner_ns__SalesRepName__c,
        status: so.ncf_body_special_statuses__c,
        notes: so.ncf_body_special_comments__c,
        sku: r.ncf_col_special_sku__c,
        quotedPrice: r.ncf_col_special_quoted_price__c,
        vendorItemNum: r.ncf_col_special_order_number__c
      };
    });
  }

  get columns() {
    return [
      { label: "Customer", fieldName: "customer" },
      { label: "Date", fieldName: "specialDate" },
      { label: "Document", fieldName: "document" },
      { label: "Need By Date", fieldName: "needByDate" },
      { label: "Sales Rep", fieldName: "salesRep" },
      { label: "Status", fieldName: "status" },
      { label: "Notes", fieldName: "notes" },
      { label: "HJ SKU", fieldName: "sku" },
      { label: "Vendor Item Num", fieldName: "vendorItemNum" },
      { label: "Quoted Price", fieldName: "quotedPrice" }
    ];
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
    } else if (type === "location") {
      searchFn = searchLocation;
    }

    if (searchKey.length > 1 && searchFn) {
      try {
        const results = await searchFn({ input: searchKey });
        input.setResults(results);
      } catch (error) {
        console.error(error);
        input.setResults([]);
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

  formateDate = (date) => (date ? new Date(date).toLocaleDateString() : "");
}
