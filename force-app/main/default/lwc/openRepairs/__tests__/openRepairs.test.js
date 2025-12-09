import { createElement } from "@lwc/engine-dom";
import getOpenRepairs from "@salesforce/apex/OpenRepairsController.getOpenRepairs";
import OpenRepairs from "c/openRepairs";

const mockGetOpenRepairs = require("./data/getOpenRepairs.json");

jest.mock(
  "@salesforce/apex/OpenRepairsController.getOpenRepairs",
  () => {
    const {
      createApexTestWireAdapter
    } = require("@salesforce/wire-service-jest-util");

    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

describe("c-open-repairs", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    jest.clearAllMocks();
  });

  it("renders datatable with data", async () => {
    const element = createElement("c-open-repairs", { is: OpenRepairs });
    document.body.appendChild(element);

    getOpenRepairs.emit(mockGetOpenRepairs);

    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");

    expect(datatable).not.toBeNull();
    expect(Array.isArray(datatable.data)).toBe(true);
    expect(datatable.data.length).toBe(mockGetOpenRepairs.length);
  });

  it('shows "No data found" when no rows', async () => {
    const element = createElement("c-open-repairs", { is: OpenRepairs });
    document.body.appendChild(element);

    getOpenRepairs.emit([]);

    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain("No data found.");
  });
});
