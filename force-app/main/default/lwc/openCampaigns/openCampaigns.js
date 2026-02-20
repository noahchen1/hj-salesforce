import { LightningElement, track, wire } from "lwc";
import getCampaignMembers from "@salesforce/apex/openCampaigns.getCampaignMembers";
import getCampaigns from "@salesforce/apex/DropdownDataController.getCampaigns";
import sendCampaignMemberEmails from "@salesforce/apex/openCampaigns.sendCampaignMemberEmails";
import getTemplateHtml from "@salesforce/apex/openCampaigns.getTemplateHtml";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

export default class OpenCampaigns extends LightningElement {
  @track sortBy = "name";
  @track sortDirection = "desc";
  @track campaign = "";
  @track pageNumber = 1;
  @track pageSize = 20;
  @track campaignOptions = [];
  @track isLoading = true;
  @track campaignOptionsLoaded = false;
  @track campaignMembersLoaded = false;

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

    this.campaignMembersLoaded = true;
    this.checkLoadingState();

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

  checkLoadingState() {
    if (this.campaignOptionsLoaded && this.campaignMembersLoaded) {
      this.isLoading = false;
    }
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

      this.campaignOptionsLoaded = true;
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

  handlePreview() {
    const emailEditor = this.template.querySelector("c-custom-email-editor");

    emailEditor.setGetTemplateHTML(getTemplateHtml);
  }

  async handleEmailSend(e) {
    const { recipientIds, subject, body } = e.detail;

    if (!Array.isArray(recipientIds) || recipientIds.length === 0) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Email failed",
          message: "No recipients selected.",
          variant: "error"
        })
      );
      return;
    }

    try {
      const result = await sendCampaignMemberEmails({
        memberIds: recipientIds,
        subject,
        body
      });

      this.showEmailResults(result);

      return refreshApex(this.wiredData);
    } catch (err) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Email failed",
          message: err?.body?.message || err?.message || "Unknown error",
          variant: "error"
        })
      );
    }
  }

  showEmailResults(resultsRaw) {
    let results = resultsRaw;

    if (typeof resultsRaw === "string") {
      try {
        results = JSON.parse(resultsRaw);
      } catch {
        results = null;
      }
    }

    if (!Array.isArray(results) || results.length === 0) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Email failed",
          message: "No results returned. Please contact your administrator.",
          variant: "error"
        })
      );

      return;
    }

    const sent = [];
    const failed = [];
    const allErrors = [];

    for (const row of results) {
      const recipient = row?.recipient || "(unknown recipient)";
      const success = !!row?.success;

      if (success) {
        sent.push(recipient);
      } else {
        failed.push(recipient);

        const errs = Array.isArray(row?.errors) ? row.errors : [];

        for (const msg of errs) if (msg) allErrors.push(msg);
      }
    }

    const uniqueErrors = [...new Set(allErrors)];
    const total = results.length;
    const sentCount = sent.length;
    const failedCount = failed.length;

    let variant = "success";
    let title = "Email Results";
    if (failedCount === total) {
      variant = "error";
      title = "Email failed";
    } else if (failedCount > 0) {
      variant = "warning";
      title = "Email partially sent";
    }

    const parts = [
      `Total: ${total}`,
      `Sent: ${sentCount}`,
      `Failed: ${failedCount}`
    ];

    if (sentCount) parts.push(`Sent to: ${sent.join(", ")}`);
    if (failedCount) parts.push(`Failed: ${failed.join(", ")}`);
    if (uniqueErrors.length) parts.push(`Errors: ${uniqueErrors.join(", ")}`);

    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message: parts.join(" | "),
        variant
      })
    );
  }
}
