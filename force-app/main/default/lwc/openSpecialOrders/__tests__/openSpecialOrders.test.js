import { createElement } from "@lwc/engine-dom";
import OpenSpecialOrders from "c/openSpecialOrders";
import getOpenSpecialOrders from "@salesforce/apex/OpenSpecialOrdersController.getOpenSpecialOrders";

const mockGetOpenSpecialOrders = require("./data/getOpenSpecialOrders.json");

jest.mock(
  "@salesforce/apex/OpenSpecialOrdersController.getOpenSpecialOrders",
  () => {
    const {
      createApexTestWireAdapter
    } = require("@salesforce/wire-service-jest-util");

    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

describe("c-open-special-orders", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders datatable with data", async () => {
    const element = createElement("c-open-special-orders", {
      is: OpenSpecialOrders
    });

    document.body.appendChild(element);

    getOpenSpecialOrders.emit(mockGetOpenSpecialOrders);

    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");

    expect(datatable).not.toBeNull();
    expect(Array.isArray(datatable.data)).toBe(true);
    expect(datatable.data.length).toBe(mockGetOpenSpecialOrders.length);
  });

  it('shows "No data found" when no rows', async () => {
    const element = createElement("c-open-special-orders", {
      is: OpenSpecialOrders
    });

    document.body.appendChild(element);

    getOpenSpecialOrders.emit([]);

    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain("No data found.");
  });

  it("updates comments when handleCommentsChange is called", async () => {
    const element = createElement("c-open-special-orders", {
      is: OpenSpecialOrders
    });

    document.body.appendChild(element);

    const input = element.shadowRoot.querySelector(
      'lightning-input[data-field-name="comments"]'
    );

    input.value = "Test comment";
    input.dispatchEvent(new CustomEvent("change"));

    await Promise.resolve();

    expect(getOpenSpecialOrders.getLastConfig().comments).toBe("Test comment");
  });
});
