import { api, LightningElement, track, wire } from "lwc";
import getCustomEmailTemplates from "@salesforce/apex/DropdownDataController.getCustomEmailTemplates";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import CUSTOM_TEMPLATE_SUBJECT from "@salesforce/schema/Custom_Email_Template__c.Subject__c";
import CUSTOM_TEMPLATE_CONTENT from "@salesforce/schema/Custom_Email_Template__c.Template_Content__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CustomEmailEditor extends LightningElement {
  @track selectedTemplate = "";
  @track templateOptions = [];
  @track templateType = "";
  @track subject = "";
  @track body = "";
  @track preview = "";
  @track isModalOpen = false;
  @track isPreviewOpen = false;
  @track isLoading = true;
  @track isPreviewLoading = false;
  @track templateOptionsLoaded = false;
  @track templateDataLoaded = false;
  @track recipientIds = [];
  @track getTemplateHtml = "";

  @api
  setTemplateType(templateType) {
    this.templateType = templateType;
    console.log(this.templateType);
  }

  @api
  setTemplateHtml(templateHtml) {
    this.templateHtml = templateHtml;
  }

  @api
  setGetTemplateHTML(getTemplateHtml) {
    this.getTemplateHtml = getTemplateHtml;
  }

  @api
  openModal() {
    this.isModalOpen = true;
  }

  @api
  setRecipients(recipientIds) {
    this.recipientIds = recipientIds;
  }

  closeModal() {
    this.selectedTemplate = "";
    this.templateOptions = [];
    this.templateType = "";
    this.subject = "";
    this.body = "";
    this.preview = "";
    this.isModalOpen = false;
    this.isPreviewOpen = false;
    this.isLoading = true;
    this.isPreviewLoading = false;
    this.templateOptionsLoaded = false;
    this.templateDataLoaded = false;
    this.recipientIds = [];
    this.getTemplateHtml = "";
  }

  async openPreview() {
    this.isPreviewLoading = true;
    this.isPreviewOpen = true;

    this.dispatchEvent(new CustomEvent("preview"));

    this.preview = await this.getTemplateHtml({
      subject: this.subject,
      body: this.body
    });

    this.isPreviewLoading = false;
  }

  closePreview() {
    this.isPreviewOpen = false;
    this.isPreviewLoading = false;
    this.preview = "";
  }

  @wire(getCustomEmailTemplates, { type: "$templateType" })
  handleTemplates(result) {
    this.processPicklistWire(result, "templateOptions");
  }

  @wire(getRecord, {
    recordId: "$selectedTemplate",
    fields: [CUSTOM_TEMPLATE_SUBJECT, CUSTOM_TEMPLATE_CONTENT]
  })
  wiredTemplateData({ error, data }) {
    if (data) {
      this.subject = getFieldValue(data, CUSTOM_TEMPLATE_SUBJECT) || "";
      this.body = getFieldValue(data, CUSTOM_TEMPLATE_CONTENT) || "";

      this.templateDataLoaded = true;
      this.checkLoadingState();
    } else {
      this.subject = "";
      this.body = "";

      if (this.isModalOpen && error) {
        console.error("Error in getting template data: " + error);
      }
    }
  }

  checkLoadingState() {
    if (this.templateOptionsLoaded && this.templateDataLoaded) {
      this.isLoading = false;
    }
  }

  handleSubjectChange(e) {
    this.subject = e.target.value;
  }

  handleBodyChange(e) {
    this.body = e.target.value;
  }

  processPicklistWire({ data, error }, target) {
    if (data && data.length !== 0) {
      this[target] = data.map(({ label, value }) => ({ label, value }));
      this.selectedTemplate = data[0].value;

      this.templateOptionsLoaded = true;
      this.checkLoadingState();
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
    fields[CUSTOM_TEMPLATE_CONTENT.fieldApiName] = this.body;

    try {
      await updateRecord({ fields });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Saved",
          message: "Template content saved.",
          variant: "success"
        })
      );
    } catch (err) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Template Save failed",
          message: err?.body?.message || err?.message || "Unknown error",
          variant: "error"
        })
      );
    }
  }

  async handleEmailSend() {
    if (!this.recipientIds.length) {
      this.closeModal();

      return;
    }

    this.dispatchEvent(
      new CustomEvent("sendemail", {
        detail: {
          recipientIds: this.recipientIds,
          subject: this.subject,
          body: this.body
        }
      })
    );

    this.closeModal();
  }
}
