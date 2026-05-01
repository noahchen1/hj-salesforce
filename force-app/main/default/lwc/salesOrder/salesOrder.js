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
import getObjectName from "@salesforce/apex/SalesOrderController.getObjectName";
import getNsCompanyFromAccount from "@salesforce/apex/SalesOrderController.getNsCompanyFromAccount";
import getCustomerAddresses from "@salesforce/apex/DropdownDataController.getCustomerAddresses";
import notifyOrderSaveStatus from "@salesforce/apex/SalesOrderController.notifyOrderSaveStatus";
import { processPicklistData } from "c/salesOrderUtils";

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
  specialDate = "";
  needByDate = ""
  subsidiary = "";
  isLoading = true;
  locationOptions = [];
  addressOptions = [];
  subsidiaryOptions = [];

  isFormInit = false;
  isAddressLoaded = false;
  isLocationLoaded = false;
  isOrderLoaded = false;
  isNsCompanyIdLoaded = false;

  get header() {
    return this.template.querySelector("c-sales-order-body");
  }

  get addressSection() {
    return this.template.querySelector("c-sales-order-address");
  }

  get lineItems() {
    return this.template.querySelector("c-sales-order-line-items");
  }

  get showTableOverlay() {
    return !(
      this.custNsInternalId &&
      this.salesRep1 &&
      this.subsidiary &&
      this.location &&
      this.date
    );
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
        this.loadOrder();
      }

      this.checkLoadingState();
    } else if (error) {
      console.error("Error fetching record type", error);
    }
  }

  @wire(getRecord, { recordId: "$selectedNsCompanyId", fields: [COMPANY_NAME] })
  wiredCustomerData({ data, error }) {
    if (data && this.selectedNsCompanyId != null) {
      const companyName = getFieldValue(data, COMPANY_NAME);

      if (companyName) {
        this.header?.setLookupValue("customer", companyName);
      }

      this.fetchCustomerAddresses({ nsCompanyId: this.selectedNsCompanyId });
    } else {
      // this._addressSection?.reset();

      if (error) console.error("Error fetching customer data", error);
    }
  }

  async connectedCallback() {
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
  }

  handleSalesRepSelect(e) {
    this[e.detail.type] = e.detail.nsId;
  }

  handleHeaderFieldChange(e) {
    this[e.detail.field] = e.detail.value;
  }

  handleHeaderFieldClear(e) {
    const field = e.detail.field;
    if (field === "customer") {
      this.custNsInternalId = "";
    } else {
      this[field] = "";
    }
  }

  handleHeaderComboboxChange(e) {
    const { name, value } = e.detail;

    if (name === "subsidiary" && this.subsidiary !== value) {
      this.location = "";
      this.lineItems?.reset();
    }

    this[name] = value;
  }

  async saveOrder() {
    if (this.isLoading) return;

    this.isLoading = true;
    const savePromise = this.executeSave();

    const navigateAway = await LightningConfirm.open({
      label: "Save Order",
      message:
        "Would you like to go back to the account while the order saves in the background?",
      theme: "default"
    });

    if (navigateAway) {
      this.isLoading = false;

      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: this.accountId || this.recordId,
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
          orderRecordId: null,
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

  async executeSave() {
    const isUpdate = Boolean(this.soNsInternalId);

    try {
      const { shippingAddressState, billingAddressState } =
        this.addressSection?.getAddressState() ?? {
          shippingAddressState: {},
          billingAddressState: {}
        };

      const rows = this.lineItems?.getRows() ?? [];
      const payload = {
        soNsInternalId: this.soNsInternalId,
        custNsInternalId: this.custNsInternalId,
        orderDate: this.date,
        salesRep1: this.salesRep1,
        salesRep2: this.salesRep2,
        subsidiary: this.subsidiary,
        location: this.location,
        memo: this.memo,
        shippingAddressJson: JSON.stringify(shippingAddressState),
        billingAddressJson: JSON.stringify(billingAddressState),
        lineItemsJson: JSON.stringify(rows)
      };

      console.log("saveSalesOrder payload:", JSON.stringify(payload));

      const soNsInternalId = await saveSalesOrder(payload);
      this.soNsInternalId = soNsInternalId;

      const orderRecordId = await getOrder({ soNsInternalId });

      return { soNsInternalId, orderRecordId, isUpdate };
    } catch (err) {
      throw err;
    }
  }

  async loadOrder() {
    try {
      const data = await getOrderData({ salesOrderId: this.recordId });

      this.soNsInternalId = data.soNsInternalId || this.soNsInternalId;
      this.accountId = data.accountId || this.accountId;
      this.custNsInternalId = data.customerNsId || "";
      this.date = data.orderDate || this.date;
      this.salesRep1 = data.salesRep1NsId || "";
      this.salesRep2 = data.salesRep2NsId || "";
      this.memo = data.memo || "";
      this.subsidiary = data.subsidiaryNsId || "";
      this.location = data.locationNsId || "";

      this.addressSection?.loadFromOrderData(data);
      const mappedRows = this.lineItems?.getMappedRows(data.lineItems);
      const itemNames = mappedRows.map((row) => row.itemName || "");
      this.lineItems?.loadRows(mappedRows, itemNames);

      await this.fetchCustomerAddresses({
        nsCompanyId: data.nsCompanyId,
        skipSelection: true
      });

      this.header?.setLookupValue("customer", data.customerName || "");
      this.header?.setLookupValue("salesRep1", data.salesRep1Name || "");
      this.header?.setLookupValue("salesRep2", data.salesRep2Name || "");
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
      this.isNsCompanyIdLoaded
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
    } finally {
      this.isAddressLoaded = true;
      this.checkLoadingState();
    }
  }
}
