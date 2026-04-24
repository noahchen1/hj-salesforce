export function formatAddress({
  contact,
  addr1,
  addr2,
  city,
  state,
  zip,
  country
}) {
  const street = [addr1, addr2].filter(Boolean).join(" ");
  const cityStateZip = [city, state, zip].filter(Boolean).join(", ");

  return [contact, street, cityStateZip, country].filter(Boolean).join("\n");
}
