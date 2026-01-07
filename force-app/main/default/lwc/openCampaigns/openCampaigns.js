import { LightningElement, track, wire } from "lwc";
import getCampaignMembers from "@salesforce/apex/openCampaigns.getCampaignMembers";

export default class OpenCampaigns extends LightningElement {
  @track sortBy = "name";
  @track sortDirection = "desc";

  @wire(getCampaignMembers)
  wiredData;

  get rows() {
    const data = this.wiredData?.data || [];

    const mappedData = data.map((r) => ({
      id: r?.Id,
      name: r?.Account?.Name,
      email: r?.Account?.Email__c,
      campaign: r?.Campaign?.Name
    }));

    return mappedData;
  }

  get columns() {
    return [
      { label: "Name", fieldName: "name", sortable: true },
      { label: "Email", fieldName: "email", sortable: true },
      { label: "Campaign", fieldName: "campaign", sortable: true }
    ];
  }

  handleSort(e) {
    this.sortBy = e.detail.fieldName;
    this.sortDirection = e.detail.sortDirection;
  }
}
