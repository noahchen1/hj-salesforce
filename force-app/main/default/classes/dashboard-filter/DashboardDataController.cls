public with sharing class DashboardDataController {
  @AuraEnabled(cacheable=true)
  public static Integer getFilteredCount(Map<String, Object> filters) {
    String baseQuery = 'SELECT COUNT() FROM Opportunity WHERE Id != null';
    List<String> conditions = new List<String>();

    String statusFilter;
    Datetime startDateFilter;
    Datetime endDateFilter;

    System.debug(filters);

    if (filters != null) {
      if (filters.get('status') != null) {
        statusFilter = (String) filters.get('status');
        conditions.add('StageName = :statusFilter');
      }

      if (filters.get('startDate') != null) {
        Date startDate = Date.valueOf((String) filters.get('startDate'));
        startDateFilter = Datetime.newInstance(
          startDate.year(),
          startDate.month(),
          startDate.day()
        );
        conditions.add('CreatedDate >= :startDateFilter');
      }

      if (filters.get('endDate') != null) {
        Date endDate = Date.valueOf((String) filters.get('endDate'));
        endDateFilter = Datetime.newInstance(
            endDate.year(),
            endDate.month(),
            endDate.day()
          )
          .addSeconds(86399);
        conditions.add('CreatedDate <= :endDateFilter');
      }
    }

    if (!conditions.isEmpty()) {
      baseQuery += ' AND ' + String.join(conditions, ' AND ');
    }

    System.debug('Final Query: ' + baseQuery);

    return Database.countQuery(baseQuery);
  }
}
