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
import getEmployeeData from "@salesforce/apex/DataService.getEmployeeData";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import COMPANY_NAME from "@salesforce/schema/breadwinner_ns__BW_Company__c.Name";
import getObjectName from "@salesforce/apex/SalesOrderController.getObjectName";
import getNsCompanyFromAccount from "@salesforce/apex/SalesOrderController.getNsCompanyFromAccount";
import getCustomerAddresses from "@salesforce/apex/DropdownDataController.getCustomerAddresses";

export default class SalesOrder extends LightningElement {
  @api recordId;

  internalId;
  customer = "";
  selectedCustomerId;
  date = new Date().toISOString();
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  memo = "";
  subsidiary = "";
  isLoading = false;
  locationOptions = [];
  addressOptions = [];
  subsidiaryOptions = [];

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
      this.customer &&
      this.salesRep1 &&
      this.subsidiary &&
      this.location &&
      this.date
    );
  }

  @wire(getObjectName, { recordId: "$recordId" })
  handleObjName({ data, error }) {
    if (data) {
      if (data === "Account") {
        this.isLoading = true;
        this.fetchNsCompanyId(this.recordId);
      } else {
        this.loadOrder();
      }
    } else if (error) {
      console.error("Error fetching record type", error);
    }
  }

  @wire(getRecord, { recordId: "$selectedCustomerId", fields: [COMPANY_NAME] })
  wiredCustomerData({ data, error }) {
    if (data && this.selectedCustomerId != null) {
      const companyName = getFieldValue(data, COMPANY_NAME);

      if (companyName) {
        this.header?.setLookupValue("customer", companyName);
      }

      this.fetchCustomerAddresses({ nsCompanyId: this.selectedCustomerId });
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

      this.processPicklistWire({ data: subsidiaries }, "locationOptions");
      this.subsidiaryOptions = subsidiaries;

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

        this.processPicklistWire({ data: locations }, "locationOptions");

        if (!this.locationOptions.some((opt) => opt.value === this.location)) {
          this.location = "";
        }
      }
    } catch (error) {
      console.error("Init failed:", error);
    }
  }

  handleCustomerSelect(e) {
    this.selectedCustomerId = e.detail.id;
    this.customer = e.detail.nsId;
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
      this.customer = "";
    } else {
      this[field] = "";
    }
  }

  handleHeaderComboboxChange(e) {
    const { name, value } = e.detail;
    if (name === "subsidiary" && this.subsidiary !== value) {
      this.location = "";
    }
    this[name] = value;
  }

  async saveOrder() {
    if (this.isLoading) return;

    console.log(
      "SalesOrder state",
      JSON.stringify({
        internalId: this.internalId,
        customer: this.customer,
        selectedCustomerId: this.selectedCustomerId,
        date: this.date,
        salesRep1: this.salesRep1,
        salesRep2: this.salesRep2,
        location: this.location,
        memo: this.memo,
        subsidiary: this.subsidiary,
        isLoading: this.isLoading,
        locationOptions: this.locationOptions,
        addressOptions: this.addressOptions,
        subsidiaryOptions: this.subsidiaryOptions
      })
    );

    this.isLoading = true;
    const isUpdate = Boolean(this.internalId);

    try {
      const { shippingAddressState, billingAddressState } =
        this.addressSection?.getAddressState() ?? {
          shippingAddressState: {},
          billingAddressState: {}
        };

      const rows = this.lineItems?.getRows() ?? [];

      const payload = {
        internalId: this.internalId,
        customer: this.customer,
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

      console.log("saveSalesOrder payload:", payload);

      const internalId = await saveSalesOrder(payload);

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Order Saved",
          message: `Order ${isUpdate ? "updated" : "created"} successfully. Internal ID: ${internalId}`,
          variant: "success"
        })
      );

      this.internalId = internalId;

      const recordId = await getOrder({ internalId });
      if (recordId) {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: { recordId, actionName: "view" }
        });
      }
    } catch (err) {
      console.error("saveOrder failed", err);
      LightningAlert.open({
        label: "Error!",
        message: `Order was not saved, cause: ${err?.body?.message}`,
        theme: "error"
      });
    } finally {
      this.isLoading = false;
    }
  }

  async loadOrder() {
    this.isLoading = true;

    try {
      const data = await getOrderData({ salesOrderId: this.recordId });

      console.log(data);

      this.internalId = data.internalId || this.internalId;
      this.customer = data.customerNsId || "";
      this.date = data.orderDate || this.date;
      this.salesRep1 = data.salesRep1NsId || "";
      this.salesRep2 = data.salesRep2NsId || "";
      this.memo = data.memo || "";
      this.subsidiary = data.subsidiaryNsId || "";
      this.location = data.locationNsId || "";

      // Populate address section from saved order data
      this.addressSection?.loadFromOrderData(data);

      // Map and load line items
      const mappedRows = (data.lineItems || []).map((line, index) => {
        const qty = line.quantity || "";
        const rate = line.rate || "";
        const amount = line.amount || "";
        const itemName = line.itemName || "";
        const isDiscount = itemName === "Store Discount";
        const lineNum = line.line || "";

        return {
          id: index + 1,
          item: line.item || "",
          itemName,
          quantity: isDiscount ? "" : qty,
          rate,
          amount,
          line: lineNum,
          isDiscount,
          showAction: index === 0,
          disableRemove: index === 0
        };
      });

      const itemNames = mappedRows.map((row) => row.itemName || "");
      this.lineItems?.loadRows(mappedRows, itemNames);

      // Fetch address dropdown options without auto-selecting defaults
      await this.fetchCustomerAddresses({
        nsCompanyId: data.nsCompanyId,
        skipSelection: true
      });

      // Restore lookup display labels
      this.header?.setLookupValue("customer", data.customerName || "");
      this.header?.setLookupValue("salesRep1", data.salesRep1Name || "");
      this.header?.setLookupValue("salesRep2", data.salesRep2Name || "");
    } catch (error) {
      console.error("Failed to load existing sales order", error);
    } finally {
      this.isLoading = false;
    }
  }

  processPicklistWire({ data, error }, target) {
    if (data) {
      this[target] = [
        { label: "All", value: "" },
        ...data.map(({ label, value }) => ({ label, value }))
      ];
    } else if (error) {
      console.error(`Error fetching ${target}: `, error);
    }
  }

  fetchNsCompanyId = async (accountId) => {
    try {
      const nsCompanyData = await getNsCompanyFromAccount({ accountId });
      if (nsCompanyData) {
        this.selectedCustomerId = nsCompanyData.companyId;
        this.customer = nsCompanyData.internalId;
      }
    } catch (error) {
      console.error("Error fetching NS company from account", error);
    } finally {
      this.isLoading = false;
    }
  };

  async fetchCustomerAddresses({ nsCompanyId }) {
    if (!nsCompanyId) {
      this.addressOptions = [{ label: "Select", value: "" }];
      return;
    }

    try {
      const addresses = await getCustomerAddresses({ nsCompanyId });

      this.processPicklistWire({ data: addresses || [] }, "addressOptions");

      // this.addressOptions = options;

      // if (!skipSelection) {
      //   this._addressSection?.applyDefaults(defaultShipping, defaultBilling);
      // }
    } catch (error) {
      this.addressOptions = [{ label: "Select", value: "" }];
      console.error("Error fetching addressOptions:", error);
    }
  }
}
