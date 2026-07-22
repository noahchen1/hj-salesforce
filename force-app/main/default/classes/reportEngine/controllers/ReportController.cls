public with sharing class ReportController {
  @AuraEnabled(cacheable=true)
  public static ReportModels.ReportPage run(
    String reportKey,
    Map<String, Object> filters,
    Integer pageSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    try {
      ReportModels.ReportRequest request = new ReportModels.ReportRequest();

      request.reportKey = reportKey;
      request.filters = filters;
      request.pageSize = pageSize;
      request.offsetSize = offsetSize;
      request.sortBy = sortBy;
      request.sortDirection = sortDirection;

      return ReportService.run(request);
    } catch (AuraHandledException e) {
      throw new AuraHandledException(e.getMessage());
    } catch (Exception e) {
      //replace with logger logic
      System.debug(
        LoggingLevel.ERROR,
        'Unexpected report error: ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString()
      );

      throw new AuraHandledException('Unable to load the requested report.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<FilterDataController.LookupResult> search(
    String reportKey,
    String filterKey,
    String searchText
  ) {
    if (String.isBlank(searchText) || searchText.length() < 2) {
      return new List<FilterDataController.LookupResult>();
    }

    if (filterKey == 'customer')
      return FilterDataController.searchCustomer(searchText);
    if (filterKey == 'salesRep')
      return FilterDataController.searchSalesRep(searchText);
    if (filterKey == 'station')
      return FilterDataController.searchRepairStation(searchText);
    if (filterKey == 'vendor')
      return FilterDataController.searchVendor(searchText);
    if (filterKey == 'vendorItemNum')
      return FilterDataController.searchVendorNum(searchText);
    if (filterKey == 'item')
      return FilterDataController.searchItem(searchText);

    throw new AuraHandledException('This report lookup is unavailable.');
  }
}
