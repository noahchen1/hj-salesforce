import { LightningElement, api } from "lwc";

const BASE_ROW = Object.freeze({
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
    return this.rows.length <= 1 || this.activeRowIndex === 0;
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
  reset() {
    this.rows = [
      this.createRow({ id: 1, showAction: true, disableRemove: true })
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

    this.emitInstructionChange();
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
      this.emitInstructionChange();
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
    updatedRows.forEach((row, idx) => {
      row.showAction = idx === nextActiveIndex;
    });

    this.rows = updatedRows;
    this.emitInstructionChange();
  }
}
