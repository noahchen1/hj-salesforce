import { LightningElement, api } from "lwc";

export default class SalesOrderTabs extends LightningElement {
  @api orderType;

  get isRepairOrder() {
    return this.orderType === "repair";
  }

  handleTableSectionClick(e) {
    const tableType = e.target.dataset.tabletype;

    this.dispatchEvent(
      new CustomEvent("tablesectionchange", {
        detail: {
          tableType: tableType
        }
      })
    );
  }
}


  // get isRepairItemTable() {
  //   return this.repairTableType === "items";
  // }

  // get isRepairInstructionTable() {
  //   return this.repairTableType === "instructions";
  // }

  // get isRepairCommentsTable() {
  //   return this.repairTableType === "comments";
  // }

  // get isRepairNoteTable() {
  //   return this.repairTableType === "notes";
  // }

  // get isRepairAttachmentTable() {
  //   return this.repairTableType === "attachments";
  // }