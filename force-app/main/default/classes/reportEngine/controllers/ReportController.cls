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
}
