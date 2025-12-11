export function getSortFunction(sortBy, sortDirection) {
  return (a, b) => {
    let valA = a[sortBy];
    let valB = b[sortBy];

    if (sortBy.toUpperCase().includes("DATE")) {
      valA = new Date(valA).getTime();
      valB = new Date(valB).getTime();

      return sortDirection === "asc" ? valA - valB : valB - valA;
    }

    if (typeof valA === "number" && typeof valB === "number") {
      return sortDirection === "asc" ? valA - valB : valB - valA;
    }

    valA = valA ? valA.toString().toLowerCase() : "";
    valB = valB ? valB.toString().toLowerCase() : "";

    if (valA < valB) return sortDirection === "asc" ? -1 : 1;
    if (valA > valB) return sortDirection === "asc" ? 1 : -1;
    return 0;
  };
}
