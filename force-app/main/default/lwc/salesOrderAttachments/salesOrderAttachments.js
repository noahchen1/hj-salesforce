import { LightningElement, api } from "lwc";

const BASE_ROW = Object.freeze({
  fileUrl: ""
});

export default class SalesOrderAttachments extends LightningElement {
  @api orderType;

  rows = [];
  nextRowId = 0;

  get isSalesOrder() {
    return this.orderType === "sales";
  }

  get isSpecialOrder() {
    return this.orderType === "special";
  }

  get isRepairOrder() {
    return this.orderType === "repair";
  }
}
