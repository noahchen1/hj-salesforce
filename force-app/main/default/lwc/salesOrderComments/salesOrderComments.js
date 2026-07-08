import { LightningElement, api } from "lwc";

const BASE_ROW = Object.freeze({
  internalId: null,
  nsEmployee: "",
  nsEmployeeId: "",
  comment: "",
  dateLastModified: null
});

export default class SalesOrderComments extends LightningElement {
  @api runningUserName;
  @api runningUserId;

  rows = [];
  nextRowId = 0;
  debounceTimer;

  constructor() {
    super();
    this.reset();
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

  emitCommentChange() {
    this.dispatchEvent(
      new CustomEvent("commentchange", {
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
          comment: row.comment,
          dateLastModified: row.lastModified,
          actionKey: row.actionKey || `action-${rowId}`
        }
      });
    });

    this.nextRowId = this.rows.length + 1;
    this.emitCommentChange();
  }

  @api
  reset() {
    this.rows = [
      this.createRow({ id: 1, showAction: true, disableRemove: true })
    ];

    this.nextRowId = 2;
    this.emitCommentChange();
  }

  handleFocus(e) {
    const index = Number(e.target.dataset.index);
    this.rows = this.rows.map((row, idx) => ({
      ...row,
      showAction: idx === index
    }));

    this.emitCommentChange();
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

      this.emitCommentChange();
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
      this.emitCommentChange();
    } catch (error) {
      console.error(`Error adding row at index ${index}`, error);
    }
  }

  removeRow(e) {
    const index = Number(e.target.dataset.index);

    if (this.rows[index]?.disableRemove) {
      return;
    }

    const updatedRows = [...this.rows];
    updatedRows.splice(index, 1);

    const nextActiveIndex = Math.max(0, index - 1);
    updatedRows.forEach((row, idx) => {
      row.showAction = idx === nextActiveIndex;
    });

    this.rows = updatedRows;
    this.emitCommentChange();
  }
}
