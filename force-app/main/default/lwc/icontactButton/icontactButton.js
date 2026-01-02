import { LightningElement, api } from "lwc";
import runIcontactAction from "@salesforce/apex/CampaignController.runIcontactAction";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CampaignAction extends LightningElement {
  @api recordId;

  handleClick() {
    runIcontactAction({ campaignId: this.recordId })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Action completed successfully",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }
}
