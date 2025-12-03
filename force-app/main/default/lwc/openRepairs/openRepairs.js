import { LightningElement, wire, track } from "lwc";
import getOpenRepairs from "@salesforce/apex/OpenRepairsController.getOpenRepairs";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchRepairStations from "@salesforce/apex/FilterDataController.searchRepairStation";
import { getSortFunction } from "c/tableSortHelper";

export default class OpenRepairs extends LightningElement {
  @track name = "";
  @track pageSize = 20;
  @track pageNumber = 1;
  @track station = "";
  @track isAccountsLoading = false;
  @track sortBy = "date";
  @track sortDirection = "asc";

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

  get isNextDisabled() {
    return this.rows.length < this.pageSize;
  }

  get rows() {
    const data = this.wiredData?.data || [];

    const mappedData = data.map((r) => ({
      id: r.Id,
      date: this.formateDate(r.breadwinner_ns__CreatedDate__c),
      name: r.Name,
      total: r.breadwinner_ns__Total__c,
      station: r.ncf_body_repair_station__c,
      type: r.ncf_body1__c,
      daysOpen: r.Days_Open__c,
      customer: r?.breadwinner_ns__Entity__r?.Name || ""
    }));

    return mappedData.sort(getSortFunction(this.sortBy, this.sortDirection));
  }

  get columns() {
    return [
      { label: "Date", fieldName: "date", sortable: true },
      { label: "Document", fieldName: "name", sortable: true },
      { label: "Customer", fieldName: "customer", sortable: true },
      { label: "Total", fieldName: "total", sortable: true },
      { label: "Repair Station", fieldName: "station", sortable: true },
      { label: "Repair Type", fieldName: "type", sortable: true },
      { label: "Days Open", fieldName: "daysOpen", sortable: true }
    ];
  }

  handleCustomerSelect(e) {
    const selectedName = e.detail.name;

    this.name = selectedName;
    this.pageNumber = 1;
  }

  handleStationSelect(e) {
    const selectedStation = e.detail.name;

    this.station = selectedStation;
    this.pageNumber = 1;
  }

  handleSort(e) {
    console.log(e.detail);
    this.sortBy = e.detail.fieldName;
    this.sortDirection = e.detail.sortDirection;
  }

  async handleCustomerSearch(e) {
    const name = e.detail.searchKey;
    const input = this.template.querySelector(
      'c-lookup-input[data-id="customerLookup"]'
    );

    if (name.length > 1) {
      try {
        const results = await searchCustomer({ input: name });

        input.setResults(results);
      } catch (error) {
        console.error(error);
        input.setResults([]);
      }
    } else {
      input.setResults([]);
      this.name = "";
    }
  }

  async handleStationSearch(e) {
    const station = e.detail.searchKey;
    const input = this.template.querySelector(
      'c-lookup-input[data-id="stationLookup"]'
    );

    if (station.length > 1) {
      try {
        const results = await searchRepairStations({ input: station });

        input.setResults(results);
      } catch (error) {
        console.log(error);

        input.setResults([]);
      }
    } else {
      input.setResults([]);
      this.station = "";
    }
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
