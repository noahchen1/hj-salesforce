import { LightningElement, api, wire } from "lwc";
import saveSalesOrder from "@salesforce/apex/SalesOrderController.saveSalesOrder";
import saveCustomer from "@salesforce/apex/CustomerController.saveCustomer";
import getInquiryId from "@salesforce/apex/SalesOrderController.getInquiryId";
import getOrder from "@salesforce/apex/SalesOrderController.getOrder";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from "lightning/navigation";
import LightningAlert from "lightning/alert";
import notifyOrderSaveStatus from "@salesforce/apex/SalesOrderController.notifyOrderSaveStatus";

const Types = Object.freeze({
  ROLEX: "ROLEX",
  TUDOR: "TUDOR"
});

export default class InquiryForm extends NavigationMixin(LightningElement) {
  @api recordId;
  isLoading = true;
  navigationTimeoutId;
  inquiryType = null;

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

  get isRolex() {
    return this.inquiryType === Types.ROLEX;
  }

  @wire(CurrentPageReference)
  async parseParam(pageRef) {
    const apiName = pageRef.attributes.apiName;

    if (!apiName) {
      await LightningAlert.open({
        label: "Inquiry Type Error",
        message: "Failed to get inquiry type, please contact your admin!",
        theme: "error"
      });

      return;
    }

    const isRolex = apiName.includes("Rolex_Inquiry");
    const isTudor = apiName.includes("Tudor_Inquiry");

    this.inquiryType = isRolex ? Types.ROLEX : isTudor ? Types.TUDOR : null;
  }

  async createOrders() {
    if (this.isLoading) return;

    this.isLoading = true;

    try {
      this.validateFields();
    } catch (error) {
      await LightningAlert.open({
        label: "Validation Error",
        message: error?.message || "Order validation failed.",
        theme: "error"
      });

      this.isLoading = false;

      return;
    }

    try {
      const bodyFields = this.body?.getFields();

      const [modelFieldsList, inquiryId] = await Promise.all([
        Promise.all([...this.watches].map((watch) => watch.getFields())),

        getInquiryId({ custNsInternalId: bodyFields.customer })
      ]);

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Inquiry Creation In Progress",
          message: "You will get a notification when processing completes!",
          variant: "info"
        })
      );

      this.navigationTimeoutId = setTimeout(() => {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: this.recordId,
            actionName: "view"
          }
        });
      }, 2000);

      const ordersPromise = this.saveOrders(
        modelFieldsList,
        inquiryId,
        bodyFields
      );

      const customerPromise = this.saveCustomerPreferrence(bodyFields);

      await Promise.allSettled([ordersPromise, customerPromise]);
    } catch (error) {
      console.error(error);
      console.error(error.name);
      console.error(error.message);
      console.error(error.stack);
      this.isLoading = false;
    } finally {
      this.isLoading = false;
    }
  }

  async executeSave(payload) {
    try {
      const soNsInternalId = await saveSalesOrder(payload);

      this.soNsInternalId = soNsInternalId;

      const orderRecordId = await getOrder({ soNsInternalId });

      return { soNsInternalId, orderRecordId };
    } catch (err) {
      console.error("Failed to create inquiry.");
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);

      throw err;
    }
  }

  async saveOrders(modelFieldsList, inquiryId, bodyFields) {
    for (const modelFields of modelFieldsList) {
      const isValidModel =
        modelFields.model?.trim() &&
        modelFields.name?.trim() &&
        modelFields.link?.trim();

      if (isValidModel) {
        const payload = this.buildPayload(inquiryId, bodyFields, modelFields);

        console.log(JSON.stringify(payload));

        try {
          const { soNsInternalId, orderRecordId } =
            await this.executeSave(payload);

          await notifyOrderSaveStatus({
            isSuccess: true,
            soNsInternalId,
            orderRecordId,
            errorMessage: null
          });
        } catch (error) {
          await notifyOrderSaveStatus({
            isSuccess: false,
            soNsInternalId: null,
            orderRecordId: this.recordId,
            errorMessage:
              error?.body?.message || error?.message || "Unknown error"
          });
        }
      }
    }
  }

  async saveCustomerPreferrence(bodyFields) {
    try {
      const soCustNsId = await saveCustomer({
        custNsInternalId: bodyFields.customer,
        isEmailPreferred: bodyFields.isEmailPreferred,
        isPhonePreferred: bodyFields.isCallPreferred,
        isMessagePreferred: bodyFields.isMessagePreferred
      });

      return { success: true, soCustNsId };
    } catch (error) {
      console.error("saveCustomer failed");
      console.error(error);

      return { success: false, error: JSON.stringify(error) };
    }
  }

  handleBodyLoaded() {
    this.isLoading = false;
  }

  disconnectedCallback() {
    if (this.navigationTimeoutId) {
      clearTimeout(this.navigationTimeoutId);

      this.navigationTimeoutId = null;
    }
  }

  buildPayload(inquiryId, bodyFields, modelFields) {
    const payload = {
      orderType: "inquiry",
      inquiryType: this.inquiryType,
      custNsInternalId: bodyFields.customer,
      orderDate: bodyFields.date,
      salesRep1: bodyFields.salesRep1,
      salesRep2: bodyFields.salesRep2,
      subsidiary: bodyFields.subsidiary,
      location: bodyFields.location,
      termsNsInternalId: "2",
      specialOrderItemType: this.isRolex ? "6" : "4",

      specialOrderVendor: this.isRolex ? "220" : "313",
      specialOrderRequestedVendor: this.specialOrderRequestedVendor,
      specialOrderComments: bodyFields.comments,
      specialOrderNotes: this.specialOrderNotes,
      specialOrderMemoOrSold: "2",
      specialDate: bodyFields.date,
      needByDate: bodyFields.needByDate,

      inquiryId: inquiryId,
      inquiryModel: modelFields.model,
      inquiryName: modelFields.name,
      inquiryLink: modelFields.link,
      inquiryIsSendEmail: bodyFields.isSendEmail,
      inquiryIsPrority: modelFields.isPriority,
      inquiryIsOpenDial: modelFields.isOpenDial,
      inquiryPersonalMsg: bodyFields.personalization,
      lineItemsJson: JSON.stringify(modelFields.rows ?? [])
    };

    return payload;
  }

  validateFields() {
    const isBodyValid = this.body?.validateFields();
    const isFirstWatchValid = this.firstModel?.validateFields();

    if (!isBodyValid || !isFirstWatchValid) {
      throw new Error("Please fill in all required fields.");
    }
  }
}
