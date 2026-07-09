import { LightningElement, api } from "lwc";

const BASE_ROW = Object.freeze({
  internalId: null,
  nsEmployee: "",
  nsEmployeeId: "",
  instruction: "",
  dateLastModified: null
});

export default class SalesOrderInstructions extends LightningElement {
  @api orderType;
  @api runningUserName;
  @api runningUserId;

  rows = [];
  nextRowId = 0;
  debounceTimer;

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

  get hasRows() {
    return this.rows.length > 0;
  }

  get activeRowIndex() {
    const activeIndex = this.rows.findIndex((row) => row.showAction);

    return activeIndex === -1 ? 0 : activeIndex;
  }

  get isActiveRowRemoveDisabled() {
    return (
      this.rows.length <= 1 || this.rows[this.activeRowIndex]?.disableRemove
    );
  }

  disconnectedCallback() {
    clearTimeout(this.debounceTimer);
  }

  emitInstructionChange() {
    this.dispatchEvent(
      new CustomEvent("instructionchange", {
        detail: {
          rows: this.getRows()
        }
      })
    );
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
  setRows(rows) {
    const sourceRows = rows || [];

    if (sourceRows.length === 0) {
      this.reset();

      return;
    }

    this.rows = sourceRows.map((row, index) => {
      const rowId = row.id || index + 1;

      return this.createRow({
        id: rowId,
        showAction: index === 0,
        disableRemove: true,
        overrides: {
          internalId: row.internalId,
          nsEmployee: row.nsEmployeeName,
          nsEmployeeId: row.nsEmployeeId,
          instruction: row.instruction,
          dateLastModified: row.lastModified,
          actionKey: row.actionKey || `action-${rowId}`
        }
      });
    });

    this.nextRowId = this.rows.length + 1;
    this.emitInstructionChange();
  }

  @api
  reset() {
    this.rows = [
      this.createRow({ id: 1, showAction: true, disableRemove: false })
    ];

    this.nextRowId = 2;
    this.emitInstructionChange();
  }

  handleFocus(e) {
    const index = Number(e.target.dataset.index);
    this.rows = this.rows.map((row, idx) => ({
      ...row,
      showAction: idx === index
    }));
  }

  handleRowChange(e) {
    const index = Number(e.target.dataset.index);
    const field = e.target.dataset.field;
    const value = e.target.value;
    const updatedRows = [...this.rows];
    const row = updatedRows[index];

    clearTimeout(this.debounceTimer);

    this.debounceTimer = setTimeout(() => {
      row[field] = value;
      row.dateLastModified = new Date().toISOString();

      if (this.runningUserName && this.runningUserId) {
        row.nsEmployee = this.runningUserName;
        row.nsEmployeeId = this.runningUserId;
      }

      this.rows = updatedRows;

      this.emitInstructionChange();
    }, 400);
  }

  addRow() {
    try {
      const newRow = this.createRow();
      const newRowIndex = this.rows.length;

      const updatedRows = [...this.rows];
      updatedRows.push(newRow);
      updatedRows.forEach((row, idx) => {
        row.showAction = idx === newRowIndex;
      });
      this.rows = updatedRows;
      this.emitInstructionChange();
    } catch (error) {
      console.error("Error adding row", error);
    }
  }

  removeRow(e) {
    const index = Number(e.target.dataset.index);

    if (this.rows[index]?.disableRemove) {
      return;
    }

    const updatedRows = [...this.rows];
    const removeCount = updatedRows[index + 1]?.isDiscount ? 2 : 1;
    updatedRows.splice(index, removeCount);

    const nextActiveIndex = Math.max(0, index - 1);
    updatedRows.forEach((row, idx) => {
      row.showAction = idx === nextActiveIndex;
    });

    this.rows = updatedRows;
    this.emitInstructionChange();
  }
}
