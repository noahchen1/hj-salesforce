import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import LightningAlert from "lightning/alert";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import searchSellableItem from "@salesforce/apex/FilterDataController.searchSellableItem";
import searchSepcialOrderItem from "@salesforce/apex/FilterDataController.searchSepcialOrderItem";
import searchParentItem from "@salesforce/apex/FilterDataController.searchParentItem";
import searchVendorNum from "@salesforce/apex/FilterDataController.searchVendorNum";
import getValue from "@salesforce/apex/DataService.getValue";
import checkOnHand from "@salesforce/apex/DataService.checkOnHand";
import getItemQuantities from "@salesforce/apex/DataService.getItemQuantities";
import BASE_PRICE from "@salesforce/schema/breadwinner_ns__BW_Item__c.Base_Price__c";
import IMAGE_ID from "@salesforce/schema/breadwinner_ns__BW_Item__c.imageId__c";
import DISPLAY_NAME from "@salesforce/schema/breadwinner_ns__BW_Item__c.breadwinner_ns__DisplayName__c";
import ITEM_TYPE from "@salesforce/schema/breadwinner_ns__BW_Item__c.breadwinner_ns__Item_Type__c";
import { SELLABLE_SPECIAL_ALLOWED_STATUSES } from "c/salesOrderUtils";

const BASE_ROW = Object.freeze({
  item: null,
  itemName: null,
  displayName: null,
  quantityAvailable: null,
  quantityBackordered: null,
  specialOrderItem: null,
  specialOrderVendorNum: null,
  imageUrl: null,
  quantity: null,
  rate: null,
  amount: null,
  quotedPrice: null,
  line: null,
  isDiscount: false,
  isRepairNeeded: "",
  itemType: null
});

export default class SalesOrderLineItems extends LightningElement {
  @api location;
  @api disabled = false;
  @api orderType;
  @api specialOrderStatus;

  rows = [];
  nextRowId = 0;
  selectedItemId;
  selectedItemRowIndex = null;
  pendingLookupSelections = null;

  constructor() {
    super();
    this.reset();
  }

