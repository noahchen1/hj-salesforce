import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getSubsidiaries from "@salesforce/apex/DropdownDataController.getSubsidiaries";
import USER_ID from "@salesforce/user/Id";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import saveSalesOrder from "@salesforce/apex/SalesOrderController.saveSalesOrder";
import saveInstruction from "@salesforce/apex/InstructionController.saveInstruction";
import saveComment from "@salesforce/apex/CommentController.saveComment";
import getOrderData from "@salesforce/apex/SalesOrderController.getOrderData";
import getOrder from "@salesforce/apex/SalesOrderController.getOrder";
import getSubsidiaryLocations from "@salesforce/apex/DropdownDataController.getSubsidiaryLocations";
import LightningAlert from "lightning/alert";
import LightningConfirm from "lightning/confirm";
import getEmployeeData from "@salesforce/apex/DataService.getEmployeeData";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import COMPANY_NAME from "@salesforce/schema/breadwinner_ns__BW_Company__c.Name";
import PAYMENT_TERM from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__TermsName__c";
import ACCOUNT_ID from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__Salesforce_Account__c";
import getObjectName from "@salesforce/apex/SalesOrderController.getObjectName";
import getNsCompanyFromAccount from "@salesforce/apex/SalesOrderController.getNsCompanyFromAccount";
import getCustomerAddresses from "@salesforce/apex/DropdownDataController.getCustomerAddresses";
import notifyOrderSaveStatus from "@salesforce/apex/SalesOrderController.notifyOrderSaveStatus";
import { processPicklistData } from "c/salesOrderUtils";
import { VENDOR_REQUIRED_ITEM_TYPES } from "c/salesOrderUtils";
import { isValidRolexVendorNum } from "c/salesOrderUtils";
import { isBlank } from "c/utils";

const DEFAULT_FORM_STATE = Object.freeze({
  custNsInternalId: "",
  date: new Date().toISOString(),
  runningUserName: "",
  runningUserId: "",
  salesRep1: "",
  salesRep2: "",
  location: "",
  memo: "",
  orderType: "sales",
  tableType: "items",
  paymentTerm: "149",
  specialDate: null,
  needByDate: null,
  specialOrderItemType: "",
  specialOrderVendor: "",
  specialOrderRequestedVendor: "",
  specialOrderComments: "",
  specialOrderNotes: "",
  specialOrderMemoOrSold: "2",
  specialOrderStatus: "",
  repairType: "",
  repairStation: "",
  repairPerson: "",
  repairLocation: "",
  repairVendor: "",
  shipRepairTo: "",
  repairDescription: "",
  extendedDescription: "",
  dateOpened: null,
  datePromised: null,
  subsidiary: "",
  address: {
    shippingAddressState: {},
    billingAddressState: {}
  },
  lineItems: [],
  instructions: [],
  comments: [],
  notes: [],
  attachments: []
});

const FORM_STATE_FIELDS = new Set(Object.keys(DEFAULT_FORM_STATE));

export default class SalesOrder extends NavigationMixin(LightningElement) {
  @api recordId;

  soNsInternalId;
  accountId;
  formState = { ...DEFAULT_FORM_STATE };
  selectedNsCompanyId;

  isLoading = true;
  locationOptions = [];
  addressOptions = [];
  subsidiaryOptions = [];

  isOrderTypeDisabled = false;
  isSubsidiaryDisbaled = false;

  isFormInit = false;
  isAddressLoaded = false;
  isLocationLoaded = false;
  isOrderLoaded = false;
  isNsCompanyIdLoaded = false;
  isCustomerDataLoaded = false;

  loadingMessage = "";

  updateFormState(patch) {
    this.formState = {
      ...this.formState,
      ...patch
    };
  }

  setFormField(field, value) {
    this.updateFormState({ [field]: value });
  }

  setAddressState(addressState = {}) {
    this.updateFormState({
      address: {
        shippingAddressState: {
          ...(addressState.shippingAddressState || {})
        },
        billingAddressState: {
          ...(addressState.billingAddressState || {})
        }
      }
    });
  }

