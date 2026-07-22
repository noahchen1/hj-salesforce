public class ReportValidator {
  private static final Pattern FIELD_PATH_PATTERN = Pattern.compile(
    '^[A-Za-z_][A-Za-z0-9_]*' + '(\\.[A-Za-z_][A-Za-z0-9_]*)*$'
  );

  private static final Pattern AGGREGATE_PATTERN = Pattern.compile(
    '^(SUM|MAX|MIN|AVG|COUNT)\\(' +
      '([A-Za-z_][A-Za-z0-9_]*' +
      '(?:\\.[A-Za-z_][A-Za-z0-9_]*)*)' +
      '\\)' +
      '(?:\\s+([A-Za-z_][A-Za-z0-9_]*))?$'
  );

  private static final Pattern SELECT_FIELD_PATTERN = Pattern.compile(
    '^([A-Za-z_][A-Za-z0-9_]*' +
      '(?:\\.[A-Za-z_][A-Za-z0-9_]*)*)' +
      '(?:\\s+([A-Za-z_][A-Za-z0-9_]*))?$'
  );

  public static Schema.SObjectType getObjectType(String objectApiName) {
    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    if (
      String.isBlank(objectApiName) ||
      !globalDescribe.containsKey(objectApiName)
    ) {
      throw new AuraHandledException(
        'The report definition has an invalid source object.'
      );
    }

    return globalDescribe.get(objectApiName);
  }

  public static String validateFieldPath(
    String path,
    Schema.SObjectType sourceType
  ) {
    if (String.isBlank(path) || !FIELD_PATH_PATTERN.matcher(path).matches()) {
      throw new AuraHandledException(
        'The report definition contains an invalid field path.'
      );
    }

    List<String> segments = path.split('\\.');
    Schema.SObjectType currentType = sourceType;

    for (Integer index = 0; index < segments.size(); index++) {
      String segment = segments[index];

      Map<String, Schema.SObjectField> fields = currentType.getDescribe()
        .fields.getMap();

      Boolean isLast = index == segments.size() - 1;

      if (isLast && fields.containsKey(segment)) {
        continue;
      }

      Schema.DescribeFieldResult relationship = findRelationship(
        fields,
        segment
      );

      if (relationship == null || relationship.getReferenceTo().isEmpty()) {
        throw new AuraHandledException(
          'The report definition contains an invalid ' + 'relationship path.'
        );
      }

      currentType = relationship.getReferenceTo()[0];
    }

    return path;
  }

  public static String validateSelectExpression(
    String expression,
    Schema.SObjectType sourceType
  ) {
    Matcher aggregate = AGGREGATE_PATTERN.matcher(expression);

    if (aggregate.matches()) {
      String alias = aggregate.group(3);

      return aggregate.group(1) +
        '(' +
        validateFieldPath(aggregate.group(2), sourceType) +
        ')' +
        (alias == null ? '' : ' ' + alias);
    }

    Matcher field = SELECT_FIELD_PATTERN.matcher(expression);

    if (!field.matches()) {
      throw new AuraHandledException(
        'The report definition contains an invalid ' + 'select expression.'
      );
    }

    String alias = field.group(2);

    return validateFieldPath(field.group(1), sourceType) +
      (alias == null ? '' : ' ' + alias);
  }

  private static Schema.DescribeFieldResult findRelationship(
    Map<String, Schema.SObjectField> fields,
    String relationshipName
  ) {
    for (Schema.SObjectField candidate : fields.values()) {
      Schema.DescribeFieldResult describe = candidate.getDescribe();

      if (describe.getRelationshipName() == relationshipName) {
        return describe;
      }
    }

    return null;
  }
}
