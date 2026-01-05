import { LightningElement, api } from "lwc";
import uploadCampaignMembers from "@salesforce/apex/CampaignController.uploadCampaignMembers";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CampaignAction extends LightningElement {
  @api recordId;

  async handleClick() {
    const confirmed = window.confirm(
      "This action will upload contacts to Icontact, are you sure?"
    );

    if (!confirmed) return;

    try {
      await uploadCampaignMembers({ campaignId: this.recordId });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Action completed successfully",
          variant: "success"
        })
      );
    } catch (error) {
      const message =
        (error && (error.body?.message || error.message)) || "Unknown error";

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message,
          variant: "error"
        })
      );
    }
  }
}