  setLineItems(rows = []) {
    this.updateFormState({
      lineItems: rows.map((row) => ({ ...row }))
    });
  }

  setInstructions(rows = []) {
    this.updateFormState({
      instructions: rows.map((row) => ({ ...row }))
    });
  }

  setComments(rows = []) {
    this.updateFormState({
      comments: rows.map((row) => ({ ...row }))
    });
  }

  setNotes(rows = []) {
    this.updateFormState({
      notes: rows.map((row) => ({ ...row }))
    });
  }

  get header() {
    return this.template.querySelector("c-sales-order-body");
  }

  get addressSection() {
    return this.template.querySelector("c-sales-order-address");
  }

  get lineItems() {
    return this.template.querySelector("c-sales-order-line-items");
  }

  get isSpecialOrder() {
    return this.formState.orderType === "special";
  }

  get isRepairOrder() {
    return this.formState.orderType === "repair";
  }

  get parentRecordId() {
    return this.accountId || this.recordId;
  }

  get showLoadingMessage() {
    return this.loadingMessage !== "";
  }

  get isLineItemTableOn() {
    return this.formState.tableType === "items";
  }

  get isInstructionTableOn() {
    return this.formState.tableType === "instructions";
  }

  get isCommentsTableOn() {
    return this.formState.tableType === "comments";
  }

  get isNotesTableOn() {
    return this.formState.tableType === "notes";
  }

  get isAttachmentsTableOn() {
    return this.formState.tableType === "attachments";
  }

  get lineItemPanelClass() {
    return this.isLineItemTableOn ? "" : "tab-hidden";
  }

  get instructionPanelClass() {
    return this.isInstructionTableOn ? "" : "tab-hidden";
  }

  get commentPanelClass() {
    return this.isCommentsTableOn ? "" : "tab-hidden";
  }

  get notePanelClass() {
    return this.isNotesTableOn ? "" : "tab-hidden";
  }

  get showTableOverlay() {
    const state = this.formState;

    if (state.orderType === "sales") {
      return !(
        state.custNsInternalId &&
        state.salesRep1 &&
        state.subsidiary &&
        state.location &&
        state.date
      );
    } else if (state.orderType === "special") {
      return !(
        state.custNsInternalId &&
        state.salesRep1 &&
        state.subsidiary &&
        state.location &&
        state.date &&
        state.needByDate &&
        state.specialOrderItemType &&
        (!VENDOR_REQUIRED_ITEM_TYPES.has(state.specialOrderItemType) ||
          state.specialOrderVendor) &&
        state.specialOrderMemoOrSold
      );
    }

    return false;
  }

  @wire(getSubsidiaryLocations, { subsidiary: "$formState.subsidiary" })
  handleLocations({ data, error }) {
    if (error) {
      console.error("Error fetching locationOptions:", error);
      this.locationOptions = [{ label: "Select", value: "" }];
      this.isLocationLoaded = true;
      this.checkLoadingState();
      return;
    }
    const { options } = processPicklistData(data);
    this.locationOptions = options;
    this.isLocationLoaded = true;
    this.checkLoadingState();
  }

  @wire(getObjectName, { recordId: "$recordId" })
  handleObjName({ data, error }) {
    if (data) {
      if (data === "Account") {
        this.isOrderLoaded = true;
        this.fetchNsCompanyId(this.recordId);
      } else {
        this.isNsCompanyIdLoaded = true;
        this.isOrderTypeDisabled = true;
        this.isSubsidiaryDisbaled = true;
        this.loadOrder();
      }

      this.checkLoadingState();
    } else if (error) {
      console.error("Error fetching record type", error);
    }
  }

