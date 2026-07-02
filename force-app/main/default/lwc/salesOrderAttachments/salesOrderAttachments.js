import { LightningElement, api } from "lwc";
import { deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createSalesforceFile from "@salesforce/apex/NsFileController.createSalesforceFile";
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
  isSavingPhoto = false;
  hasConfiguredCameraInput = false;
  isCameraOpen = false;
  cameraStream;

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

  disconnectedCallback() {
    this.stopCameraStream();
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
        sourceRows.map(async (sourceRow) => {
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

  async handleTakePhotoClick() {
    if (!navigator.mediaDevices?.getUserMedia) {
      return;
    }

    try {
      this.cameraStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: {
            ideal: "environment"
          }
        },
        audio: false
      });

      console.log(JSON.stringify(this.cameraStream));

      this.isCameraOpen = true;
      await Promise.resolve();
      this.attachCameraStream();
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message:
            "Unable to open the camera preview. You can choose a photo instead.",
          variant: "error"
        })
      );

      console.error("Error opening camera preview:", error);
    }
  }

  attachCameraStream() {
    const video = this.template.querySelector(".camera-video");

    if (!video || !this.cameraStream) {
      return;
    }

    video.srcObject = this.cameraStream;
    video.autoplay = true;
    video.muted = true;
    video.playsInline = true;

    try {
      video.play();
    } catch (error) {
      console.error("Error playing camera preview:", error);
    }
  }

  async handleCapturePhotoClick() {
    const video = this.template.querySelector(".camera-video");
    const canvas = this.template.querySelector(".camera-canvas");

    if (!video || !canvas || !video.videoWidth || !video.videoHeight) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "Camera preview is not ready yet.",
          variant: "error"
        })
      );

      return;
    }

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext("2d").drawImage(video, 0, 0, canvas.width, canvas.height);

    const [prefix, base64Data] = canvas
      .toDataURL("image/jpeg", 0.92)
      .split(",");

    this.isSavingPhoto = true;

    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");

      await this.savePhoto({
        base64Data,
        fileName: `Captured_Photo_${timestamp}.jpg`
      });
      this.closeCameraPreview();
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "Unable to save the photo. Please try again.",
          variant: "error"
        })
      );

      console.error("Error saving camera photo:", error);
    } finally {
      this.isSavingPhoto = false;
    }
  }

  handleCancelCameraClick() {
    this.closeCameraPreview();
  }

  closeCameraPreview() {
    this.stopCameraStream();
    this.isCameraOpen = false;
  }

  stopCameraStream() {
    this.cameraStream?.getTracks().forEach((track) => track.stop());
    this.cameraStream = null;

    const video = this.template.querySelector(".camera-video");

    if (video) {
      video.srcObject = null;
    }
  }

  async savePhoto({ base64Data, fileName }) {
    const file = await createSalesforceFile({
      fileName,
      base64Data
    });
    const fileUrl = await createContentDistributionUrl({
      fileName: file.name,
      contentVersionId: file.contentVersionId
    });

    const row = this.createRow({
      overrides: {
        name: file.name,
        documentId: file.documentId,
        contentVersionId: file.contentVersionId,
        fileUrl
      }
    });

    this.rows = [...this.rows, row];
    this.emitAttachmentChange();
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
