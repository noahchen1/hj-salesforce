import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import getSubsidiaries from "@salesforce/apex/DropdownDataController.getSubsidiaries";
import searchSellableItem from "@salesforce/apex/FilterDataController.searchSellableItem";
import BASE_PRICE from "@salesforce/schema/breadwinner_ns__BW_Item__c.Base_Price__c";
import USER_ID from "@salesforce/user/Id";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import saveSalesOrder from "@salesforce/apex/SalesOrderController.saveSalesOrder";
import getOrderData from "@salesforce/apex/SalesOrderController.getOrderData";
import getOrder from "@salesforce/apex/SalesOrderController.getOrder";

import getSubsidiaryLocations from "@salesforce/apex/DropdownDataController.getSubsidiaryLocations";
import checkOnHand from "@salesforce/apex/DataService.checkOnHand";
import LightningAlert from "lightning/alert";
import getEmployeeData from "@salesforce/apex/DataService.getEmployeeData";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import SHIPPING_CONTACT from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingAddressee__c";
import SHIPPING_ADDR1 from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingAddr1__c";
import SHIPPING_ADDR2 from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingAddr2__c";
import SHIPPING_CITY from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingCity__c";
import SHIPPING_STATE from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingState__c";
import SHIPPING_ZIP from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingZip__c";
import SHIPPING_COUNTRY from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__ShippingCountry__c";
import BILLING_CONTACT from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingAddressee__c";
import BILLING_ADDR1 from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingAddr1__c";
import BILLING_ADDR2 from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingAddr2__c";
import BILLING_CITY from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingCity__c";
import BILLING_STATE from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingState__c";
import BILLING_ZIP from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingZip__c";
import BILLING_COUNTRY from "@salesforce/schema/breadwinner_ns__BW_Company__c.breadwinner_ns__BillingCountry__c";
import COMPANY_NAME from "@salesforce/schema/breadwinner_ns__BW_Company__c.Name";
import getObjectName from "@salesforce/apex/SalesOrderController.getObjectName";
import getNsCompanyFromAccount from "@salesforce/apex/SalesOrderController.getNsCompanyFromAccount";
import { formatAddress } from "c/utils";

export default class SalesOrderForm extends NavigationMixin(LightningElement) {
  @api recordId;
  internalId;
  customer = "";
  selectedCustomerId;
  shippingAddress = "";
  billingAddress = "";
  date = new Date().toISOString();
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  memo = "";
  isLoading = false;
  locationOptions = [];
  subsidiary = "";
  subsidiaryOptions = [];
  rows = [
    {
      id: 1,
      item: "",
      itemName: "",
      quantity: "",
      rate: "",
      amount: "",
      line: "",
      isDiscount: false,
      showAction: true,
      disableRemove: true
    }
  ];
  nextRowId = 2;
  selectedItemId;
  selectedItemRowIndex = null;
  pendingLookupValues;

