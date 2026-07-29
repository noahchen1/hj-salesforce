import { createElement } from "@lwc/engine-dom";
import SalesOrderLineItems from "c/salesOrderLineItems";
import getValue from "@salesforce/apex/DataService.getValue";

jest.mock(
  "@salesforce/apex/DataService.getValue",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

describe("c-sales-order-line-items", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(orderType) {
    const element = createElement("c-sales-order-line-items", {
      is: SalesOrderLineItems
    });
    element.orderType = orderType;
    document.body.appendChild(element);

    return element;
  }

  function getDisplayNameInput(element) {
    return element.shadowRoot.querySelector(
      'lightning-input[data-field="displayName"]'
    );
  }

  it("enables Display Name editing for special orders", () => {
    const element = createComponent("special");
    const displayNameInput = getDisplayNameInput(element);

    expect(displayNameInput.readOnly).toBe(false);

    displayNameInput.value = "Updated special-order name";
    displayNameInput.dispatchEvent(new CustomEvent("change"));

    expect(element.getRows()[0].displayName).toBe("Updated special-order name");
  });

  it.each(["sales", "repair"])(
    "keeps Display Name read-only for %s orders",
    (orderType) => {
      const element = createComponent(orderType);

      expect(getDisplayNameInput(element).readOnly).toBe(true);
    }
  );

  it("sets Display Name when an HJ SKU is selected", async () => {
    getValue.mockResolvedValue({
      breadwinner_ns__VendorName__c: "VENDOR-123",
      Base_Price__c: 125,
      breadwinner_ns__DisplayName__c: "Selected HJ SKU display name"
    });
    const element = createComponent("special");
    const lookup = element.shadowRoot.querySelector(
      'c-lookup-input[data-type="specialOrderItem"]'
    );

    lookup.dispatchEvent(
      new CustomEvent("select", {
        detail: { id: "a001", name: "HJ-SKU-123" }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    expect(getValue).toHaveBeenCalledWith({
      recordName: "breadwinner_ns__BW_Item__c",
      fieldNames: [
        "breadwinner_ns__VendorName__c",
        "Base_Price__c",
        "breadwinner_ns__DisplayName__c"
      ],
      recordId: "a001"
    });
    expect(element.getRows()[0].displayName).toBe(
      "Selected HJ SKU display name"
    );
  });

  it("sets Display Name when a vendor item number is selected", async () => {
    getValue.mockResolvedValue({
      Name: "HJ-SKU-456",
      Base_Price__c: 250,
      breadwinner_ns__DisplayName__c: "Selected vendor item display name"
    });
    const element = createComponent("special");
    const lookup = element.shadowRoot.querySelector(
      'c-lookup-input[data-type="specialOrderVendorNum"]'
    );

    lookup.dispatchEvent(
      new CustomEvent("select", {
        detail: { id: "a002", name: "VENDOR-456" }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    expect(getValue).toHaveBeenCalledWith({
      recordName: "breadwinner_ns__BW_Item__c",
      fieldNames: ["Name", "Base_Price__c", "breadwinner_ns__DisplayName__c"],
      recordId: "a002"
    });
    expect(element.getRows()[0].displayName).toBe(
      "Selected vendor item display name"
    );
  });
});
