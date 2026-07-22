/**
 * Configuration-driven query runner for Lightning report components.
 *
 * Report definitions live in ReportDefinitions. The JSON fields contain
 * only declarative structure; all identifiers and operators are validated
 * before they are included in SOQL, and every value is passed as a bind.
 */

// ReportEngine.ReportPage page = ReportEngine.run(
//   'Open_Repairs',
//   new Map<String, Object>{
//     'customer' => customer,
//     'salesRep' => salesRep,
//     'station' => station
//   },
//   20,
//   0,
//   'date',
//   'desc'
// );

public with sharing class ReportEngine {
  private static final Integer DEFAULT_PAGE_SIZE = 20;
  private static final Integer MAX_PAGE_SIZE = 200;
  private static final Set<String> ALLOWED_OPERATORS = new Set<String>{
    '=',
    '!=',
    '<',
    '>',
    '<=',
    '>=',
    'LIKE',
    'IN',
    'NOT IN',
    'IS NULL',
    'IS NOT NULL'
  };

  public class FilterDefinition {
    public String key;
    public String field;
    public String operator;
    public Object value;
    public String valueType;
  }

  public class ReportPage {
    @AuraEnabled
    public List<SObject> rows;
    @AuraEnabled
    public Boolean hasMore;
    @AuraEnabled
    public Integer pageSize;
    @AuraEnabled
    public Integer offsetSize;
  }

  private class QueryParts {
    private String soql;
    private Map<String, Object> binds;
  }

  @AuraEnabled(cacheable=true)
  public static ReportPage run(
    String reportKey,
    Map<String, Object> filters,
    Integer pageSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    if (String.isBlank(reportKey)) {
      throw new AuraHandledException('A report key is required.');
    }

    ReportDefinitions.Definition definition = ReportDefinitions.get(reportKey);

    if (definition == null || !definition.isActive) {
      throw new AuraHandledException('The requested report is unavailable.');
    }

    Integer safePageSize = pageSize == null ? DEFAULT_PAGE_SIZE : pageSize;
    safePageSize = Math.max(1, Math.min(safePageSize, MAX_PAGE_SIZE));

    Integer safeOffset = offsetSize == null ? 0 : Math.max(0, offsetSize);
    Map<String, Object> safeFilters = null ? new Map<String, Object>() : filters;

    try {
      QueryParts parts = buildQuery(
        definition,
        safeFilters,
        safePageSize + 1,
        safeOffset,
        sortBy,
        sortDirection
      );

      List<SObject> results = Database.queryWithBinds(
        parts.soql,
        parts.binds,
        // The existing report controllers use dynamic SOQL without USER_MODE.
        // Keep that behavior while the reports are migrated; class sharing still
        // applies record-level sharing rules.
        AccessLevel.SYSTEM_MODE
      );

      ReportPage page = new ReportPage();
      page.hasMore = results.size() > safePageSize;
      page.rows = page.hasMore ? takeFirst(results, safePageSize) : results;
      page.pageSize = safePageSize;
      page.offsetSize = safeOffset;
      return page;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'ReportEngine failed: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Unable to load this report: ' + e.getMessage()
      );
    }
  }

  @TestVisible
  private static QueryParts buildQuery(
    ReportDefinitions.Definition definition,
    Map<String, Object> runtimeValues,
    Integer limitSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    Schema.SObjectType sourceType = getSourceType(definition.sourceObject);

    List<Object> selectConfig = deserializeList(
      definition.selectFieldsJson,
      'select fields'
    );
    
    List<String> selectedFields = new List<String>();
    for (Object item : selectConfig) {
      selectedFields.add(
        validateSelectExpression(String.valueOf(item), sourceType)
      );
    }
    if (selectedFields.isEmpty()) {
      throw new AuraHandledException(
        'The report definition has no selected fields.'
      );
    }

    Map<String, Object> binds = new Map<String, Object>();
    List<String> whereParts = new List<String>();

    addFilters(
      whereParts,
      binds,
      deserializeFilters(definition.baseFiltersJson, 'base filters'),
      new Map<String, Object>(),
      sourceType,
      'base'
    );

    addFilters(
      whereParts,
      binds,
      deserializeFilters(definition.runtimeFiltersJson, 'runtime filters'),
      runtimeValues,
      sourceType,
      'runtime'
    );

    String query =
      'SELECT ' +
      String.join(selectedFields, ', ') +
      ' FROM ' +
      definition.sourceObject;
    if (!whereParts.isEmpty())
      query += ' WHERE ' + String.join(whereParts, ' AND ');

    List<Object> groupByConfig = deserializeList(
      definition.groupByFieldsJson,
      'group by fields'
    );
    if (!groupByConfig.isEmpty()) {
      List<String> groupByFields = new List<String>();
      for (Object item : groupByConfig)
        groupByFields.add(validateFieldPath(String.valueOf(item), sourceType));
      query += ' GROUP BY ' + String.join(groupByFields, ', ');
    }

    Map<String, Object> sortConfig = deserializeMap(
      definition.sortFieldsJson,
      'sort fields'
    );
    String sortExpression = sortConfig.containsKey(sortBy)
      ? String.valueOf(sortConfig.get(sortBy))
      : definition.defaultSort;
    if (String.isNotBlank(sortExpression)) {
      query +=
        ' ORDER BY ' + validateSelectExpression(sortExpression, sourceType);
      query += String.valueOf(sortDirection).toLowerCase() == 'asc'
        ? ' ASC'
        : ' DESC';
      query += ' NULLS LAST';
    }

    binds.put('limitSize', limitSize);
    binds.put('offsetSize', offsetSize);
    QueryParts parts = new QueryParts();
    parts.soql = query + ' LIMIT :limitSize OFFSET :offsetSize';
    parts.binds = binds;
    return parts;
  }

  private static void addFilters(
    List<String> whereParts,
    Map<String, Object> binds,
    List<FilterDefinition> definitions,
    Map<String, Object> values,
    Schema.SObjectType sourceType,
    String prefix
  ) {
    for (FilterDefinition filter : definitions) {
      if (String.isBlank(filter.field) || String.isBlank(filter.operator)) {
        throw new AuraHandledException('A report filter is incomplete.');
      }
      String operator = filter.operator.trim().toUpperCase();
      if (!ALLOWED_OPERATORS.contains(operator)) {
        throw new AuraHandledException(
          'A report filter uses an invalid operator.'
        );
      }
      String field = validateFieldPath(filter.field, sourceType);
      if (operator == 'IS NULL' || operator == 'IS NOT NULL') {
        whereParts.add(field + ' ' + operator);
        continue;
      }

      Object value = String.isBlank(filter.key)
        ? filter.value
        : values.get(filter.key);
      if (
        value == null ||
        (value instanceof String && String.isBlank((String) value))
      )
        continue;
      String bindName = prefix + '_' + String.valueOf(whereParts.size());
      binds.put(bindName, coerceValue(value, filter.valueType));
      whereParts.add(field + ' ' + operator + ' :' + bindName);
    }
  }

  private static Object coerceValue(Object value, String valueType) {
    if (value instanceof List<Object>) {
      List<String> normalizedValues = new List<String>();
      for (Object item : (List<Object>) value) {
        normalizedValues.add(String.valueOf(item));
      }
      return normalizedValues;
    }
    if (String.isBlank(valueType))
      return value;
    if (valueType == 'Date')
      return Date.valueOf(String.valueOf(value));
    if (valueType == 'Integer')
      return Integer.valueOf(String.valueOf(value));
    if (valueType == 'Decimal')
      return Decimal.valueOf(String.valueOf(value));
    if (valueType == 'Boolean')
      return String.valueOf(value).toLowerCase() == 'true';
    return value;
  }

  private static Schema.SObjectType getSourceType(String sourceObject) {
    if (
      String.isBlank(sourceObject) ||
      !Schema.getGlobalDescribe().containsKey(sourceObject)
    ) {
      throw new AuraHandledException(
        'The report definition has an invalid source object.'
      );
    }
    return Schema.getGlobalDescribe().get(sourceObject);
  }

  private static String validateFieldPath(
    String path,
    Schema.SObjectType sourceType
  ) {
    if (
      String.isBlank(path) ||
      !Pattern.matches(
        '^[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*$',
        path
      )
    ) {
      throw new AuraHandledException(
        'The report definition contains an invalid field path.'
      );
    }
    List<String> segments = path.split('\\.');
    Schema.SObjectType currentType = sourceType;
    for (Integer i = 0; i < segments.size(); i++) {
      Map<String, Schema.SObjectField> fields = currentType.getDescribe()
        .fields.getMap();
      if (i == segments.size() - 1 && fields.containsKey(segments[i]))
        continue;
      Schema.DescribeFieldResult relationship;
      for (Schema.SObjectField candidate : fields.values()) {
        Schema.DescribeFieldResult candidateDescribe = candidate.getDescribe();
        if (candidateDescribe.getRelationshipName() == segments[i]) {
          relationship = candidateDescribe;
          break;
        }
      }
      if (relationship == null || relationship.getReferenceTo().isEmpty()) {
        throw new AuraHandledException(
          'The report definition contains an invalid relationship path.'
        );
      }
      currentType = relationship.getReferenceTo()[0];
    }
    return path;
  }

  private static String validateSelectExpression(
    String expression,
    Schema.SObjectType sourceType
  ) {
    Matcher aggregate = Pattern.compile(
        '^(SUM|MAX|MIN|AVG|COUNT)\\(([A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z_][A-Za-z0-9_]*)*)\\)(?:\\s+([A-Za-z_][A-Za-z0-9_]*))?$'
      )
      .matcher(expression);
    if (aggregate.matches())
      return aggregate.group(1) +
        '(' +
        validateFieldPath(aggregate.group(2), sourceType) +
        ')' +
        (aggregate.group(3) == null ? '' : ' ' + aggregate.group(3));
    Matcher field = Pattern.compile(
        '^([A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z_][A-Za-z0-9_]*)*)(?:\\s+([A-Za-z_][A-Za-z0-9_]*))?$'
      )
      .matcher(expression);
    if (!field.matches())
      throw new AuraHandledException(
        'The report definition contains an invalid select expression.'
      );
    return validateFieldPath(field.group(1), sourceType) +
      (field.group(2) == null ? '' : ' ' + field.group(2));
  }

  private static List<Object> deserializeList(String jsonText, String label) {
    if (String.isBlank(jsonText))
      return new List<Object>();
    try {
      return (List<Object>) JSON.deserializeUntyped(jsonText);
    } catch (Exception e) {
      throw new AuraHandledException(
        'The report ' + label + ' configuration is invalid.'
      );
    }
  }

  private static Map<String, Object> deserializeMap(
    String jsonText,
    String label
  ) {
    if (String.isBlank(jsonText))
      return new Map<String, Object>();
    try {
      return (Map<String, Object>) JSON.deserializeUntyped(jsonText);
    } catch (Exception e) {
      throw new AuraHandledException(
        'The report ' + label + ' configuration is invalid.'
      );
    }
  }

  private static List<FilterDefinition> deserializeFilters(
    String jsonText,
    String label
  ) {
    List<FilterDefinition> results = new List<FilterDefinition>();
    for (Object item : deserializeList(jsonText, label)) {
      Map<String, Object> values = (Map<String, Object>) item;
      FilterDefinition filter = new FilterDefinition();
      filter.key = (String) values.get('key');
      filter.field = (String) values.get('field');
      filter.operator = (String) values.get('operator');
      filter.value = values.get('value');
      filter.valueType = (String) values.get('valueType');
      results.add(filter);
    }
    return results;
  }

  private static List<SObject> takeFirst(List<SObject> source, Integer count) {
    List<SObject> results = new List<SObject>();
    for (Integer i = 0; i < count && i < source.size(); i++) {
      results.add(source[i]);
    }
    return results;
  }
}
