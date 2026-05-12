export const processPicklistData = (data, isAddress = false) => {
  const blank = { label: "Select", value: "" };

  if (!data?.length) {
    return { options: [blank], defaultShipping: "", defaultBilling: "" };
  }

  let defaultShipping = "";
  let defaultBilling = "";

  const options = [
    blank,
    ...data.map((item) => {
      const value = item.value ?? item.id ?? item.internalId ?? "";
      if (isAddress) {
        if (item.isDefaultShipping) defaultShipping = value;
        if (item.isDefaultBilling) defaultBilling = value;
      }
      return {
        label: item.label ?? item.name ?? "",
        value
      };
    })
  ];

  return { options, defaultShipping, defaultBilling };
};

export const isValidRolexVendorNum = (str) => {
  const regex = /^M\d{5,}[A-Za-z]*-\d{4}$/i;

  return regex.test(str);
};

export const VENDOR_REQUIRED_ITEM_TYPES = new Set(["1", "2", "4", "5", "6"]);

export const SELLABLE_SPECIAL_ALLOWED_STATUSES = new Set([
  "3",
  "4",
  "102",
  "5",
  "6",
  "7"
]);

// Manager Approved
// Request Received
// Order Confirmed
// On Backorder
// Ordered
// Stocked
