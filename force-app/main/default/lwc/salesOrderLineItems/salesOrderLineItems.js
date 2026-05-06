import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import LightningAlert from "lightning/alert";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import searchSellableItem from "@salesforce/apex/FilterDataController.searchSellableItem";
import searchSepcialOrderItem from "@salesforce/apex/FilterDataController.searchSepcialOrderItem";
import searchItem from "@salesforce/apex/FilterDataController.searchItem";
import searchVendorNum from "@salesforce/apex/FilterDataController.searchVendorNum";
import getValue from "@salesforce/apex/DataService.getValue";
import checkOnHand from "@salesforce/apex/DataService.checkOnHand";
import BASE_PRICE from "@salesforce/schema/breadwinner_ns__BW_Item__c.Base_Price__c";
import IMAGE_ID from "@salesforce/schema/breadwinner_ns__BW_Item__c.imageId__c";

const BASE_ROW = Object.freeze({
  item: "",
  itemName: "",
  specialOrderItem: "",
  specialOrderVendorNum: "",
  imageUrl: "",
  quantity: "",
  rate: "",
  amount: "",
  line: "",
  isDiscount: false
});

export default class SalesOrderLineItems extends LightningElement {
  @api location;
  @api disabled = false;
  @api orderType;

  rows = [];
  nextRowId = 1;
  selectedItemId;
  selectedItemRowIndex = null;
  pendingItemNames = null;

  constructor() {
    super();
    this.reset();
  }

  get isSalesOrder() {
    return this.orderType === "sales";
  }

  get isSpecialOrder() {
    return this.orderType === "special";
  }

  get isRepairOrder() {
    return this.orderType === "repair";
  }

  createRow({
    id,
    showAction = false,
    disableRemove = false,
    overrides = {}
  } = {}) {
    const rowId = id ?? this.nextRowId++;
    const row = {
      id: rowId,
      actionKey: `action-${rowId}`,
      ...BASE_ROW,
      showAction,
      disableRemove
    };

    return {
      ...row,
      ...overrides
    };
  }

  @api
  getRows() {
    return [...this.rows];
  }

  @api
  loadRows(rows, itemNames) {
    this.rows = (rows || []).map((row, index) => {
      const rowId = row.id || index + 1;

      return this.createRow({
        id: rowId,
        showAction: index === 0,
        disableRemove: index === 0,
        overrides: {
          ...row,
          actionKey: row.actionKey || `action-${rowId}`
        }
      });
    });

    this.nextRowId = this.rows.length + 1;
    this.pendingItemNames = itemNames;
  }

  @api
  reset() {
    this.nextRowId = 1;
    this.rows = [this.createRow({ showAction: true, disableRemove: true })];
    this.selectedItemId = null;
    this.selectedItemRowIndex = null;

    this.clearItemLookups();
    this.pendingItemNames = [""];
  }

  @api
  getMappedRows(rows) {
    const mappedRows = (rows || []).map((line, index) => {
      const rowId = index + 1;
      const qty = line.quantity || "";
      const rate = line.rate || "";
      const amount = line.amount || "";
      const itemName = line.itemName || "";
      const isDiscount = itemName === "Store Discount";
      const lineNum = line.line || "";

      return this.createRow({
        id: rowId,
        showAction: index === 0,
        disableRemove: index === 0,
        overrides: {
          item: line.item || "",
          itemName,
          specialOrderItem: line.specialOrderItem || "",
          specialOrderVendorNum: line.specialOrderVendorNum || "",
          imageUrl: line.imageUrl || "",
          quantity: isDiscount ? "" : qty,
          rate,
          amount,
          line: lineNum,
          isDiscount
        }
      });
    });

    return mappedRows;
  }

  @api
  setSpecialItem({ itemId, itemName }) {
    this.reset();

    const newRow = this.createRow({
      overrides: {
        item: itemId,
        itemName,
        quantity: 1,
        showAction: false,
        disableRemove: false
      }
    });

    this.rows = [newRow];

    this.pendingItemNames = [itemName];
  }

  renderedCallback() {
    if (!this.pendingItemNames) return;

    const itemLookups = this.template.querySelectorAll(
      'c-lookup-input[data-type="item"]'
    );

    if (itemLookups.length < this.pendingItemNames.length) return;

    itemLookups.forEach((lookup, index) => {
      lookup.setSelected(this.pendingItemNames[index] || "");
    });

    this.pendingItemNames = null;
  }

  @wire(getRecord, {
    recordId: "$selectedItemId",
    fields: [BASE_PRICE, IMAGE_ID]
  })
  wiredItemRecord({ data, error }) {
    if (data && this.selectedItemRowIndex !== null) {
      const row = this.rows[this.selectedItemRowIndex];

      if (row?.isDiscount) return;

      const basePrice = getFieldValue(data, BASE_PRICE);
      const imageId = getFieldValue(data, IMAGE_ID);
      const imageUrl = imageId
        ? "/sfc/servlet.shepherd/document/download/" + imageId
        : "";

      const updatedRows = [...this.rows];

      if (updatedRows[this.selectedItemRowIndex]) {
        updatedRows[this.selectedItemRowIndex].imageUrl = imageUrl;
        updatedRows[this.selectedItemRowIndex].quantity = 1;
        updatedRows[this.selectedItemRowIndex].rate = basePrice ?? "";
        updatedRows[this.selectedItemRowIndex].amount = basePrice ?? "";
        this.rows = updatedRows;
      }
    } else if (error) {
      console.error("Error fetching item base price", error);
    }
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;
    const index = Number(e.target.dataset.index);

    if (searchKey.length > 1) {
      input.setLoading(true);

      const searchFn =
        type === "item"
          ? this.isSpecialOrder
            ? searchSepcialOrderItem
            : searchSellableItem
          : type === "specialOrderItem"
            ? searchItem
            : type === "specialOrderVendorNum"
              ? searchVendorNum
              : null;

      if (!searchFn) {
        input.setResults([]);
        return;
      }

      try {
        const results = await searchFn({ input: searchKey });

        input.setResults(results);
      } catch (err) {
        console.error(err.name);
        console.error(err.message);
        console.error(err.stack);
        input.setResults([]);
      } finally {
        input.setLoading(false);
      }
    } else {
      input.setResults([]);
      this.resetItemRow(index);
    }
  }

