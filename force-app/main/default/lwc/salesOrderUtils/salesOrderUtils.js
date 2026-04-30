export function processPicklistData(data, isAddress = false) {
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
}
