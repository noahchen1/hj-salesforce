import { LightningElement, wire, api } from "lwc";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";
import searchSalesRep from "@salesforce/apex/FilterDataController.searchSalesRep";
import getNsCompanyFromAccount from "@salesforce/apex/SalesOrderController.getNsCompanyFromAccount";
import { processPicklistData } from "c/salesOrderUtils";
import getEmployeeData from "@salesforce/apex/DataService.getEmployeeData";
import getSubsidiaries from "@salesforce/apex/DropdownDataController.getSubsidiaries";
import getSubsidiaryLocations from "@salesforce/apex/DropdownDataController.getSubsidiaryLocations";
import USER_ID from "@salesforce/user/Id";

export default class InquiryFormBody extends LightningElement {
  @api accountId;

  customer = "";
  date = new Date().toISOString();
  salesRep1 = "";
  salesRep2 = "";
  location = "";
  subsidiary = "";
  locationOptions = [];
  personalization = "";
  isSendEmail = true;
  isEmailPreferred = false;
  isCallPreferred = false;
  isMessagePreferred = false;
  comments = "";

  isLoaded = false;
  isLocationLoaded = false;
  isCustomerLoaded = false;
  isFormInit = false;

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
    this.locationOptions = options.filter(({ label, value }) =>
      ["", "26", "28"].includes(value)
    );
    this.isLocationLoaded = true;
    this.checkLoadingState();
  }

  async connectedCallback() {
    try {
      const [subsidiaries, emp] = await Promise.all([
        getSubsidiaries(),
        getEmployeeData({ userId: USER_ID })
      ]);

      const { options: subOptions } = processPicklistData(subsidiaries);
      this.subsidiaryOptions = subOptions.filter(({ label, value }) =>
        ["", "10", "30"].includes(value)
      );

      if (emp !== null) {
        this.salesRep1 = emp.employeeId;
        this.subsidiary = emp.subsidiaryId;
        this.location = emp.locationId;

        this.setLookupValue("salesRep1", emp.employeeName);
      }

      if (this.subsidiary) {
        const locations = await getSubsidiaryLocations({
          subsidiary: this.subsidiary
        });

        const { options: locOptions } = processPicklistData(locations);
        this.locationOptions = locOptions.filter(({ label, value }) =>
          ["", "26", "28"].includes(value)
        );

        if (!this.locationOptions.some((opt) => opt.value === this.location)) {
          this.location = "";
        }
      }
    } catch (error) {
      console.error("Init failed:", error);
      console.error(error.message);
      this.isFormInit = true;
      this.checkLoadingState();
    } finally {
      this.isFormInit = true;
      this.checkLoadingState();
    }
  }

  async renderedCallback() {
    if (!this.accountId || this.isCustomerLoaded) return;

    try {
      this.isCustomerLoaded = false;
      const nsCompany = await getNsCompanyFromAccount({
        accountId: this.accountId
      });

      if (nsCompany != null) {
        const {
          name,
          companyId,
          internalId,
          isEmailPreferred,
          isCallPreferred,
          isMessagePreferred
        } = nsCompany;

        if (internalId) this.customer = internalId;
        if (isEmailPreferred) this.isEmailPreferred = isEmailPreferred;
        if (isCallPreferred) this.isCallPreferred = isCallPreferred;
        if (isMessagePreferred) this.isMessagePreferred = isMessagePreferred;

        if (name) {
          this.setLookupValue("customer", name);
        }
      }
    } catch (error) {
      console.error(error);
    } finally {
      this.isCustomerLoaded = true;
      this.checkLoadingState();
    }
  }

  @api
  getFields() {
    return {
      customer: this.customer,
      date: this.date,
      salesRep1: this.salesRep1,
      salesRep2: this.salesRep2,
      subsidiary: this.subsidiary,
      location: this.location,
      personalization: this.personalization,
      isSendEmail: this.isSendEmail,
      comments: this.comments,
      needByDate: this.date,
      isEmailPreferred: this.isEmailPreferred,
      isCallPreferred: this.isCallPreferred,
      isMessagePreferred: this.isMessagePreferred
    };
  }

  @api
  validateFields() {
    const inputs = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("lightning-combobox"),
      ...this.template.querySelectorAll("lightning-textarea"),
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

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = e.target;
    const isSalesRepFields = type === "salesRep1" || type === "salesRep2";

    const searchFn =
      type === "customer"
        ? searchCustomer
        : isSalesRepFields
          ? searchSalesRep
          : null;

    if (searchKey.length > 1) {
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
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const { id, nsId } = e.detail;

    this[type] = nsId;
  }

  handleComboboxChange(e) {
    const name = e.target.name;
    const value = e.target.value;

    this[name] = value;
  }

  handleInputChange(e) {
    const isCheckBox = e.target.type === "checkbox";
    const type = e.target.dataset.type;
    const value = isCheckBox ? e.target.checked : e.target.value;

    this[type] = value;
  }

  checkLoadingState() {
    if (this.isLocationLoaded && this.isFormInit && this.isCustomerLoaded) {
      this.isLoaded = true;
      this.dispatchEvent(new CustomEvent("loaded"));
    }
  }

  setLookupValue(type, name) {
    const lookup = this.template.querySelector(
      `c-lookup-input[data-type="${type}"]`
    );

    if (lookup) lookup.setSelected(name);
  }
}
