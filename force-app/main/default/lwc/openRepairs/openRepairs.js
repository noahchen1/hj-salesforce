import { LightningElement, wire, track } from "lwc";
import getOpenRepairs from "@salesforce/apex/OpenRepairsController.getOpenRepairs";
import getAccountNames from "@salesforce/apex/OpenRepairsController.getAccountNames";
import getStations from "@salesforce/apex/OpenRepairsController.getStations";

export default class OpenRepairs extends LightningElement {
  @track name = "";
  @track pageSize = 20;
  @track pageNumber = 1;
  @track accountOptions = [];
  @track stationOptions = [];
  @track station = "";
  @track isAccountsLoading = true;

  @wire(getOpenRepairs, {
    name: "$name",
    station: "$station",
    limitSize: "$pageSize",
    offsetSize: "$offset"
  })
  wiredData;

  get offset() {
    return (this.pageNumber - 1) * this.pageSize;
  }

  get isPrevDisabled() {
    return this.pageNumber === 1;
  }

  get rows() {
    const data = this.wiredData?.data || [];

    return data.map((r) => ({
      id: r.Id,
      date: this.formateDate(r.breadwinner_ns__CreatedDate__c),
      name: r.Name,
      total: r.breadwinner_ns__Total__c,
      station: r.ncf_body_repair_station__c,
      type: r.ncf_body1__c,
      daysOpen: r.Days_Open__c,
      customer: r?.breadwinner_ns__Entity__r?.Name || ""
    }));
  }

  get columns() {
    return [
      { label: "Date", fieldName: "date" },
      { label: "Document", fieldName: "name" },
      { label: "Customer", fieldName: "customer" },
      { label: "Total", fieldName: "total" },
      { label: "Repair Station", fieldName: "station" },
      { label: "Repair Type", fieldName: "type" },
      { label: "Days Open", fieldName: "daysOpen" }
    ];
  }

  @wire(getAccountNames)
  wiredAccounts({ data, error }) {
    if (error) {
      console.error("getAccountNames error:", error);
      this.isAccountsLoading = false;
    }
    if (data) {
      this.accountOptions = [{ label: "All", value: "" }].concat(
        data.map((name) => ({ label: name, value: name }))
      );
      this.isAccountsLoading = false;
    }
  }

  @wire(getStations)
  wiredStations({ data, error }) {
    if (error) {
      console.error("getStations error: ", error);
    }

    if (data) {
      this.stationOptions = [{ label: "All", value: "" }].concat(
        data.map((name) => ({ label: name, value: name }))
      );
    }
  }

  handleStatusChange(e) {
    this.billingStatus = e.target.value;
    this.pageNumber = 1;
  }

  handleNameChange(e) {
    this.name = e.target.value;
    this.pageNumber = 1;
  }

  handleStationChange(e) {
    this.station = e.target.value;
    this.pageNumber = 1;
  }

  formateDate = (date) => (date ? new Date(date).toLocaleDateString() : "");

  nextPage() {
    this.pageNumber += 1;
  }

  prevPage() {
    if (this.pageNumber > 1) {
      this.pageNumber -= 1;
    }
  }
}

//date
//document
//name
//amount
//repiar station
//repair description
//promise date
