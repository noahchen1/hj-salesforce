import { LightningElement, wire, track } from "lwc";
import getOpenRepairs from "@salesforce/apex/OpenRepairsController.getOpenRepairs";

export default class OpenRepairs extends LightningElement {
  @track billingStatus = "";
  @track name = "";

  @wire(getOpenRepairs, { billingStatus: "$billingStatus", name: "$name" })
  wiredData;

  get rows() {
    const data = this.wiredData?.data || [];

    return data.map((r) => ({
      id: r.Id,
      date: r.breadwinner_ns__CreatedDate__c,
      name: r.Name,
      total: r.breadwinner_ns__Total__c,
      station: r.ncf_body_repair_station__c,
      type: r.ncf_body1__c,
      customer: r.breadwinner_ns__Entity__r.Name
    }));
  }

  get columns() {
    return [
      { label: "Document", fieldName: "name" },
      { label: "Customer", fieldName: "customer" },
      { label: "Date", fieldName: "date" },
      { label: "Repair Station", fieldName: "station" },
      { label: "Repair Type", fieldName: "type" },
      { label: "Total", fieldName: "total" }
    ];
  }

  get billingOptions() {
    return [
      { label: "All", value: "" },
      { label: "1", value: "1" },
      { label: "2", value: "2" }
    ];
  }

  get customers() {
    return [
      { label: "All", value: "" },
      { label: "Customer A", value: "Customer A" },
      { label: "Customer B", value: "Customer B" }
    ];
  }

  handleStatusChange(e) {
    this.billingStatus = e.target.value;
  }

  handleNameChange(e) {
    this.name = e.target.value;
  }
}
