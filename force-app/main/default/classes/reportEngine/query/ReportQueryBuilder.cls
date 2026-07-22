public class ReportQueryBuilder {
  public static ReportModels.QuerySpec build(
    ReportModels.ParsedFilterDefinition definition,
    Map<String, Object> runtimeValues,
    Integer limitSize,
    Integer offsetSize,
    String sortBy,
    String sortDirection
  ) {
    Schema.SObjectType sourceType = ReportValidator.getObjectType(
      definition.sourceObject
    );

    List<String> selectedFields = buildSelectFields(
      definition.selectExpressions,
      sourceType
    );

    Map<String, Object> binds = new Map<String, Object>();

    List<String> whereParts = new List<String>();

    ReportFilterBuilder.addFilters(
      whereParts,
      binds,
      definition.baseFilters,
      new Map<String, Object>(),
      sourceType,
      'base'
    );

    ReportFilterBuilder.addFilters(
      whereParts,
      binds,
      definition.runtimeFilters,
      runtimeValues,
      sourceType,
      'runtime'
    );

    List<String> queryParts = new List<String>{
      'SELECT ' + String.join(selectedFields, ', '),
      'FROM ' + definition.sourceObject
    };

    if (!whereParts.isEmpty()) {
      queryParts.add('WHERE ' + String.join(whereParts, ' AND '));
    }

    String groupByClause = buildGroupByClause(
      definition.groupByFields,
      sourceType
    );

    if (String.isNotBlank(groupByClause)) {
      queryParts.add(groupByClause);
    }

    String orderByClause = buildOrderByClause(
      definition,
      sourceType,
      sortBy,
      sortDirection
    );

    if (String.isNotBlank(orderByClause)) {
      queryParts.add(orderByClause);
    }

    binds.put('limitSize', limitSize);
    binds.put('offsetSize', offsetSize);

    queryParts.add('LIMIT :limitSize OFFSET :offsetSize');

    return new ReportModels.QuerySpec(String.join(queryParts, ' '), binds);
  }

  private static List<String> buildSelectFields(
    List<String> expressions,
    Schema.SObjectType sourceType
  ) {
    if (expressions.isEmpty()) {
      throw new AuraHandledException(
        'The report definition has no selected fields.'
      );
    }

    List<String> result = new List<String>();

    for (String expression : expressions) {
      result.add(
        ReportValidator.validateSelectExpression(expression, sourceType)
      );
    }

    return result;
  }

  private static String buildGroupByClause(
    List<String> configuredFields,
    Schema.SObjectType sourceType
  ) {
    if (configuredFields.isEmpty()) {
      return null;
    }

    List<String> validatedFields = new List<String>();

    for (String field : configuredFields) {
      validatedFields.add(
        ReportValidator.validateFieldPath(field, sourceType)
      );
    }

    return 'GROUP BY ' + String.join(validatedFields, ', ');
  }

  private static String buildOrderByClause(
    ReportModels.ParsedFilterDefinition definition,
    Schema.SObjectType sourceType,
    String sortBy,
    String sortDirection
  ) {
    String expression = definition.sortFields.containsKey(sortBy)
      ? definition.sortFields.get(sortBy)
      : definition.defaultSort;

    if (String.isBlank(expression)) {
      return null;
    }

    String direction = 'asc'.equalsIgnoreCase(sortDirection) ? 'ASC' : 'DESC';

    return 'ORDER BY ' +
      ReportValidator.validateSelectExpression(expression, sourceType) +
      ' ' +
      direction +
      ' NULLS LAST';
  }
}
