import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getUiDefinition from "@salesforce/apex/ReportDefinitionController.getUiDefinition";
import runReport from "@salesforce/apex/ReportEngine.run";
import searchLookup from "@salesforce/apex/ReportLookupController.search";

export default class ConfigurableReport extends LightningElement {
  @api reportKey;

  title = "Report";
  definition;
  filters = [];
  columnDefinitions = [];
  rows = [];
  isLoading = true;
  pageSize = 20;
  pageNumber = 1;
  sortBy;
  sortDirection = "desc";
  hasMore = false;

  connectedCallback() {
    this.initialize();
  }

  async initialize() {
    try {
      this.definition = await getUiDefinition({ reportKey: this.reportKey });
      this.title = this.definition.title || this.reportKey;
      this.filters = this.parseJson(this.definition.uiFiltersJson, []).map(
        (filter) => ({ ...filter, value: filter.defaultValue ?? "" })
      );
      this.columnDefinitions = this.parseJson(this.definition.columnsJson, []);
      this.sortBy = this.definition.defaultSortKey || this.firstSortableColumn;
      await this.loadReport();
    } catch (error) {
      this.showError(error);
      this.isLoading = false;
    }
  }

  get lookupFilters() {
    return this.filters.filter((filter) => filter.type === "lookup");
  }
  get comboboxFilters() {
    return this.filters.filter((filter) => filter.type === "combobox");
  }
  get multiSelectFilters() {
    return this.filters.filter((filter) => filter.type === "multiSelect");
  }
  get inputFilters() {
    return this.filters.filter(
      (filter) => !["lookup", "combobox", "multiSelect"].includes(filter.type)
    );
  }
  get columns() {
    return this.columnDefinitions.map((column) =>
      this.toDatatableColumn(column)
    );
  }
  get hasRows() {
    return this.rows.length > 0;
  }
  get isPreviousDisabled() {
    return this.pageNumber === 1;
  }
  get isNextDisabled() {
    return !this.hasMore;
  }
  get firstSortableColumn() {
    return this.columnDefinitions.find((column) => column.sortable)?.fieldName;
  }
  get offsetSize() {
    return (this.pageNumber - 1) * this.pageSize;
  }

  async loadReport() {
    this.isLoading = true;
    try {
      const page = await runReport({
        reportKey: this.reportKey,
        filters: this.filterValues,
        pageSize: this.pageSize,
        offsetSize: this.offsetSize,
        sortBy: this.sortBy,
        sortDirection: this.sortDirection
      });
      this.hasMore = page.hasMore;
      this.rows = (page.rows || []).map((row, index) =>
        this.mapRow(row, index)
      );
    } catch (error) {
      this.rows = [];
      this.hasMore = false;
      this.showError(error);
    } finally {
      this.isLoading = false;
    }
  }

  get filterValues() {
    return this.filters.reduce(
      (values, filter) => ({ ...values, [filter.key]: filter.value }),
      {}
    );
  }

  async handleLookupSearch(event) {
    const key = event.target.dataset.key;
    const searchText = event.detail.searchKey;
    const input = event.target;
    if (searchText.length < 2) {
      input.setResults([]);
      return;
    }
    input.setLoading(true);
    try {
      input.setResults(
        await searchLookup({
          reportKey: this.reportKey,
          filterKey: key,
          searchText
        })
      );
    } catch (error) {
      input.setResults([]);
      this.showError(error);
    } finally {
      input.setLoading(false);
    }
  }

  handleLookupSelect(event) {
    this.setFilterValue(event.target.dataset.key, event.detail.name);
  }

  handleValueChange(event) {
    const value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;
    this.setFilterValue(event.target.dataset.key, value);
  }

  handleMultiSelectChange(event) {
    this.setFilterValue(event.target.dataset.key, event.detail.value || []);
  }

  setFilterValue(key, value) {
    this.filters = this.filters.map((filter) => {
      return filter.key === key ? { ...filter, value } : filter;
    });
    this.pageNumber = 1;
    this.loadReport();
  }

  handleSort(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.loadReport();
  }

  nextPage() {
    if (this.hasMore) {
      this.pageNumber += 1;
      this.loadReport();
    }
  }

  previousPage() {
    if (this.pageNumber > 1) {
      this.pageNumber -= 1;
      this.loadReport();
    }
  }

  toDatatableColumn(column) {
    const result = { ...column };
    delete result.source;
    delete result.urlTemplate;
    delete result.labelSource;
    if (column.type === "url" && column.labelSource) {
      result.typeAttributes = {
        label: { fieldName: `${column.fieldName}Label` },
        target: "_blank"
      };
    }
    return result;
  }

  mapRow(sourceRow, index) {
    const row = {
      id: this.readPath(sourceRow, "Id") || `${this.offsetSize}-${index}`
    };
    this.columnDefinitions.forEach((column) => {
      if (column.urlTemplate) {
        row[column.fieldName] = column.urlTemplate.replace(
          /{{([^}]+)}}/g,
          (_, path) => this.readPath(sourceRow, path) || ""
        );
        row[`${column.fieldName}Label`] =
          this.readPath(sourceRow, column.labelSource) || "";
      } else {
        row[column.fieldName] = this.readPath(sourceRow, column.source);
      }
    });
    return row;
  }

  readPath(value, path) {
    return (path || "")
      .split(".")
      .reduce((current, key) => current?.[key], value);
  }

  parseJson(value, fallback) {
    try {
      return value ? JSON.parse(value) : fallback;
    } catch {
      return fallback;
    }
  }

  showError(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Report error",
        message: error?.body?.message || "Unable to load the report.",
        variant: "error"
      })
    );
  }
}
