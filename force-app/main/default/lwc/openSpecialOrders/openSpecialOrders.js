import { LightningElement, wire, track } from "lwc";
import getOpenSpecialOrders from "@salesforce/apex/openSpecialOrdersController.getOpenSpecialOrders";

export default class OpenSpecialOrders extends LightningElement {
  @track date = `${new Date().getFullYear()}-01-01`;

  @wire(getOpenSpecialOrders, { dateFilter: "$date" })
  wiredData;

  get rows() {
    const data = this.wiredData?.data || [];

    return data.map((r) => ({
      id: r.Id,
      date: this.formateDate(r.breadwinner_ns__CreatedDate__c),
      customer: r?.breadwinner_ns__Entity__r?.Name || "",
      specialDate: this.formateDate(r.ncf_body_special_date__c),
      salesRep: r.breadwinner_ns__SalesRepName__c,
      status: r.ncf_body_special_statuses__c,
      notes: r.ncf_body_special_comments__c,
      document: r.Name
    }));
  }

  get columns() {
    return [
      { label: "Customer", fieldName: "customer" },
      { label: "Date", fieldName: "date" },
      { label: "Document", fieldName: "document" },
      { label: "Need By Date", fieldName: "specialDate" },
      { label: "Sales Rep", fieldName: "salesRep" },
      { label: "status", fieldName: "status" },
      { label: "notes", fieldName: "notes" }
    ];
  }

  formateDate = (date) => (date ? new Date(date).toLocaleDateString() : "");

  handleDateChange(e) {
    this.date = e.target.value;
  }
}