  async connectedCallback() {
    // const btn = window.document.querySelector(
    //   'button[title="Cancel and close"]'
    // );

    // if (btn) {
    //   console.log(btn);

    //   console.log((btn.style.display = "none"));
    // }

    try {
      const [subsidiaries, emp] = await Promise.all([
        getSubsidiaries(),
        getEmployeeData({ userId: USER_ID })
      ]);

      this.processPicklistWire({ data: subsidiaries }, "subsidiaryOptions");

      this.subsidiary = emp.subsidiaryId || "";
      this.location = emp.locationId || "";
      this.salesRep1 = emp.employeeId || "";

      if (emp.employeeId && emp.employeeName) {
        const lookup = this.template.querySelector(
          'c-lookup-input[data-type="salesRep1"]'
        );
        lookup?.setSelected(emp.employeeName);
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

  renderedCallback() {
    this.applyPendingLookupValues();
  }

  // @wire(CurrentPageReference)
  // getStateParameters(pageRef) {
  //   if (pageRef) {
  //     this.recordId = pageRef.state?.c__recordId;
  //     if (this.recordId) this.loadOrder();
  //   }
  // }

  @wire(getSubsidiaryLocations, { subsidiary: "$subsidiary" })
  handleLocations(results) {
    this.processPicklistWire(results, "locationOptions");
  }

  @wire(getObjectName, { recordId: "$recordId" })
  handleObjName({ data, error }) {
    if (data) {
      const isAccount = data === "Account";

      if (isAccount) {
        this.isLoading = true;
        this.fetchNsCompanyId(this.recordId);
      } else {
        this.loadOrder();
      }
    } else if (error) {
      console.error("Error fetching record type", error);
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

  @wire(getRecord, {
    recordId: "$selectedItemId",
    fields: [BASE_PRICE]
  })
  wiredItemRecord({ data, error }) {
    if (data && this.selectedItemRowIndex !== null) {
      const row = this.rows[this.selectedItemRowIndex];

      if (row?.isDiscount) return;

      const basePrice = getFieldValue(data, BASE_PRICE);
      const updatedRows = [...this.rows];

      if (updatedRows[this.selectedItemRowIndex]) {
        updatedRows[this.selectedItemRowIndex].quantity = 1;
        updatedRows[this.selectedItemRowIndex].rate = basePrice ?? "";
        updatedRows[this.selectedItemRowIndex].amount = basePrice ?? "";
        this.rows = updatedRows;
      }
    } else if (error) {
      console.error("Error fetching item base price", error);
    }
  }

  @wire(getRecord, {
    recordId: "$selectedCustomerId",
    fields: [
      SHIPPING_CONTACT,
      SHIPPING_ADDR1,
      SHIPPING_ADDR2,
      SHIPPING_CITY,
      SHIPPING_COUNTRY,
      SHIPPING_STATE,
      SHIPPING_ZIP,
      BILLING_CONTACT,
      BILLING_ADDR1,
      BILLING_ADDR2,
      BILLING_CITY,
      BILLING_COUNTRY,
      BILLING_STATE,
      BILLING_ZIP,
      COMPANY_NAME
    ]
  })
  wiredCustomerData({ data, error }) {
    if (data && this.selectedCustomerId != null) {
      const companyName = getFieldValue(data, COMPANY_NAME);
      if (companyName) {
        const customerLookup = this.template.querySelector(
          'c-lookup-input[data-type="customer"]'
        );
        customerLookup?.setSelected(companyName);
      }

      const shippingContact = getFieldValue(data, SHIPPING_CONTACT);
      const shippingAddress1 = getFieldValue(data, SHIPPING_ADDR1);
      const shippingAddress2 = getFieldValue(data, SHIPPING_ADDR2);
      const shippingCity = getFieldValue(data, SHIPPING_CITY);
      const shippingState = getFieldValue(data, SHIPPING_STATE);
      const shippingZip = getFieldValue(data, SHIPPING_ZIP);
      const shippingCountry = getFieldValue(data, SHIPPING_COUNTRY);
      const billingContact = getFieldValue(data, BILLING_CONTACT);
      const billingAddress1 = getFieldValue(data, BILLING_ADDR1);
      const billingAddress2 = getFieldValue(data, BILLING_ADDR2);
      const billingCity = getFieldValue(data, BILLING_CITY);
      const billingState = getFieldValue(data, BILLING_STATE);
      const billingZip = getFieldValue(data, BILLING_ZIP);
      const billingCountry = getFieldValue(data, BILLING_COUNTRY);

      this.shippingAddress = formatAddress({
        contact: shippingContact,
        addr1: shippingAddress1,
        addr2: shippingAddress2,
        city: shippingCity,
        state: shippingState,
        zip: shippingZip,
        country: shippingCountry
      });

      this.billingAddress = formatAddress({
        contact: billingContact,
        addr1: billingAddress1,
        addr2: billingAddress2,
        city: billingCity,
        state: billingState,
        zip: billingZip,
        country: billingCountry
      });
    } else if (error) {
      this.shippingAddress = "";
      this.billingAddress = "";

      console.error("Error fetching customer shipping address", error);
    } else {
      this.shippingAddress = "";
      this.billingAddress = "";
    }
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

  get isLocationDisabled() {
    return !this.subsidiary;
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;

    let searchFn;

    if (type === "salesRep1" || type === "salesRep2") {
      searchFn = searchSalesRep;
    } else if (type === "customer") {
      searchFn = searchCustomer;
    } else if (type === "item") {
      searchFn = searchSellableItem;
    }

    if (searchKey.length > 1 && searchFn) {
      input.setLoading(true);

      try {
        const results = await searchFn({ input: searchKey });

        input.setResults(results);
      } catch (error) {
        console.error(error);
        input.setResults([]);
      } finally {
        input.setLoading(false);
      }
    } else {
      input.setResults([]);

      if (type === "item") {
        const index = Number(e.target.dataset.index);
        this.clearItemRow(index);
        return;
      }

      this[type] = "";
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;

    try {
      if (type === "item") return this.handleItemSelect(e);
      if (type === "customer") return this.handleCustomerSelect(e);
      if (type === "salesRep1" || type === "salesRep2") {
        return this.handleSalesRepSelect(e);
      }
    } catch (err) {
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);
    }
  }

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    if (name === "subsidiary" && this.subsidiary !== value) {
      this.location = "";
    }

    this[name] = e.target.value;
  }

  processPicklistWire({ data, error }, target) {
    if (data) {
      this[target] = [
        { label: "Select", value: "" },
        ...data.map(({ label, value }) => ({ label, value }))
      ];
    } else if (error) {
      console.error(`Error fetching ${target}: `, error);
    }
  }

  async handleRowChange(e) {
    const index = Number(e.target.dataset.index);
    const field = e.target.dataset.field;
    const value = e.target.value;
    const updatedRows = [...this.rows];
    const row = updatedRows[index];

    if (field === "quantity") {
      const itemName = row.itemName;

      if (!row.isDiscount) {
        const itemIsAvailable = await checkOnHand({
          itemName: itemName,
          nsLocationId: this.location,
          qtyRequested: value
        });

        if (!itemIsAvailable) {
          await LightningAlert.open({
            label: "Warning!",
            message: "This item is not available at the selected location",
            theme: "warning"
          });
        }
      }
    }

    if (field === "rate" && row.isDiscount) {
      const trimmed = `${value ?? ""}`.trim();
      const isPercent = trimmed.endsWith("%");
      const numericValue = parseFloat(trimmed.replace("%", ""));

      if (!isNaN(numericValue) && numericValue > 0) {
        const negated = isPercent ? `-${numericValue}%` : `${-numericValue}`;
        row.rate = negated;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Warning",
            message: "Discount rate must be negative. Value has been negated.",
            variant: "warning"
          })
        );
      } else {
        row.rate = value;
      }
    } else {
      row[field] = value;
    }

    if (row.isDiscount) {
      row.amount = this.calcDiscountAmount(index, updatedRows);
    } else {
      const qty = parseFloat(row.quantity) || 0;
      const rate = parseFloat(row.rate) || 0;
      row.amount = qty * rate || "";

      if (updatedRows[index + 1]?.isDiscount) {
        updatedRows[index + 1].amount = this.calcDiscountAmount(
          index + 1,
          updatedRows
        );
      }
    }

    this.rows = updatedRows;
  }

  addRow(e) {
    const index = Number(e.target.dataset.index);

    try {
      const newRow = {
        id: this.nextRowId++,
        item: "",
        itemName: "",
        quantity: "",
        rate: "",
        amount: "",
        line: "",
        isDiscount: false,
        showAction: false,
        disableRemove: false
      };

      const updatedRows = [...this.rows];
      updatedRows.splice(index + 1, 0, newRow);

      this.rows = updatedRows;
    } catch (error) {
      console.error(
        `Error occured when changing values for line item ${index}`
      );
      console.error(error);
    }
  }

  removeRow(e) {
    const index = Number(e.target.dataset.index);

    const updatedRows = [...this.rows];
    updatedRows.splice(index, 1);

    this.rows = updatedRows;
  }

  handleFocus(e) {
    const index = Number(e.target.dataset.index);
    const updatedRows = [...this.rows];

    updatedRows.forEach((row, idx) => {
      if (idx === index) {
        row.showAction = true;
      } else {
        row.showAction = false;
      }
    });

    this.rows = updatedRows;
  }

  handleInputChange(e) {
    const type = e.target.dataset.type;

    this[type] = e.target.value;
  }

  async handleItemSelect(e) {
    const selectedName = e.detail.name;
    const selectedId = e.detail.id;
    const selectedNsId = e.detail.nsId;
    const index = Number(e.target.dataset.index);
    const input = e.target;
    const isDiscount = selectedName === "Store Discount";

    if (isDiscount) {
      if (index === 0) {
        this.resetItemRow(index, input);
        await LightningAlert.open({
          label: "Error!",
          message:
            "Store Discount cannot appear as the first line; it must be applied to the item directly above it",
          theme: "error"
        });
        return;
      }

      if (this.rows[index - 1]?.isDiscount) {
        this.resetItemRow(index, input);
        await LightningAlert.open({
          label: "Error!",
          message: "Each item can only be followed by one Store Discount.",
          theme: "error"
        });
        return;
      }
    }

    if (!isDiscount) {
      const itemIsAvailable = await checkOnHand({
        itemName: selectedName,
        nsLocationId: this.location,
        qtyRequested: 1
      });

      if (!itemIsAvailable) {
        await LightningAlert.open({
          label: "Warning!",
          message: "This item is not available at the selected location",
          theme: "warning"
        });
      }
    }

    const updatedRows = [...this.rows];
    if (updatedRows[index]) {
      updatedRows[index].item = selectedNsId;
      updatedRows[index].itemName = selectedName;
      updatedRows[index].isDiscount = isDiscount;

      if (isDiscount) {
        updatedRows[index].quantity = "";
        updatedRows[index].rate = "";
        updatedRows[index].amount = "";
      }
    }
    this.rows = updatedRows;

    if (!isDiscount) {
      this.selectedItemRowIndex = index;
      this.selectedItemId = selectedId;
    }
  }

  handleCustomerSelect(e) {
    const selectedId = e.detail.id;
    const selectedNsId = e.detail.nsId;

    this.selectedCustomerId = selectedId;
    this.customer = selectedNsId;
  }

  handleSalesRepSelect(e) {
    const type = e.target.dataset.type;
    const selectedNsId = e.detail.nsId;

    this[type] = selectedNsId;
  }

  async saveOrder() {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    const isUpdate = Boolean(this.internalId);

    try {
      const payload = {
        internalId: this.internalId,
        customer: this.customer,
        orderDate: this.date,
        salesRep1: this.salesRep1,
        salesRep2: this.salesRep2,
        subsidiary: this.subsidiary,
        location: this.location,
        memo: this.memo,
        lineItemsJson: JSON.stringify(this.rows)
      };

      console.log("saveSalesOrder payload:", payload);
      console.log(
        "saveSalesOrder payload (pretty):",
        JSON.stringify(
          {
            ...payload,
            lineItemsJson: JSON.parse(payload.lineItemsJson)
          },
          null,
          2
        )
      );

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
          attributes: {
            recordId,
            actionName: "view"
          }
        });
      }
    } catch (err) {
      console.error("createSo failed", err);

      LightningAlert.open({
        label: "Error!",
        message: `Order was not saved, cause: ${err?.body?.message}`,
        theme: "error"
      });
    } finally {
      this.isLoading = false;
    }
  }

  clearItemRow(index) {
    const updatedRows = [...this.rows];

    if (updatedRows[index]) {
      updatedRows[index] = {
        ...updatedRows[index],
        item: "",
        itemName: "",
        quantity: "",
        rate: "",
        amount: "",
        isDiscount: false
      };

      this.rows = updatedRows;
    }

    if (this.selectedItemRowIndex === index) {
      this.selectedItemRowIndex = null;
      this.selectedItemId = null;
    }
  }

  resetItemRow(index, input) {
    this.clearItemRow(index);

    if (input?.setSelected) {
      input.setSelected("");
    }
  }

  calcDiscountAmount(index, rows) {
    const discountRow = rows[index];
    const prevRow = rows[index - 1];

    if (!prevRow) return "";

    const input = `${discountRow.rate ?? ""}`.trim();
    const prevAmount = parseFloat(prevRow.amount) || 0;

    if (!input) return "";

    const isPercent = input.endsWith("%");
    const numericValue = parseFloat(input.replace("%", ""));

    if (isNaN(numericValue)) return "";

    if (isPercent) {
      return prevAmount * (numericValue / 100) || "";
    }

    return numericValue || "";
  }

  async loadOrder() {
    this.isLoading = true;

    try {
      const data = await getOrderData({
        salesOrderId: this.recordId
      });

      this.internalId = data.internalId || this.internalId;
      this.selectedCustomerId = data.customerId || null;
      this.customer = data.customerNsId || "";
      this.date = data.orderDate || this.date;
      this.salesRep1 = data.salesRep1NsId || "";
      this.salesRep2 = data.salesRep2NsId || "";
      this.memo = data.memo || "";
      this.subsidiary = data.subsidiaryNsId || "";
      this.location = data.locationNsId || "";

      this.billingAddress = formatAddress({
        contact: data.billingAddress?.addressee,
        addr1: data.billingAddress?.addr1,
        addr2: data.billingAddress?.addr2,
        city: data.billingAddress?.city,
        state: data.billingAddress?.state,
        zip: data.billingAddress?.zip,
        country: data.billingAddress?.country
      });

      this.shippingAddress = formatAddress({
        contact: data.shippingAddress?.addressee,
        addr1: data.shippingAddress?.addr1,
        addr2: data.shippingAddress?.addr2,
        city: data.shippingAddress?.city,
        state: data.shippingAddress?.state,
        zip: data.shippingAddress?.zip,
        country: data.shippingAddress?.country
      });

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

      if (mappedRows.length > 0) {
        this.rows = mappedRows;
        this.nextRowId = mappedRows.length + 1;
      }

      this.pendingLookupValues = {
        customer: data.customerName || "",
        salesRep1: data.salesRep1Name || "",
        salesRep2: data.salesRep2Name || "",
        items: mappedRows.map((row) => row.itemName || "")
      };

      this.applyPendingLookupValues();
    } catch (error) {
      console.error("Failed to preload existing sales order", error);
    } finally {
      this.isLoading = false;
    }
  }

  applyPendingLookupValues() {
    if (!this.pendingLookupValues) {
      return;
    }

    const customerLookup = this.template.querySelector(
      'c-lookup-input[data-type="customer"]'
    );
    customerLookup?.setSelected(this.pendingLookupValues.customer);

    const rep1Lookup = this.template.querySelector(
      'c-lookup-input[data-type="salesRep1"]'
    );
    rep1Lookup?.setSelected(this.pendingLookupValues.salesRep1);

    const rep2Lookup = this.template.querySelector(
      'c-lookup-input[data-type="salesRep2"]'
    );
    rep2Lookup?.setSelected(this.pendingLookupValues.salesRep2);

    const itemLookups = this.template.querySelectorAll(
      'c-lookup-input[data-type="item"]'
    );

    if (itemLookups.length < this.pendingLookupValues.items.length) {
      return;
    }

    itemLookups.forEach((lookup, index) => {
      lookup.setSelected(this.pendingLookupValues.items[index] || "");
    });

    this.pendingLookupValues = null;
  }

  resetForm() {
    this.internalId = null;
    this.customer = "";
    this.selectedCustomerId = null;
    this.shippingAddress = "";
    this.billingAddress = "";
    this.date = new Date().toISOString();
    this.salesRep1 = "";
    this.salesRep2 = "";
    this.memo = "";
    this.subsidiary = "";
    this.location = "";
    this.rows = [
      {
        id: 1,
        item: "",
        itemName: "",
        quantity: "",
        rate: "",
        amount: "",
        line: "",
        isDiscount: false,
        showAction: true,
        disableRemove: true
      }
    ];
    this.nextRowId = 2;
    this.selectedItemRowIndex = null;
    this.selectedItemId = null;
    this.pendingLookupValues = null;
  }
}
