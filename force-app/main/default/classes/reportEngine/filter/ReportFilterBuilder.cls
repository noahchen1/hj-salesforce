public class ReportFilterBuilder {
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

  public static void addFilters(
    List<String> whereParts,
    Map<String, Object> binds,
    List<ReportModels.FilterDefinition> definitions,
    Map<String, Object> values,
    Schema.SObjectType sourceType,
    String prefix
  ) {
    for (ReportModels.FilterDefinition definition : definitions) {
      addFilter(whereParts, binds, definition, values, sourceType, prefix);
    }
  }

  private static void addFilter(
    List<String> whereParts,
    Map<String, Object> binds,
    ReportModels.FilterDefinition definition,
    Map<String, Object> values,
    Schema.SObjectType sourceType,
    String prefix
  ) {
    validateDefinition(definition);

    String operator = definition.operator.trim().toUpperCase();

    String field = ReportValidator.validateFieldPath(
      definition.field,
      sourceType
    );

    if (operator == 'IS NULL' || operator == 'IS NOT NULL') {
      whereParts.add(field + ' ' + operator);
      return;
    }

    Object value = resolveValue(definition, values);

    if (isEmpty(value)) {
      return;
    }

    validateOperatorValue(operator, value);

    String bindName = prefix + '_' + String.valueOf(binds.size());

    binds.put(
      bindName,
      ReportValueConverter.convert(value, definition.valueType)
    );

    whereParts.add(field + ' ' + operator + ' :' + bindName);
  }

  private static Object resolveValue(
    ReportModels.FilterDefinition definition,
    Map<String, Object> values
  ) {
    return String.isBlank(definition.key)
      ? definition.value
      : values.get(definition.key);
  }

  private static Boolean isEmpty(Object value) {
    return value == null ||
      (value instanceof String && String.isBlank((String) value));
  }

  private static void validateDefinition(
    ReportModels.FilterDefinition definition
  ) {
    if (
      definition == null ||
      String.isBlank(definition.field) ||
      String.isBlank(definition.operator)
    ) {
      throw new AuraHandledException('A report filter is incomplete.');
    }

    String operator = definition.operator.trim().toUpperCase();

    if (!ALLOWED_OPERATORS.contains(operator)) {
      throw new AuraHandledException('A report filter uses an invalid operator.');
    }
  }

  private static void validateOperatorValue(String operator, Object value) {
    Boolean listOperator = operator == 'IN' || operator == 'NOT IN';

    if (listOperator && !(value instanceof List<Object>)) {
      throw new AuraHandledException(operator + ' requires a list value.');
    }
  }
}
