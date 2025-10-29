import { LightningElement, wire, track } from "lwc";
import getOpps from "@salesforce/apex/ReportExampleController.getOps";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";

export default class ReportExample extends LightningElement {
  @track stageOptions = [];
  stage = "";
  @track limitSize = 200;

  @wire(getOpps, { stage: "$stage", limitSize: "$limitSize" })
  wiredData;

  @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
  opportunityInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$opportunityInfo.data.defaultRecordTypeId",
    fieldApiName: STAGE_FIELD
  })
  stagePicklistValues({ data, error }) {
    if (data) {
      console.log(data);
      this.stageOptions = data.values.map((stage) => ({
        label: stage.label,
        value: stage.value
      }));
    } else if (error) {
      console.error("Error fetching stages:", error);
    }
  }

  get columns() {
    return [
      { label: "Name", fieldName: "Name" },
      { label: "Account", fieldName: "AccountName" },
      { label: "Amount", fieldName: "Amount", type: "currency" },
      { label: "Close Date", fieldName: "CloseDate", type: "date" },
      { label: "Owner", fieldName: "OwnerName" },
      { label: "Stage", fieldName: "StageName" }
    ];
  }

  get rows() {
    const data = this.wiredData?.data || [];

    return data.map((r) => ({
      Id: r.Id,
      Name: r.Name,
      AccountName: r.Account?.Name,
      Amount: r.Amount,
      CloseDate: r.CloseDate,
      OwnerName: r.Owner?.Name,
      StageName: r.StageName
    }));
  }

  handleStageChange(e) {
    this.stage = e.target.value;
  }

  handleLimitChange(e) {
    this.limitSize = Number(e.target.value || 200);
  }
}
