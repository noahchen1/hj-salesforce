import { LightningElement } from "lwc";
import saveSalesOrder from "@salesforce/apex/SalesOrderController.saveSalesOrder";

export default class InquiryForm extends LightningElement {
  get body() {
    return this.template.querySelector("c-inquiry-form-body");
  }

  get firstModel() {
    return this.template.querySelectorAll("c-inquiry-form-items")[0];
  }

  get secondModel() {
    return this.template.querySelectorAll("c-inquiry-form-items")[1];
  }

  get thirdModel() {
    return this.template.querySelectorAll("c-inquiry-form-items")[2];
  }

  get watches() {
    return this.template.querySelectorAll("c-inquiry-form-items");
  }

  async createOrders() {
    try {
      const bodyFields = this.body?.getFields();

      const modelFieldsList = await Promise.all(
        [...this.watches].map((watch) => watch.getFields())
      );

      for (const modelFields of modelFieldsList) {
        const isValidModel =
          modelFields.model?.trim() &&
          modelFields.name?.trim() &&
          modelFields.link?.trim();

        if (isValidModel) {
          const payload = this.buildPayload(bodyFields, modelFields);

          console.log(JSON.stringify(payload));
          const soNsInternalId = await saveSalesOrder(payload);

          console.log(soNsInternalId);
        }
      }
    } catch (error) {
      console.error(error);
      console.error(error.name);
      console.error(error.message);
      console.error(error.stack);
    }
  }

  buildPayload(bodyFields, modelFields) {
    const payload = {
      orderType: "inquiry",
      custNsInternalId: bodyFields.customer,
      orderDate: bodyFields.date,
      salesRep1: bodyFields.salesRep1,
      salesRep2: bodyFields.salesRep2,
      subsidiary: "30",
      location: "28",
      termsNsInternalId: "2",
      specialOrderItemType: "6",

      specialOrderVendor: "220",
      specialOrderRequestedVendor: this.specialOrderRequestedVendor,
      specialOrderComments: bodyFields.comments,
      specialOrderNotes: this.specialOrderNotes,
      specialOrderMemoOrSold: "2",
      specialDate: bodyFields.date,
      needByDate: bodyFields.needByDate,

      inquiryModel: modelFields.model,
      inquiryName: modelFields.name,
      inquiryLink: modelFields.link,
      inquiryIsPrority: modelFields.isPriority,
      inquiryIsOpenDial: modelFields.isOpenDial,
      lineItemsJson: JSON.stringify(modelFields.rows ?? [])
    };

    return payload;
  }
}
