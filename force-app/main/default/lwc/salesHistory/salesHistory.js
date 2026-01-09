import { LightningElement, wire, track } from "lwc";
import getSalesHistory from "@salesforce/apex/SalesHistory.getSalesHistory";
import searchCustomer from "@salesforce/apex/FilterDataController.searchCustomer";

export default class SalesHistory extends LightningElement {
  @track customer = "";
  @track pageNumber = 1;
  @track pageSize = 20;

  @wire(getSalesHistory, {
    customer: "$customer",
    limitSize: "$pageSize",
    offsetSize: "$offset"
  })
  wiredData;

  get rows() {
    const data = this.wiredData?.data?.rows || [];

    const mappedData = data.map((r) => ({
      id: r?.id,
      transaction: r?.tranNumber,
      // customer: r?.customer,
      // salesRep: r?.salesRep,
      division: r?.division,
      item: r?.item,
      quantity: r?.quantity,
      amount: r?.amount,
      // anniversary: r?.anniversary,
      // birthday: r?.birthday,
      // leadsource: r?.leadsource,
      location: r?.location,
      preferredVendor: r?.preferredVendor,
      trandate: this.formateDate(r?.trandate)
      // isNewCustomer: r?.isNewCustomer,
      // isServiceOnly: r?.isServiceOnly,
      // ranking: r?.ranking
    }));

    return mappedData;
  }

  get columns() {
    return [
      { label: "Transaction", fieldName: "transaction", sortable: true },
      // { label: "Customer", fieldName: "customer", sortable: true },
      // { label: "Sales Rep", fieldName: "salesRep", sortable: true },
      { label: "Division", fieldName: "division", sortable: true },
      { label: "Item", fieldName: "item", sortable: true },
      {
        label: "Quantity",
        fieldName: "quantity",
        type: "number",
        sortable: true
      },
      { label: "Amount", fieldName: "amount", sortable: true },
      // { label: "Anniversary", fieldName: "anniversary", sortable: true },
      // { label: "Birthday", fieldName: "birthday", sortable: true },
      // { label: "Lead Source", fieldName: "leadsource", sortable: true },
      { label: "Location", fieldName: "location", sortable: true },
      {
        label: "Preferred Vendor",
        fieldName: "preferredVendor",
        sortable: true
      },
      { label: "Date", fieldName: "trandate", sortable: true }
      // {
      //   label: "New Customer",
      //   fieldName: "isNewCustomer",
      //   type: "boolean",
      //   sortable: true
      // },
      // {
      //   label: "Service Only",
      //   fieldName: "isServiceOnly",
      //   type: "boolean",
      //   sortable: true
      // },
      // { label: "Ranking", fieldName: "ranking", sortable: true }
    ];
  }

  get offset() {
    return (this.pageNumber - 1) * this.pageSize;
  }

  async handleLookupSearch(e) {
    const type = e.target.dataset.type;
    const searchKey = e.detail.searchKey;
    const input = this.template.querySelector(
      `c-lookup-input[data-type="${type}"]`
    );

    let searchFn;

    if (type === "customer") {
      searchFn = searchCustomer;
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
      this[type] = "";
    }
  }

  handleLookupSelect(e) {
    const type = e.target.dataset.type;
    const selectedName = e.detail.name;
    this[type] = selectedName;
    this.pageNumber = 1;
  }

  formateDate = (date) => (date ? new Date(date).toLocaleDateString() : "");
}
