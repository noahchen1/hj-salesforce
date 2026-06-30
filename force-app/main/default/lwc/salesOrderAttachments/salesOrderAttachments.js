import { LightningElement, api } from "lwc";
import { deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createContentDistributionUrl from "@salesforce/apex/NsFileService.createContentDistributionUrl";

const BASE_ROW = Object.freeze({
  name: null,
  documentId: null,
  contentVersionId: null,
  fileUrl: null
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

  @api
  reset() {
    this.rows = [];
    this.nextRowId = 0;
    this.emitAttachmentChange();
  }

  @api
  async setRows(rows) {
    const sourceRows = rows || [];

    if (sourceRows.length === 0) {
      this.reset();

      return;
    }

    try {
      this.rows = await Promise.all(
        sourceRows.map(async sourceRow => {
          const fileUrl = await createContentDistributionUrl({
            fileName: sourceRow.name,
            contentVersionId: sourceRow.contentVersionId
          });

          const row = this.createRow({
            overrides: {
              name: sourceRow.name,
              documentId: sourceRow.documentId,
              contentVersionId: sourceRow.contentVersionId,
              fileUrl: fileUrl
            }
          });

          return row;
        })
      );

      this.nextRowId = this.rows.length + 1;

      this.emitAttachmentChange();
    } catch (error) {
      this.showContentUrlError(error);
    }
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

    try {
      const newRows = await Promise.all(
        uploadedFiles.map(async (file) => {
          const fileUrl = await createContentDistributionUrl({
            fileName: file.name,
            contentVersionId: file.contentVersionId
          });

          const row = this.createRow({
            overrides: {
              name: file.name,
              documentId: file.documentId,
              contentVersionId: file.contentVersionId,
              fileUrl: fileUrl
            }
          });

          return row;
        })
      );

      this.rows = [...this.rows, ...newRows];

      this.emitAttachmentChange();
    } catch (error) {
      console.error("Error creating file URL:", error);
    }
  }

  async handleRemoveClick(e) {
    const { rowId, documentId } = e.currentTarget.dataset;

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
