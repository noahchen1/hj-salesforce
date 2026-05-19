import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getSubsidiaries from "@salesforce/apex/DropdownDataController.getSubsidiaries";
import USER_ID from "@salesforce/user/Id";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import saveSalesOrder from "@salesforce/apex/SalesOrderController.saveSalesOrder";
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

export default class SalesOrder extends NavigationMixin(LightningElement) {
  @api recordId;

  soNsInternalId;
  accountId;
  custNsInternalId = "";
  selectedNsCompanyId;
  date = new Date().toISOString();
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  memo = "";
  orderType = "sales";
  paymentTerm = "149";

  specialDate = null;
  needByDate = null;
  specialOrderItemType = "";
  specialOrderVendor = "";
  specialOrderRequestedVendor = "";
  specialOrderComments = "";
  specialOrderNotes = "";
  specialOrderMemoOrSold = "2";
  specialOrderStatus = "";

  subsidiary = "";
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
    return this.orderType === "special";
  }

  get parentRecordId() {
    return this.accountId || this.recordId;
  }

  get showTableOverlay() {
    if (this.orderType === "sales") {
      return !(
        this.custNsInternalId &&
        this.salesRep1 &&
        this.subsidiary &&
        this.location &&
        this.date
      );
    } else if (this.orderType === "special") {
      return !(
        this.custNsInternalId &&
        this.salesRep1 &&
        this.subsidiary &&
        this.location &&
        this.date &&
        this.needByDate &&
        this.specialOrderItemType &&
        (!VENDOR_REQUIRED_ITEM_TYPES.has(this.specialOrderItemType) ||
          this.specialOrderVendor) &&
        this.specialOrderMemoOrSold
      );
    }

    return false;
  }

  @wire(getSubsidiaryLocations, { subsidiary: "$subsidiary" })
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
          this.paymentTerm = paymentTermObj[0].value;
        }
      }

      if (accountId) this.accountId = accountId;

      this.isCustomerDataLoaded = true;
      this.checkLoadingState();

      this.fetchCustomerAddresses({ nsCompanyId: this.selectedNsCompanyId });
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

      this.subsidiary = emp.subsidiaryId || "";
      this.location = emp.locationId || "";
      this.salesRep1 = emp.employeeId || "";

      if (emp.employeeId && emp.employeeName) {
        this.header?.setLookupValue("salesRep1", emp.employeeName);
      }

      if (this.subsidiary) {
        const locations = await getSubsidiaryLocations({
          subsidiary: this.subsidiary
        });

        const { options: locOptions } = processPicklistData(locations);
        this.locationOptions = locOptions;

        if (!this.locationOptions.some((opt) => opt.value === this.location)) {
          this.location = "";
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
    this.custNsInternalId = e.detail.nsId;
    this.accountId = "";
  }

  handleSalesRepSelect(e) {
    this[e.detail.type] = e.detail.nsId;
  }

  handleSpecialOrderVendorSelect(e) {
    this[e.detail.type] = e.detail.nsId;
  }

  handleHeaderFieldChange(e) {
    this[e.detail.field] = e.detail.value;
  }

  handleHeaderFieldClear(e) {
    const field = e.detail.field;
    if (field === "customer") {
      this.custNsInternalId = "";
      this.accountId = "";
    } else {
      this[field] = "";
    }
  }

  handleHeaderComboboxChange(e) {
    const { name, value } = e.detail;

    if (name === "orderType") {
      this[name] = value;
      this.reset();

      const isSpecialOrder = value === "special";

      if (isSpecialOrder) {
        this.initSpecialOrderForm();
      }

      return;
    }

    if (name === "specialOrderItemType") {
      const isRolex = value === "6";

      this.specialOrderVendor = "";
      this.specialOrderRequestedVendor = "";

      if (isRolex) {
        this.specialOrderVendor = "220";

        this.header?.setLookupValue(
          "specialOrderVendor",
          "ROLEX WATCH U.S.A., INC"
        );
      } else {
        this.specialOrderVendor = "";

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

    if (name === "subsidiary" && this.subsidiary !== value) {
      this.location = "";
      // this.lineItems?.reset();
    }

    // if (name === "location" && this.location !== value) {
    //   this.lineItems?.reset();
    // }

    this[name] = value;
  }

  async reset() {
    this.isLoading = true;
    this.isFormInit = false;
    this.isAddressLoaded = false;
    this.isNsCompanyIdLoaded = false;

    this.date = new Date().toISOString();
    this.salesRep1 = "";
    this.salesRep2 = "";
    this.location = "";
    this.memo = "";
    this.paymentTerm = "149";
    this.subsidiary = "";
    this.specialDate = "";
    this.needByDate = "";
    this.accountId = this.recordId || "";
    this.custNsInternalId = "";
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
    const savePromise = this.executeSave(payload);

    if (navigateAway) {
      this.isLoading = false;

      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: this.parentRecordId,
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
          orderRecordId: this.parentRecordId,
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
    const { shippingAddressState, billingAddressState } =
      this.addressSection?.getAddressState() ?? {
        shippingAddressState: {},
        billingAddressState: {}
      };

    const rows = this.lineItems?.getRows() ?? [];

    const payload = {
      orderType: this.orderType,
      soNsInternalId: this.soNsInternalId,
      custNsInternalId: this.custNsInternalId,
      orderDate: this.date,
      salesRep1: this.salesRep1,
      salesRep2: this.salesRep2,
      subsidiary: this.subsidiary,
      location: this.location,
      termsNsInternalId: this.paymentTerm,
      memo: this.memo,
      specialOrderItemType: this.specialOrderItemType,
      specialOrderVendor: this.specialOrderVendor,
      specialOrderRequestedVendor: this.specialOrderRequestedVendor,
      specialOrderComments: this.specialOrderComments,
      specialOrderNotes: this.specialOrderNotes,
      specialOrderMemoOrSold: this.specialOrderMemoOrSold,
      shippingAddressJson: JSON.stringify(shippingAddressState),
      billingAddressJson: JSON.stringify(billingAddressState),
      lineItemsJson: JSON.stringify(rows)
    };

    if (this.specialDate) payload.specialDate = this.specialDate;
    if (this.needByDate) payload.needByDate = this.needByDate;

    return payload;
  }

  async executeSave(payload = this.buildPayload()) {
    const isUpdate = Boolean(this.soNsInternalId);

    try {
      console.log("saveSalesOrder payload:", JSON.stringify(payload));

      const soNsInternalId = await saveSalesOrder(payload);
      this.soNsInternalId = soNsInternalId;
      const orderRecordId = await getOrder({ soNsInternalId });
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

      this.orderType = isSpecialOrder ? "special" : "sales";
      this.soNsInternalId = data.soNsInternalId ?? "";
      this.accountId = data.accountId ?? "";
      this.custNsInternalId = data.customerNsId ?? "";
      this.date = data.orderDate ?? null;
      this.salesRep1 = data.salesRep1NsId ?? "";
      this.salesRep2 = data.salesRep2NsId ?? "";
      this.memo = data.memo ?? "";
      this.paymentTerm = data.paymentTerm ?? "149";
      this.subsidiary = data.subsidiaryNsId ?? "";
      this.location = data.locationNsId ?? "";
      this.paymentTerm = data.termNsId ?? "";

      if (isSpecialOrder) {
        this.specialDate = data.specialDate ?? null;
        this.needByDate = data.needByDate ?? null;
        this.specialOrderItemType = data.specialOrderItemType ?? "";
        this.specialOrderVendor = data.specialOrderVendorNsId ?? "";
        this.specialOrderRequestedVendor =
          data.specialOrderRequestedVendor ?? "";
        this.specialOrderComments = data.specialOrderComments ?? "";
        this.specialOrderNotes = data.specialOrderNotes ?? "";
        this.specialOrderMemoOrSold = data.specialOrderMemoOrSold ?? "";
        this.specialOrderStatus = data.specialOrderStatus ?? "";
      } else {
        this.specialDate = "";
        this.needByDate = "";
        this.specialOrderItemType = "";
        this.specialOrderVendor = "";
        this.specialOrderRequestedVendor = "";
        this.specialOrderComments = "";
        this.specialOrderNotes = "";
        this.specialOrderMemoOrSold = "";
      }

      this.addressSection?.loadFromOrderData(data);
      const mappedRows = this.lineItems?.getMappedRows(data.lineItems);
      this.lineItems?.loadRows(mappedRows);

      await this.fetchCustomerAddresses({
        nsCompanyId: data.nsCompanyId,
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
        this.custNsInternalId = nsCompanyData.internalId;
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

  async fetchCustomerAddresses({ nsCompanyId, skipSelection }) {
    if (!nsCompanyId) {
      this.addressOptions = [{ label: "Select", value: "" }];
      this.isAddressLoaded = true;
      this.checkLoadingState();

      return;
    }

    try {
      const addresses = await getCustomerAddresses({ nsCompanyId });
      const { options, defaultShipping, defaultBilling } = processPicklistData(
        addresses || [],
        true
      );

      this.addressOptions = options;

      if (!skipSelection) {
        this.addressSection?.applyDefaults(defaultShipping, defaultBilling);
      }
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
        } catch (error) {
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
    this.specialDate = new Date().toISOString();
  }
}