  @wire(getRecord, {
    recordId: "$selectedNsCompanyId",
    fields: [COMPANY_NAME, PAYMENT_TERM, ACCOUNT_ID]
  })
  wiredCustomerData({ data, error }) {
    if (data && this.selectedNsCompanyId != null) {
      const companyName = getFieldValue(data, COMPANY_NAME);
      const paymentTermText = getFieldValue(data, PAYMENT_TERM);
      const accountId = getFieldValue(data, ACCOUNT_ID);

      if (companyName) {
        this.header?.setLookupValue("customer", companyName);
      }

      if (paymentTermText) {
        const options = this.header?.paymentTermOptions;
        const paymentTermObj = options.filter(
          ({ label }) => label === paymentTermText
        );

        if (paymentTermObj.length > 0) {
          this.setFormField("paymentTerm", paymentTermObj[0].value);
        }
      }

      if (accountId) this.accountId = accountId;

      this.isCustomerDataLoaded = true;
      this.checkLoadingState();

      this.fetchCustomerAddresses({
        nsCompanyId: this.selectedNsCompanyId,
        location: this.formState.location
      });
    } else {
      // this._addressSection?.reset();

      if (error) console.error("Error fetching customer data", error);
      this.isCustomerDataLoaded = true;
      this.checkLoadingState();
    }
  }

  async connectedCallback() {
    await this.initForm();

    if (!this.recordId) {
      this.initializeStandaloneState();
    }
  }

  initializeStandaloneState() {
    this.addressOptions = [{ label: "Select", value: "" }];
    this.isAddressLoaded = true;
    this.isOrderLoaded = true;
    this.isNsCompanyIdLoaded = true;
    this.isCustomerDataLoaded = true;
    this.checkLoadingState();
  }

  async initForm() {
    try {
      const [subsidiaries, emp] = await Promise.all([
        getSubsidiaries(),
        getEmployeeData({ userId: USER_ID })
      ]);

      const { options: subOptions } = processPicklistData(subsidiaries);
      this.subsidiaryOptions = subOptions;

      this.updateFormState({
        subsidiary: emp.subsidiaryId || "",
        location: emp.locationId || "",
        salesRep1: emp.employeeId || "",
        runningUserName: emp.employeeName || "",
        runningUserId: emp.employeeId || ""
      });

      if (emp.employeeId && emp.employeeName) {
        this.header?.setLookupValue("salesRep1", emp.employeeName);
      }

      if (this.formState.subsidiary) {
        const locations = await getSubsidiaryLocations({
          subsidiary: this.formState.subsidiary
        });

        const { options: locOptions } = processPicklistData(locations);
        this.locationOptions = locOptions;

        if (
          !this.locationOptions.some(
            (opt) => opt.value === this.formState.location
          )
        ) {
          this.setFormField("location", "");
        }
      }
    } catch (error) {
      console.error("Init failed:", error);
    } finally {
      this.isFormInit = true;
      this.checkLoadingState();
    }
  }

  handleCustomerSelect(e) {
    this.selectedNsCompanyId = e.detail.id;
    this.setFormField("custNsInternalId", e.detail.nsId);
    this.accountId = "";
  }

  handleHeaderFieldChange(e) {
    this.setFormField(e.detail.field, e.detail.value);
  }

  handleHeaderFieldClear(e) {
    const field = e.detail.field;
    if (field === "customer") {
      this.setFormField("custNsInternalId", "");
      this.accountId = "";
      return;
    }

    if (FORM_STATE_FIELDS.has(field)) {
      this.setFormField(field, "");
    }
  }

  handleAddressStateChange(e) {
    this.setAddressState(e.detail);
  }

  handleLineItemsChange(e) {
    this.setLineItems(e.detail?.rows || []);
  }

  handleInstructionChange(e) {
    this.setInstructions(e.detail?.rows || []);
    console.log(JSON.stringify(this.formState.instructions));
  }

  handleCommentChange(e) {
    this.setComments(e.detail?.rows || []);
    console.log(JSON.stringify(this.formState.comments));
  }

  handleNoteChange(e) {
    this.setNotes(e.detail?.rows || []);
    console.log(JSON.stringify(this.formState.notes));
  }

