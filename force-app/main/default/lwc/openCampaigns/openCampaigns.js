import { LightningElement, track, wire } from "lwc";
import getCampaignMembers from "@salesforce/apex/openCampaigns.getCampaignMembers";
import getCampaigns from "@salesforce/apex/DropdownDataController.getCampaigns";

export default class OpenCampaigns extends LightningElement {
  @track sortBy = "name";
  @track sortDirection = "desc";
  @track campaign = "";
  @track pageNumber = 1;
  @track pageSize = 20;
  @track campaignOptions = [];

  @wire(getCampaigns)
  handleCampaigns(result) {
    this.processPicklistWire(result, "campaignOptions");
  }

  @wire(getCampaignMembers, { campaignId: "$campaign" })
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

  async openTemplateModal() {
    const recipientIds = (this.wiredData?.data || [])
      .map((r) => r.Id)
      .filter(Boolean);
    const emailEditor = this.template.querySelector("c-custom-email-editor");

    emailEditor.setTemplateType("Campaign");
    emailEditor.setRecipients(recipientIds);
    emailEditor.openModal();
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

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    this[name] = value;
  }
}
