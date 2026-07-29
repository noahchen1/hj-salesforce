import { createElement } from "@lwc/engine-dom";
import InquiryFormItems from "c/inquiryFormItems";
import getParentByVendorNum from "@salesforce/apex/DataService.getParentByVendorNum";

jest.mock(
  "@salesforce/apex/DataService.getParentByVendorNum",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

describe("c-inquiry-form-items", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("adds the parent item's Display Name to inquiry line items", async () => {
    getParentByVendorNum.mockResolvedValue({
      name: "HJ-SKU-123",
      basePrice: "125.00",
      displayName: "Inquiry item display name"
    });
    const element = createElement("c-inquiry-form-items", {
      is: InquiryFormItems
    });
    element.isRolex = true;
    element.toggleFields = true;
    document.body.appendChild(element);

    const modelInput = element.shadowRoot.querySelector(
      'lightning-input[data-type="model"]'
    );
    modelInput.value = "VENDOR-123";
    modelInput.dispatchEvent(new CustomEvent("change"));

    const fields = await element.getFields();

    expect(getParentByVendorNum).toHaveBeenCalledWith({
      vendorNum: "VENDOR-123"
    });
    expect(fields.rows[0].displayName).toBe("Inquiry item display name");
  });
});