  handleHeaderComboboxChange(e) {
    const { name, value } = e.detail;

    if (name === "orderType") {
      this.setFormField(name, value);
      this.reset();

      const isSpecialOrder = value === "special";

      if (isSpecialOrder) {
        this.initSpecialOrderForm();
      }

      return;
    }

    if (name === "specialOrderItemType") {
      const isRolex = value === "6";

      this.updateFormState({
        specialOrderVendor: "",
        specialOrderRequestedVendor: ""
      });

      if (isRolex) {
        this.setFormField("specialOrderVendor", "220");

        this.header?.setLookupValue(
          "specialOrderVendor",
          "ROLEX WATCH U.S.A., INC"
        );
      } else {
        this.setFormField("specialOrderVendor", "");

        this.header?.setLookupValue("specialOrderVendor", "");
      }

      const itemMap = {
        1: { itemId: 213836, itemName: "Special Order Item Designer" },
        2: { itemId: 213837, itemName: "Special Order Item Giftware" },
        3: { itemId: 213838, itemName: "Special Order Item Jewelry" },
        4: { itemId: 213839, itemName: "Special Order Item Watch" },
        5: { itemId: 213840, itemName: "Special Order Item Watch Strap" },
        6: { itemId: 213841, itemName: "Special Order Item Rolex" },
        7: { itemId: 213842, itemName: "Special Order Item Patek" },
        101: { itemId: 213834, itemName: "Special Order Item Bridal" }
      };

      const item = itemMap[value] || null;

      if (item) {
        this.lineItems?.setSpecialItem(item);
      }
    }

    if (name === "subsidiary" && this.formState.subsidiary !== value) {
      this.setFormField("location", "");
      // this.lineItems?.reset();
    }

    // if (name === "location" && this.location !== value) {
    //   this.lineItems?.reset();
    // }

    this.setFormField(name, value);
  }

  handleTableSecionChange(e) {
    const tableType = e.detail.tableType;

    this.setFormField("tableType", tableType);
  }

  async reset() {
    this.isLoading = true;
    this.loadingMessage = "";
    this.isFormInit = false;
    this.isAddressLoaded = false;
    this.isNsCompanyIdLoaded = false;

    const orderType = this.formState.orderType || DEFAULT_FORM_STATE.orderType;

    this.formState = {
      ...DEFAULT_FORM_STATE,
      orderType: orderType,
      date: new Date().toISOString(),
      specialDate: "",
      needByDate: "",
      address: {
        shippingAddressState: {},
        billingAddressState: {}
      },
      lineItems: []
    };
    this.accountId = this.recordId || "";
    this.selectedNsCompanyId = undefined;
    this.locationOptions = [];
    this.addressOptions = [{ label: "Select", value: "" }];

    this.lineItems?.reset();
    this.addressSection?.reset();
    this.header?.setLookupValue("customer", "");
    this.header?.setLookupValue("salesRep1", "");
    this.header?.setLookupValue("salesRep2", "");

    if (this.parentRecordId) {
      await Promise.all([
        this.initForm(),
        this.fetchNsCompanyId(this.parentRecordId)
      ]);
      return;
    }

    await this.initForm();
    this.initializeStandaloneState();
  }

