import { LightningElement } from "lwc";

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
    const modelFieldsList = await Promise.all(
      [...this.watches].map((watch) => watch.getFields())
    );

    modelFieldsList.forEach((modelFields) => {
      const isValidModel =
        !!modelFields.model?.trim() &&
        !!modelFields.name?.trim() &&
        !!modelFields.link?.trim();

      if (isValidModel) {
        console.log(JSON.stringify(modelFields));

        // const bodyFields = this.body.getFields();
        // const payload = this.buildPayload(bodyFields, modelFields);
      }
    });
  }

  buildPayload(bodyFields, modelFields) {
    const payload = {
      orderType: "special",
      custNsInternalId: bodyFields.customer,
      orderDate: bodyFields.date,
      salesRep1: bodyFields.salesRep1,
      salesRep2: bodyFields.salesRep2,
      subsidiary: "28",
      location: bodyFields.location,
      termsNsInternalId: "2",
      specialOrderItemType: "6",

      specialOrderVendor: "220",
      specialOrderRequestedVendor: this.specialOrderRequestedVendor,
      specialOrderComments: bodyFields.comments,
      specialOrderNotes: this.specialOrderNotes,
      specialOrderMemoOrSold: "2",
      specialDate: bodyFields.date,
      needByDate: bodyFields.needByDate,

      lineItemsJson: JSON.stringify(modelFields.rows ?? [])

      // orderNum
    };

    return payload;
  }
}
