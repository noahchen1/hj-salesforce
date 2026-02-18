import { LightningElement, track, wire } from "lwc";
import getCampaignMembers from "@salesforce/apex/openCampaigns.getCampaignMembers";
import sendCampaignMemberEmails from "@salesforce/apex/openCampaigns.sendCampaignMemberEmails";
import getCampaigns from "@salesforce/apex/DropdownDataController.getCampaigns";
import getCustomEmailTemplates from "@salesforce/apex/DropdownDataController.getCustomEmailTemplates";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import CUSTOM_TEMPLATE_SUBJECT from "@salesforce/schema/Custom_Email_Template__c.Subject__c";
import CUSTOM_TEMPLATE_CONTENT from "@salesforce/schema/Custom_Email_Template__c.Template_Content__c";

export default class OpenCampaigns extends LightningElement {
  @track sortBy = "name";
  @track sortDirection = "desc";
  @track isModalOpen = false;
  @track emailSubject = "";
  @track emailBody = "";
  @track campaign = "";
  @track pageNumber = 1;
  @track pageSize = 20;
  @track campaignOptions = [];
  @track selectedTemplate = "";
  @track templateOptions = [];

  @wire(getCampaigns)
  handleCampaigns(result) {
    this.processPicklistWire(result, "campaignOptions");
  }

  @wire(getCustomEmailTemplates, { type: "Campaign" })
  handleTemplates(result) {
    this.processPicklistWire(result, "templateOptions");
  }

  @wire(getCampaignMembers, { campaignId: "$campaign" })
  wiredData;

  @wire(getRecord, {
    recordId: "$selectedTemplate",
    fields: [CUSTOM_TEMPLATE_SUBJECT, CUSTOM_TEMPLATE_CONTENT]
  })
  wiredTemplateData({ error, data }) {
    if (data) {
      this.emailSubject = getFieldValue(data, CUSTOM_TEMPLATE_SUBJECT) || "";
      this.emailBody = getFieldValue(data, CUSTOM_TEMPLATE_CONTENT) || "";
    } else {
      this.emailSubject = "";
      this.emailBody = "";

      console.error("Error in getting template data: " + error);
    }

    console.log(this.emailBody);
  }

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

  processPicklistWire({ data, error }, target) {
    if (data) {
      if (target === "templateOptions") {
        this[target] = data.map(({ label, value }) => ({ label, value }));
        this.selectedTemplate = data[0].value;
      } else {
        this[target] = [
          { label: "All", value: "" },
          ...data.map(({ label, value }) => ({ label, value }))
        ];
      }
    } else if (error) {
      console.error(`Error fetching ${target}: `, error);
    }
  }

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    this[name] = value;
  }

  async handleTemplateSave() {
    if (!this.selectedTemplate) return;

    const fields = {};
    fields.Id = this.selectedTemplate;
    fields[CUSTOM_TEMPLATE_CONTENT.fieldApiName] = this.emailBody;

    try {
      await updateRecord({ fields });
    } catch (err) {
      console.error("Failed to update template content:", err);
    }
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
