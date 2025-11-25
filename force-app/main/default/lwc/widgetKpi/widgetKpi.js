import { LightningElement, wire, track } from "lwc";
import { subscribe, MessageContext } from "lightning/messageService";
import GLOBAL_FILTER from "@salesforce/messageChannel/GlobalFilterChannel__c";
import getFilteredCount from "@salesforce/apex/DashboardDataController.getFilteredCount";

export default class WidgetKpi extends LightningElement {
  @track count;
  filters = {};

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    this.subscribeToFilters();
    this.loadData();
  }

  subscribeToFilters() {
    subscribe(this.messageContext, GLOBAL_FILTER, (msg) => {
      this.filters = msg;
      this.loadData();
    });
  }

  loadData() {
    getFilteredCount({ filters: this.filters })
      .then((result) => {
        this.count = result;
      })
      .catch((error) => {
        console.error(error);
      });
  }
}
