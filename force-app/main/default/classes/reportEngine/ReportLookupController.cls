public with sharing class ReportLookupController {
  @AuraEnabled(cacheable=true)
  public static List<FilterDataController.LookupResult> search(
    String reportKey,
    String filterKey,
    String searchText
  ) {
    if (String.isBlank(searchText) || searchText.length() < 2) {
      return new List<FilterDataController.LookupResult>();
    }

    // This is intentionally an allowlist, not a dynamic method invocation.
    if (filterKey == 'customer') return FilterDataController.searchCustomer(searchText);
    if (filterKey == 'salesRep') return FilterDataController.searchSalesRep(searchText);
    if (filterKey == 'station') return FilterDataController.searchRepairStation(searchText);
    if (filterKey == 'vendor') return FilterDataController.searchVendor(searchText);
    if (filterKey == 'vendorItemNum') return FilterDataController.searchVendorNum(searchText);
    if (filterKey == 'item') return FilterDataController.searchItem(searchText);
    throw new AuraHandledException('This report lookup is unavailable.');
  }
}
