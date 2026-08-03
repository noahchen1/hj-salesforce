import { createElement } from "@lwc/engine-dom";
import LookupInput from "c/lookupInput";

describe("c-lookup-input", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders DisplayName and returns the raw Name when selected", async () => {
    const element = createElement("c-lookup-input", {
      is: LookupInput
    });
    const selectHandler = jest.fn();
    element.addEventListener("select", selectHandler);

    document.body.appendChild(element);
    element.setResults([
      {
        Id: "item-id",
        Name: "SKU-001",
        DisplayName: "SKU-001 Emerald Bracelet",
        NsId: "123"
      }
    ]);
    await Promise.resolve();

    const result = element.shadowRoot.querySelector("li[data-id='item-id']");
    expect(result.textContent.trim()).toBe("SKU-001 Emerald Bracelet");

    result.click();
    await Promise.resolve();

    expect(selectHandler).toHaveBeenCalledTimes(1);
    expect(selectHandler.mock.calls[0][0].detail).toEqual({
      id: "item-id",
      name: "SKU-001",
      displayName: "SKU-001 Emerald Bracelet",
      nsId: "123"
    });
    expect(element.shadowRoot.querySelector("lightning-input").value).toBe(
      "SKU-001"
    );
  });
});