  async handleLookupSelect(e) {
    const type = e.target.dataset.type;

    try {
      if (type === "item") {
        await this.handleItemSelect(e);
      } else if (type === "specialOrderItem") {
        await this.handleSpecialOrderItemSelect(e);
      } else if (type === "specialOrderVendorNum") {
        await this.handleSpecialOrderVendorNumSelect(e);
      }
    } catch (err) {
      console.error(err.name);
      console.error(err.message);
      console.error(err.stack);
    }
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
        this.resetItemRow(index);
        await LightningAlert.open({
          label: "Error!",
          message:
            "Store Discount cannot appear as the first line; it must be applied to the item directly above it",
          theme: "error"
        });
        return;
      }

      if (this.rows[index - 1]?.isDiscount) {
        this.resetItemRow(index);
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
      updatedRows[index].imageUrl = "";

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

  async handleSpecialOrderItemSelect(e) {
    const selectedId = e.detail.id;
    const index = Number(e.target.dataset.index);

    const results = await getValue({
      recordName: "breadwinner_ns__BW_Item__c",
      fieldNames: ["breadwinner_ns__VendorName__c", "Base_Price__c"],
      recordId: selectedId
    });

    const vendorNum = results.breadwinner_ns__VendorName__c;
    const basePrice = results.Base_Price__c;
    const updates = {};

    if (this.hasValue(vendorNum)) {
      this.setLookupValue(index, "specialOrderVendorNum", vendorNum);
      updates.specialOrderVendorNum = vendorNum;
    }

    if (this.hasValue(basePrice)) {
      updates.rate = basePrice;
      updates.amount = basePrice;
    }

    this.updateRowFields(index, updates);
  }

  async handleSpecialOrderVendorNumSelect(e) {
    const selectedId = e.detail.id;
    const index = Number(e.target.dataset.index);

    const results = await getValue({
      recordName: "breadwinner_ns__BW_Item__c",
      fieldNames: ["Name", "Base_Price__c"],
      recordId: selectedId
    });

    const name = results.Name;
    const basePrice = results.Base_Price__c;
    const updates = {};

    if (this.hasValue(name)) {
      this.setLookupValue(index, "specialOrderItem", name);
      updates.specialOrderItem = name;
    }

    if (this.hasValue(basePrice)) {
      updates.rate = basePrice;
      updates.amount = basePrice;
    }

    this.updateRowFields(index, updates);
  }

  async handleRowChange(e) {
    const index = Number(e.target.dataset.index);
    const field = e.target.dataset.field;
    const value = e.target.value;
    const updatedRows = [...this.rows];
    const row = updatedRows[index];

    if (field === "quantity") {
      if (!row.isDiscount) {
        const itemIsAvailable = await checkOnHand({
          itemName: row.itemName,
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
      const newRow = this.createRow();

      const updatedRows = [...this.rows];
      updatedRows.splice(index + 1, 0, newRow);
      this.rows = updatedRows;
    } catch (error) {
      console.error(`Error adding row at index ${index}`, error);
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
    this.rows = this.rows.map((row, idx) => ({
      ...row,
      showAction: idx === index
    }));
  }

  clearItemLookups() {
    const itemLookups = this.template.querySelectorAll(
      'c-lookup-input[data-type="item"]'
    );

    itemLookups.forEach((lookup) => {
      lookup.setSelected("");
      lookup.setResults([]);
    });
  }

  clearItemRow(index) {
    const updatedRows = [...this.rows];

    if (updatedRows[index]) {
      updatedRows[index] = {
        ...updatedRows[index],
        item: "",
        itemName: "",
        specialOrderItem: "",
        specialOrderVendorNum: "",
        imageUrl: "",
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

  resetItemRow(index) {
    this.clearItemRow(index);

    const lookupInputs = this.template.querySelectorAll(
      `c-lookup-input[data-index="${index}"]`
    );

    lookupInputs.forEach((lookup) => lookup.setSelected(""));
  }

  hasValue(value) {
    return value !== null && value !== undefined && value !== "";
  }

  setLookupValue(index, lookupType, value) {
    if (!this.hasValue(value)) return;

    const lookupInput = this.template.querySelector(
      `c-lookup-input[data-type="${lookupType}"][data-index="${index}"]`
    );

    if (lookupInput?.setSelected) {
      lookupInput.setSelected(String(value));
    }
  }

  updateRowFields(index, updates) {
    if (!updates || Object.keys(updates).length === 0) return;

    const updatedRows = [...this.rows];
    if (updatedRows[index]) {
      updatedRows[index] = {
        ...updatedRows[index],
        ...updates
      };
      this.rows = updatedRows;
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
}