  async saveOrder() {
    if (this.isLoading) return;

    let payload;

    try {
      payload = this.buildPayload();

      this.validateFields(payload);
    } catch (error) {
      await LightningAlert.open({
        label: "Validation Error",
        message: error?.message || "Order validation failed.",
        theme: "error"
      });

      return;
    }

    let navigateAway = false;

    if (this.parentRecordId) {
      navigateAway = await LightningConfirm.open({
        label: "Save Order",
        message:
          "Would you like to go back to the account while the order saves in the background?",
        theme: "default"
      });
    }

    this.isLoading = true;
    this.loadingMessage = "Order is being saved";
    const savePromise = this.executeSave(payload);

    if (navigateAway) {
      const targetRecordId = this.parentRecordId;
      this.isLoading = false;
      this.reset();

      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: targetRecordId,
          actionName: "view"
        }
      });

      try {
        const { soNsInternalId, orderRecordId } = await savePromise;

        await notifyOrderSaveStatus({
          isSuccess: true,
          soNsInternalId,
          orderRecordId,
          errorMessage: null
        });
      } catch (error) {
        console.error("saveOrder failed");
        console.error(error.name);
        console.error(error.message);
        console.error(error.stack);

        await notifyOrderSaveStatus({
          isSuccess: false,
          soNsInternalId: null,
          orderRecordId: targetRecordId,
          errorMessage:
            error?.body?.message || error?.message || "Unknown error"
        });
      }

      return;
    }

    try {
      const { soNsInternalId, orderRecordId, isUpdate } = await savePromise;

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Order Saved",
          message: `Order ${isUpdate ? "updated" : "created"} successfully. Internal ID: ${soNsInternalId}`,
          variant: "success"
        })
      );

      if (orderRecordId) {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: { recordId: orderRecordId, actionName: "view" }
        });
      }

      this.reset();
    } catch (err) {
      console.error("saveOrder failed");
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);
      LightningAlert.open({
        label: "Error!",
        message: `Order was not saved, cause: ${err?.body?.message || err?.message}`,
        theme: "error"
      });
    } finally {
      this.isLoading = false;
    }
  }

  buildPayload() {
    const { shippingAddressState = {}, billingAddressState = {} } =
      this.formState.address || {};

    const lineItems = this.formState.lineItems;
    const instructions = this.formState.instructions;
    const comments = this.formState.comments;
    const notes = this.formState.notes;
    const attachments = this.formState.attachments;

    const payload = {
      orderType: this.formState.orderType,
      soNsInternalId: this.soNsInternalId,
      custNsInternalId: this.formState.custNsInternalId,
      orderDate: new Date(this.formState.date).toLocaleDateString("en-CA"),
      salesRep1: this.formState.salesRep1,
      salesRep2: this.formState.salesRep2,
      subsidiary: this.formState.subsidiary,
      location: this.formState.location,
      termsNsInternalId: this.formState.paymentTerm,
      memo: this.formState.memo,
      specialOrderItemType: this.formState.specialOrderItemType,
      specialOrderVendor: this.formState.specialOrderVendor,
      specialOrderRequestedVendor: this.formState.specialOrderRequestedVendor,
      specialOrderComments: this.formState.specialOrderComments,
      specialOrderNotes: this.formState.specialOrderNotes,
      specialOrderMemoOrSold: this.formState.specialOrderMemoOrSold,
      repairType: this.formState.repairType,
      repairStation: this.formState.repairStation,
      repairPerson: this.formState.repairPerson,
      repairLocation: this.formState.repairLocation,
      repairVendor: this.formState.repairVendor,
      shipRepairTo: this.formState.shipRepairTo,
      repairDescription: this.formState.repairDescription,
      extendedDescription: this.formState.extendedDescription,
      dateOpened: this.formState.dateOpened,
      datePromised: this.formState.datePromised,
      shippingAddressJson: JSON.stringify(shippingAddressState),
      billingAddressJson: JSON.stringify(billingAddressState),
      lineItemsJson: JSON.stringify(lineItems),
      instructionsJson: JSON.stringify(instructions),
      commentsJson: JSON.stringify(comments),
      notesJson: JSON.stringify(notes),
      fileJson: JSON.stringify(attachments)
    };

    if (this.formState.specialDate)
      payload.specialDate = this.formState.specialDate;
    if (this.formState.needByDate)
      payload.needByDate = this.formState.needByDate;

    return payload;
  }

  async executeSave(payload = this.buildPayload()) {
    const isUpdate = Boolean(this.soNsInternalId);
    const instructions = this.formState.instructions;
    const comments = this.formState.comments;
    const notes = this.formState.notes;
    const attachments = this.formState.attachments;

    try {
      console.log("saveSalesOrder payload:", JSON.stringify(payload));

      const soNsInternalId = await saveSalesOrder({
        saveParamJson: JSON.stringify(payload)
      });

      this.soNsInternalId = soNsInternalId;

      const orderRecordId = await getOrder({ soNsInternalId });

      if (!isBlank(orderRecordId) && this.isRepairOrder) {
        const instructionSaves = instructions
          .filter(
            ({ nsEmployeeId, instruction }) =>
              !isBlank(nsEmployeeId) && !isBlank(instruction)
          )
          .map(async ({ nsEmployeeId, instruction }) => {
            const instructionId = await saveInstruction({
              nsEmployeeId,
              nsSoId: soNsInternalId,
              instruction
            });

            console.log("instruction inserted: " + instructionId);
          });

        const commentSaves = comments
          .filter(
            ({ nsEmployeeId, comment }) =>
              !isBlank(nsEmployeeId) && !isBlank(comment)
          )
          .map(async ({ nsEmployeeId, comment }) => {
            const commentId = await saveComment({
              nsEmployeeId,
              nsSoId: soNsInternalId,
              comment
            });

            console.log("comment inserted: " + commentId);
          });

        await Promise.all([...instructionSaves, ...commentSaves]);
      }

      return { soNsInternalId, orderRecordId, isUpdate };
    } catch (err) {
      console.error("Failed to save sales order");
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);
      throw err;
    }
  }

  async loadOrder() {
    try {
      const data = await getOrderData({ salesOrderId: this.recordId });

      console.log(data);

      const isSpecialOrder =
        data.specialOrderItemType !== null &&
        data.specialOrderItemType !== "" &&
        data.specialOrderItemType !== undefined;

      this.updateFormState({
        orderType: isSpecialOrder ? "special" : "sales",
        custNsInternalId: data.customerNsId ?? "",
        date: data.orderDate ?? null,
        salesRep1: data.salesRep1NsId ?? "",
        salesRep2: data.salesRep2NsId ?? "",
        memo: data.memo ?? "",
        paymentTerm: data.termNsId ?? "",
        subsidiary: data.subsidiaryNsId ?? "",
        location: data.locationNsId ?? ""
      });
      this.soNsInternalId = data.soNsInternalId ?? "";
      this.accountId = data.accountId ?? "";

      if (isSpecialOrder) {
        this.updateFormState({
          specialDate: data.specialDate ?? null,
          needByDate: data.needByDate ?? null,
          specialOrderItemType: data.specialOrderItemType ?? "",
          specialOrderVendor: data.specialOrderVendorNsId ?? "",
          specialOrderRequestedVendor: data.specialOrderRequestedVendor ?? "",
          specialOrderComments: data.specialOrderComments ?? "",
          specialOrderNotes: data.specialOrderNotes ?? "",
          specialOrderMemoOrSold: data.specialOrderMemoOrSold ?? "",
          specialOrderStatus: data.specialOrderStatus ?? ""
        });
      } else {
        this.updateFormState({
          specialDate: "",
          needByDate: "",
          specialOrderItemType: "",
          specialOrderVendor: "",
          specialOrderRequestedVendor: "",
          specialOrderComments: "",
          specialOrderNotes: "",
          specialOrderMemoOrSold: "",
          specialOrderStatus: ""
        });
      }

      this.addressSection?.loadFromOrderData(data);
      const mappedRows = this.lineItems?.getMappedRows(data.lineItems);
      this.lineItems?.loadRows(mappedRows);
      this.setAddressState({
        shippingAddressState: data.shippingAddress || {},
        billingAddressState: data.billingAddress || {}
      });
      this.setLineItems(mappedRows || []);

      await this.fetchCustomerAddresses({
        nsCompanyId: data.nsCompanyId,
        location: this.formState.location,
        skipSelection: true
      });

      this.header?.setLookupValue("customer", data.customerName ?? "");
      this.header?.setLookupValue("salesRep1", data.salesRep1Name ?? "");
      this.header?.setLookupValue("salesRep2", data.salesRep2Name ?? "");

      if (isSpecialOrder) {
        this.header?.setLookupValue(
          "specialOrderVendor",
          data.specialOrderVendorName
        );
      } else {
        this.header?.setLookupValue("specialOrderVendor", "");
      }
    } catch (error) {
      console.error("Failed to load existing sales order");
      console.error(error.name);
      console.error(error.message);
      console.error(error.stack);
    } finally {
      this.isOrderLoaded = true;
      this.checkLoadingState();
    }
  }

  fetchNsCompanyId = async (accountId) => {
    try {
      const nsCompanyData = await getNsCompanyFromAccount({ accountId });
      if (nsCompanyData) {
        this.selectedNsCompanyId = nsCompanyData.companyId;
        this.setFormField("custNsInternalId", nsCompanyData.internalId);
      } else {
        this.addressOptions = [{ label: "Select", value: "" }];
        this.isAddressLoaded = true;
      }
    } catch (error) {
      console.error("Error fetching NS company from account", error);
      this.addressOptions = [{ label: "Select", value: "" }];
      this.isAddressLoaded = true;
    } finally {
      this.isNsCompanyIdLoaded = true;
      this.checkLoadingState();
    }
  };

  checkLoadingState() {
    if (
      this.isFormInit &&
      this.isAddressLoaded &&
      this.isLocationLoaded &&
      this.isOrderLoaded &&
      this.isNsCompanyIdLoaded &&
      this.isCustomerDataLoaded
    ) {
      this.isLoading = false;
    }
  }

  async fetchCustomerAddresses({ nsCompanyId, location, skipSelection }) {
    if (!nsCompanyId) {
      this.addressOptions = [{ label: "Select", value: "" }];
      this.isAddressLoaded = true;
      this.checkLoadingState();

      return;
    }

    try {
      const addresses = await getCustomerAddresses({
        nsCompanyId,
        nsLocationId: location
      });
      const { options, defaultShipping, defaultBilling } = processPicklistData(
        addresses || [],
        true
      );

      this.addressOptions = options;

      if (!skipSelection) {
        this.addressSection?.applyDefaults(defaultShipping, defaultBilling);
      }

      this.addressSection?.setDefaults(defaultShipping, defaultBilling);
    } catch (error) {
      this.addressOptions = [{ label: "Select", value: "" }];
      console.error("Error fetching addressOptions:", error);

      this.isAddressLoaded = true;
      this.checkLoadingState();
    } finally {
      this.isAddressLoaded = true;
      this.checkLoadingState();
    }
  }

  validateFields(payload) {
    const isHeaderValid = this.header?.validateFields();
    const isLineItemValid = this.lineItems?.validateFields();

    if (!isHeaderValid || !isLineItemValid) {
      throw new Error("Please fill in all required fields.");
    }

    const orderType = payload.orderType;

    if (orderType === "special") {
      const specialOrderItemType = payload.specialOrderItemType;
      const isRolex = specialOrderItemType === "6";

      if (isRolex) {
        let parsedLineItems = [];

        try {
          parsedLineItems = JSON.parse(payload.lineItemsJson || "[]");
        } catch {
          throw new Error("Invalid line item payload.");
        }

        const rolexRows = parsedLineItems.filter(
          (line) => String(line?.item ?? "") === "213841"
        );

        const hasMissingVendorNum =
          rolexRows.length === 0 ||
          rolexRows.some(
            (line) => String(line?.specialOrderVendorNum ?? "").trim() === ""
          );

        if (hasMissingVendorNum) {
          throw new Error("Special Order Vendor # is required for Rolex.");
        }

        const hasInvalidVendorNumFormat = rolexRows.some(
          (line) =>
            !isValidRolexVendorNum(
              String(line?.specialOrderVendorNum ?? "").trim()
            )
        );

        if (hasInvalidVendorNumFormat) {
          throw new Error(
            "Special Order Vendor # format is invalid. Expected: M#####-####."
          );
        }
      }
    }
  }

  initSpecialOrderForm() {
    this.setFormField("specialDate", new Date());
  }
}