  emitLineItemsChange() {
    this.dispatchEvent(
      new CustomEvent("lineitemschange", {
        detail: {
          rows: this.getRows()
        }
      })
    );
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

  get isSellableAllowed() {
    return SELLABLE_SPECIAL_ALLOWED_STATUSES.has(this.specialOrderStatus);
  }

  get hasRows() {
    return this.rows.length > 0;
  }

  get activeRowIndex() {
    const activeIndex = this.rows.findIndex((row) => row.showAction);
    return activeIndex === -1 ? 0 : activeIndex;
  }

  get isActiveRowRemoveDisabled() {
    return this.rows.length <= 1 || this.activeRowIndex === 0;
  }

  get isRepairNeededOptions() {
    return [
      { label: "Optional", value: "1" },
      { label: "Required", value: "2" }
    ];
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

  setRows(rows) {
    const sourceRows = rows || [];

    this.rows = sourceRows.map((row, index) => {
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

    this.pendingLookupSelections = {
      item: this.rows.map((row) => row.itemName || "")
    };

    const hasSpecialRowData = sourceRows.some(
      (row) =>
        row &&
        ((row.specialOrderItem ?? "") !== "" ||
          (row.specialOrderVendorNum ?? "") !== "")
    );

    if (this.isSpecialOrder || hasSpecialRowData) {
      this.pendingLookupSelections.specialOrderItem = this.rows.map(
        (row) => row.specialOrderItem || ""
      );
      this.pendingLookupSelections.specialOrderVendorNum = this.rows.map(
        (row) => row.specialOrderVendorNum || ""
      );
    }
  }

  @api
  loadRows(rows) {
    this.setRows(rows);

    this.emitLineItemsChange();
  }

  @api
  reset() {
    this.rows = [
      this.createRow({ id: 1, showAction: true, disableRemove: true })
    ];
    this.nextRowId = 2;
    this.selectedItemId = null;
    this.selectedItemRowIndex = null;

    this.clearItemLookups();
    this.pendingLookupSelections = {
      item: [""]
    };
    this.emitLineItemsChange();
  }

  @api
  getMappedRows(rows) {
    const mappedRows = (rows || []).map((line, index) => {
      const rowId = index + 1;
      const qty = line.quantity ?? "";
      const rate = line.rate ?? "";
      const amount = line.amount ?? "";
      const quotedPrice = line.quotedPrice ?? "";
      const displayName = line.displayName ?? "";
      const quantityAvailable = line.quantityAvailable ?? "";
      const quantityBackordered = line.quantityBackOrdered ?? "";
      const itemName = line.itemName ?? "";
      const isDiscount = itemName === "Store Discount";
      const lineNum = line.line ?? "";
      const isRepairNeeded = line.isRepairNeeded ?? "";

      return this.createRow({
        id: rowId,
        showAction: index === 0,
        disableRemove: index === 0,
        overrides: {
          item: line.item ?? "",
          itemName,
          displayName,
          quantityAvailable,
          quantityBackordered,
          specialOrderItem: line.specialOrderItem ?? "",
          specialOrderVendorNum: line.specialOrderVendorNum ?? "",
          imageUrl: line.imageUrl ?? "",
          itemType: line.itemType ?? "",
          quantity: isDiscount ? "" : qty,
          rate,
          amount,
          quotedPrice,
          line: lineNum,
          isRepairNeeded,
          isDiscount
        }
      });
    });

    return mappedRows;
  }

  @api
  setItems(items) {
    if (items.length === 0) return;

    this.rows = items.map(({ itemId, itemName, displayName, amount }, index) =>
      this.createRow({
        id: index + 1,
        showAction: index === 0,
        disableRemove: index === 0,
        overrides: {
          item: itemId ?? "",
          itemName: itemName ?? "",
          displayName: displayName ?? "",
          quantity: 1,
          rate: amount ?? "",
          amount: amount ?? ""
        }
      })
    );

    this.nextRowId = this.rows.length + 1;
    this.selectedItemId = null;
    this.selectedItemRowIndex = null;

    this.pendingLookupSelections = {
      item: this.rows.map((row) => row.itemName || "")
    };

    if (this.isSpecialOrder) {
      this.pendingLookupSelections.specialOrderItem = this.rows.map(() => "");
      this.pendingLookupSelections.specialOrderVendorNum = this.rows.map(
        () => ""
      );
    }

    this.emitLineItemsChange();
  }

  @api
  validateFields() {
    const inputs = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("lightning-combobox"),
      ...this.template.querySelectorAll("c-lookup-input")
    ];

    let isValid = true;

    inputs.forEach((field) => {
      const fieldIsValid = field.reportValidity();

      if (!fieldIsValid) {
        isValid = false;
      }
    });

    return isValid;
  }

  renderedCallback() {
    if (!this.pendingLookupSelections) return;

    const lookupTypes = Object.keys(this.pendingLookupSelections);

    for (const lookupType of lookupTypes) {
      const values = this.pendingLookupSelections[lookupType] || [];

      for (let index = 0; index < values.length; index += 1) {
        const lookup = this.template.querySelector(
          `c-lookup-input[data-type="${lookupType}"][data-index="${index}"]`
        );

        if (!lookup) {
          const isSpecialLookup =
            lookupType === "specialOrderItem" ||
            lookupType === "specialOrderVendorNum";

          if (isSpecialLookup && this.rows[index]?.isDiscount) {
            continue;
          }

          return;
        }

        lookup.setSelected(values[index] || "");
      }
    }

    this.pendingLookupSelections = null;
  }

  @wire(getRecord, {
    recordId: "$selectedItemId",
    fields: [BASE_PRICE, IMAGE_ID, DISPLAY_NAME, ITEM_TYPE]
  })
  async wiredItemRecord({ data, error }) {
    if (data && this.selectedItemRowIndex !== null) {
      const row = this.rows[this.selectedItemRowIndex];

      if (row?.isDiscount) return;

      const basePrice = getFieldValue(data, BASE_PRICE);
      const imageId = getFieldValue(data, IMAGE_ID);
      const displayName = getFieldValue(data, DISPLAY_NAME);
      const itemType = getFieldValue(data, ITEM_TYPE);
      const imageUrl = imageId
        ? "/sfc/servlet.shepherd/document/download/" + imageId
        : "";

      const updatedRows = [...this.rows];

      if (updatedRows[this.selectedItemRowIndex]) {
        updatedRows[this.selectedItemRowIndex].imageUrl = imageUrl;
        updatedRows[this.selectedItemRowIndex].quantity = 1;
        updatedRows[this.selectedItemRowIndex].rate = basePrice ?? "";
        updatedRows[this.selectedItemRowIndex].amount = basePrice ?? "";
        updatedRows[this.selectedItemRowIndex].displayName = displayName ?? "";
        updatedRows[this.selectedItemRowIndex].itemType = itemType ?? "";

        if (updatedRows[this.selectedItemRowIndex + 1]?.isDiscount) {
          updatedRows[this.selectedItemRowIndex + 1].amount =
            this.calcDiscountAmount(this.selectedItemRowIndex + 1, updatedRows);
        }

        this.rows = updatedRows;
        this.emitLineItemsChange();
      }

      if (
        itemType === "Inventory Item" &&
        (!this.isSpecialOrder || this.isSellableAllowed)
      ) {
        const itemIsAvailable = await checkOnHand({
          itemName: row.itemName,
          nsLocationId: this.location,
          qtyRequested: row.quantity
        });

        if (!itemIsAvailable) {
          await LightningAlert.open({
            label: "Warning!",
            message: "This item is not available at the selected location",
            theme: "warning"
          });
        }
      }
    } else if (error) {
      console.error("Error fetching item base price", error);
    }

    this.selectedItemId = null;
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;

    if (searchKey.length > 1) {
      input.setLoading(true);

      const searchFn =
        type === "item"
          ? this.isSpecialOrder && !this.isSellableAllowed
            ? searchSepcialOrderItem
            : searchSellableItem
          : type === "specialOrderItem"
            ? searchParentItem
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

      // if (type )
      // this.resetItemRow(index);
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

  handleLookupBlur(e) {
    const type = e.target.dataset.type;

    if (type !== "specialOrderItem" && type !== "specialOrderVendorNum") {
      return;
    }

    const index = Number(e.target.dataset.index);
    const target = e.target;
    const value = String(e.detail?.searchKey ?? "").trim();
    const field =
      type === "specialOrderItem"
        ? "specialOrderItem"
        : "specialOrderVendorNum";

    setTimeout(() => {
      this.updateRowFields(index, { [field]: value });

      if (this.pendingLookupSelections && this.pendingLookupSelections[type]) {
        this.pendingLookupSelections[type][index] = value;
      }

      target.setResults([]);
    }, 150);
  }

  async handleItemSelect(e) {
    const selectedName = e.detail.name;
    const selectedId = e.detail.id;
    const selectedNsId = e.detail.nsId;
    const index = Number(e.target.dataset.index);
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

    if (this.isSpecialOrder && index > 0 && !isDiscount) {
      const firstItem = this.rows[0];

      if (
        firstItem &&
        firstItem.item !== selectedNsId &&
        !this.isSellableAllowed
      ) {
        this.resetItemRow(index);
        await LightningAlert.open({
          label: "Error!",
          message: "You can only enter the same special order item!",
          theme: "error"
        });
        return;
      }
    }

    const updatedRows = [...this.rows];

    if (updatedRows[index]) {
      const results = await getItemQuantities({
        itemName: selectedName,
        nsLocationId: this.location
      });

      updatedRows[index].item = selectedNsId;
      updatedRows[index].itemName = selectedName;
      updatedRows[index].isDiscount = isDiscount;
      updatedRows[index].itemType = "";
      updatedRows[index].imageUrl = "";
      updatedRows[index].quantityAvailable = results.quantityAvailable ?? "";
      updatedRows[index].quantityBackordered =
        results.quantityBackOrdered ?? "";

      if (isDiscount) {
        updatedRows[index].quantity = "";
        updatedRows[index].rate = "";
        updatedRows[index].amount = "";
      }
    }

    this.rows = updatedRows;
    this.emitLineItemsChange();

    if (!isDiscount) {
      this.selectedItemRowIndex = index;
      this.selectedItemId = selectedId;
    }
  }

  async handleSpecialOrderItemSelect(e) {
    const selectedName = e.detail.name;
    const selectedId = e.detail.id;
    const index = Number(e.target.dataset.index);

    const results = await getValue({
      recordName: "breadwinner_ns__BW_Item__c",
      fieldNames: ["breadwinner_ns__VendorName__c", "Base_Price__c"],
      recordId: selectedId
    });

    const vendorNum = results.breadwinner_ns__VendorName__c;
    const basePrice = results.Base_Price__c;
    const updates = { specialOrderItem: selectedName };

    if (this.hasValue(vendorNum)) {
      this.setLookupValue(index, "specialOrderVendorNum", vendorNum);
      updates.specialOrderVendorNum = vendorNum;
    }

    if (this.hasValue(basePrice)) {
      updates.quotedPrice = basePrice;
      updates.rate = basePrice;
      updates.amount = basePrice;
    }

    this.updateRowFields(index, updates);
  }

  async handleSpecialOrderVendorNumSelect(e) {
    const selectedName = e.detail.name;
    const selectedId = e.detail.id;
    const index = Number(e.target.dataset.index);

    const results = await getValue({
      recordName: "breadwinner_ns__BW_Item__c",
      fieldNames: ["Name", "Base_Price__c"],
      recordId: selectedId
    });

    const name = results.Name;
    const basePrice = results.Base_Price__c;
    const updates = { specialOrderVendorNum: selectedName };

    if (this.hasValue(name)) {
      this.setLookupValue(index, "specialOrderItem", name);
      updates.specialOrderItem = name;
    }

    if (this.hasValue(basePrice)) {
      updates.quotedPrice = basePrice;
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
    const isInventoryItem = row.itemType === "Inventory Item";

    if (field === "quantity" && isInventoryItem && !this.isSpecialOrder) {
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

    if (field === "quotedPrice") {
      row.quotedPrice = value;
      row.rate = value;
    } else if (field === "rate" && row.isDiscount) {
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
    this.emitLineItemsChange();
  }

  addRow(e) {
    const index = Number(e.target.dataset.index);

    try {
      const newRow = this.createRow();

      const updatedRows = [...this.rows];
      updatedRows.splice(index + 1, 0, newRow);
      updatedRows.forEach((row, idx) => {
        row.showAction = idx === index + 1;
      });
      this.rows = updatedRows;
      this.emitLineItemsChange();
    } catch (error) {
      console.error(`Error adding row at index ${index}`, error);
    }
  }

  removeRow(e) {
    const index = Number(e.target.dataset.index);
    const updatedRows = [...this.rows];
    const removeCount = updatedRows[index + 1]?.isDiscount ? 2 : 1;
    updatedRows.splice(index, removeCount);

    const nextActiveIndex = Math.max(0, index - 1);
    this.rows = updatedRows.map((row, idx) => {
      row.showAction = idx === nextActiveIndex;

      return row;
    });
    this.emitLineItemsChange();
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
        displayName: "",
        quantityAvailable: "",
        quantityBackordered: "",
        specialOrderItem: "",
        specialOrderVendorNum: "",
        imageUrl: "",
        itemType: "",
        quantity: "",
        rate: "",
        amount: "",
        quotedPrice: "",
        isRepairNeeded: "",
        isDiscount: false
      };

      this.rows = updatedRows;
      this.emitLineItemsChange();
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
      this.emitLineItemsChange();
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
