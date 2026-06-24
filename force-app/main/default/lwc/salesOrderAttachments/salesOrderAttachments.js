import { LightningElement, api } from "lwc";
import { deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const BASE_ROW = Object.freeze({
  name: "",
  documentId: "",
  contentVersionId: "",
  contentBodyId: "",
  mimeType: "",
  fileUrl: "",
  downloadUrl: ""
});

export default class SalesOrderAttachments extends LightningElement {
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

  @api getRows() {
    return [...this.rows];
  }

  emitAttachmentChange() {
    this.dispatchEvent(
      new CustomEvent("attachmentchange", {
        detail: {
          rows: this.getRows()
        }
      })
    );
  }

  createRow({ id, overrides = {} }) {
    const rowId = id ?? this.nextRowId++;
    const row = {
      id: rowId,
      ...BASE_ROW
    };

    return {
      ...row,
      ...overrides
    };
  }

  async handleUploadFinished(e) {
    const uploadedFiles = e.detail.files;

    const newRows = uploadedFiles.map((file) => {
      const fileUrl = `/lightning/r/ContentDocument/${file.documentId}/view`;
      const downloadUrl = `https://hamiltonjewelers--full.sandbox.file.force.com/sfc/servlet.shepherd/version/download/${file.contentVersionId}`;

      const row = this.createRow({
        overrides: {
          name: file.name,
          documentId: file.documentId,
          contentVersionId: file.contentVersionId,
          contentBodyId: file.contentBodyId,
          mimeType: file.mimeType,
          fileUrl: fileUrl,
          downloadUrl: downloadUrl
        }
      });

      return row;
    });

    this.rows = [...this.rows, ...newRows];

    this.emitAttachmentChange();
  }

  async handleRemoveClick(event) {
    const { rowId, documentId } = event.currentTarget.dataset;

    try {
      await deleteRecord(documentId);

      this.rows = this.rows.filter((row) => String(row.id) !== rowId);
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Delete Failed",
          message: "Unable to delete the file. Please try again.",
          variant: "error"
        })
      );

      console.error("Error deleting file:", error);
    }

    this.emitAttachmentChange();
  }
}

// [{"name":"Noah Chen_NPC-00025.pdf","documentId":"069WJ00000FF3eTYAT","contentVersionId":"068WJ00000G60ovYAB","contentBodyId":"05TWJ00000Q6axx2AB","mimeType":"application/pdf"}]
