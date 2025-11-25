import { LightningElement, track, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";
import GLOBAL_FILTER from "@salesforce/messageChannel/GlobalFilterChannel__c";

export default class GlobalFilterBar extends LightningElement {
  @track startDate;
  @track endDate;
  @track status;

  get statusOptions() {
    return [
      { label: "All", value: "" },
      { label: "Negotiation/Review ", value: "Negotiation/Review" },
      { label: "Perception Analysis", value: "Perception Analysis" },
      { label: "Closed Won", value: "Closed Won" },
      { label: "Prospecting ", value: "Prospecting" }
    ];
  }

  @wire(MessageContext)
  messageContext;

  handleStartChange(e) {
    this.startDate = e.target.value;
  }

  handleEndChange(e) {
    this.endDate = e.target.value;
  }

  handleStatusChange(e) {
    this.status = e.detail.value;
  }

  applyFilters() {
    publish(this.messageContext, GLOBAL_FILTER, {
      startDate: this.startDate,
      endDate: this.endDate,
      status: this.status
    });
  }
}
