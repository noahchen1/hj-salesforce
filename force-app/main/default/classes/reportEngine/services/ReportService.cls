public with sharing class ReportService {
  private static final Integer DEFAULT_PAGE_SIZE = 20;
  private static final Integer MAX_PAGE_SIZE = 200;

  public static ReportModels.ReportPage run(
    ReportModels.ReportRequest request
  ) {
    validateRequest(request);

    ReportDefinitions.Definition storedDefinition = ReportDefinitions.get(
      request.reportKey
    );

    if (storedDefinition == null || !storedDefinition.isActive) {
      throw new AuraHandledException('The requested report is unavailable.');
    }

    ReportModels.ParsedFilterDefinition definition = ReportConfigBuilder.parse(
      storedDefinition
    );

    Integer pageSize = normalizePageSize(request.pageSize);
    Integer offsetSize = normalizeOffset(request.offsetSize);

    ReportModels.QuerySpec querySpec = ReportQueryBuilder.build(
      definition,
      request.filters == null ? new Map<String, Object>() : request.filters,
      pageSize + 1,
      offsetSize,
      request.sortBy,
      request.sortDirection
    );

    List<SObject> rows = Database.queryWithBinds(
      querySpec.soql,
      querySpec.binds,
      AccessLevel.SYSTEM_MODE
    );

    return createPage(rows, pageSize, offsetSize);
  }

  private static void validateRequest(ReportModels.ReportRequest request) {
    if (request == null || String.isBlank(request.reportKey)) {
      throw new AuraHandledException('A report key is required.');
    }
  }

  private static Integer normalizePageSize(Integer pageSize) {
    Integer result = pageSize == null ? DEFAULT_PAGE_SIZE : pageSize;

    return Math.max(1, Math.min(result, MAX_PAGE_SIZE));
  }

  private static Integer normalizeOffset(Integer offsetSize) {
    return offsetSize == null ? 0 : Math.max(0, offsetSize);
  }

  private static ReportModels.ReportPage createPage(
    List<SObject> rows,
    Integer pageSize,
    Integer offsetSize
  ) {
    ReportModels.ReportPage page = new ReportModels.ReportPage();

    page.hasMore = rows.size() > pageSize;
    page.rows = new List<SObject>();

    Integer returnedCount = Math.min(rows.size(), pageSize);
    for (Integer index = 0; index < returnedCount; index++) {
      page.rows.add(rows[index]);
    }
    
    page.pageSize = pageSize;
    page.offsetSize = offsetSize;

    return page;
  }
}
