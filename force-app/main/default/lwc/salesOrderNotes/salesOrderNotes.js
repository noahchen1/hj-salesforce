import { LightningElement, api } from "lwc";

const BASE_ROW = Object.freeze({
  owner: "",
  ownerId: "",
  title: "",
  direction: "",
  memo: "",
  dateLastModified: null
});

export default class SalesOrderNotes extends LightningElement {
  @api runningUserName;
  @api runningUserId;

  rows = [];
  previousRowData = [];
  nextRowId = 0;

  constructor() {
    super();
    this.reset();
  }

  @api
  get previousRows() {
    return this.previousRowData;
  }

  set previousRows(value) {
    this.previousRowData = Array.isArray(value)
      ? value.map((row) => ({ ...row }))
      : [];

    if (this.shouldHydrateRows()) {
      this.hydrateRowsFromPrevious();
    }
  }

  get typeOptions() {
    return [
      { label: "Conference Call", value: "2" },
      { label: "E-mail", value: "3" },
      { label: "Fax", value: "4" },
      { label: "Letter", value: "5" },
      { label: "Meeting", value: "6" },
      { label: "Note", value: "7" },
      { label: "Phone Call", value: "8" }
    ];
  }

  get directionOptions() {
    return [
      { label: "Incoming", value: "1" },
      { label: "Outgoing", value: "2" }
    ];
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

  emitNoteChange() {
    this.dispatchEvent(
      new CustomEvent("notechange", {
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
    this.rows = [];
    this.nextRowId = 0;
    this.hydrateRowsFromPrevious();
  }

  shouldHydrateRows() {
    if (!this.rows.length) {
      return true;
    }

    if (this.rows.length > 1) {
      return false;
    }

    const row = this.rows[0];

    const hasData =
      row.owner ||
      row.ownerId ||
      row.title ||
      row.direction ||
      row.memo ||
      row.dateLastModified;

    return !hasData;
  }

  hydrateRowsFromPrevious() {
    if (this.previousRowData.length > 0) {
      this.rows = this.previousRowData.map((row, index) =>
        this.createRow({
          showAction: index === 0,
          disableRemove: index === 0,
          overrides: row
        })
      );

      this.nextRowId = this.rows.length;
      return;
    }

    this.rows = [
      this.createRow({
        id: 1,
        showAction: true,
        disableRemove: true
      })
    ];
    this.nextRowId = 2;
  }

  handleFocus(e) {
    const index = Number(e.target.dataset.index);
    this.rows = this.rows.map((row, idx) => ({
      ...row,
      showAction: idx === index
    }));

    this.emitNoteChange();
  }

  handleRowChange(e) {
    const index = Number(e.target.dataset.index);
    const field = e.target.dataset.field;
    const value = e.target.value;
    const updatedRows = [...this.rows];
    const row = updatedRows[index];

    row[field] = value;
    row.dateLastModified = new Date().toISOString();

    if (this.runningUserName && this.runningUserId) {
      row.owner = this.runningUserName;
      row.ownerId = this.runningUserId;
    }

    this.rows = updatedRows;

    this.emitNoteChange();
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
      this.emitNoteChange();
    } catch (error) {
      console.error(`Error adding row at index ${index}`, error);
    }
  }

  removeRow(e) {
    const index = Number(e.target.dataset.index);
    const updatedRows = [...this.rows];
    updatedRows.splice(index, 1);

    const nextActiveIndex = Math.max(0, index - 1);
    updatedRows.forEach((row, idx) => {
      row.showAction = idx === nextActiveIndex;
    });

    this.rows = updatedRows;
    this.emitNoteChange();
  }
}
