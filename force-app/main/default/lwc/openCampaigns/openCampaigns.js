import { LightningElement, track, wire } from "lwc";
import getCampaignMembers from "@salesforce/apex/openCampaigns.getCampaignMembers";
import sendCampaignMemberEmails from "@salesforce/apex/openCampaigns.sendCampaignMemberEmails";

export default class OpenCampaigns extends LightningElement {
  @track sortBy = "name";
  @track sortDirection = "desc";
  @track isModalOpen = false;
  @track emailSubject = "Campaign follow up";
  @track emailBody = "Hello world!";

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

  handleSubjectChange(e) {
    this.emailSubject = e.target.value;
  }

  handleBodyChange(e) {
    this.emailBody = e.target.value;
  }

  async openTemplateModal() {
    this.isModalOpen = true;
  }

  closeTemplateModal() {
    this.isModalOpen = false;
  }

  async handleEmailSend() {
    const ids = (this.wiredData?.data || []).map((r) => r.Id).filter(Boolean);

    if (!ids.length) {
      this.closeTemplateModal();

      return;
    }

    try {
      await sendCampaignMemberEmails({
        memberIds: ids,
        subject: this.emailSubject,
        body: this.emailBody
      });

      this.closeTemplateModal();
    } catch (error) {
      console.error(error);

      this.closeTemplateModal();
    }
  }
}
