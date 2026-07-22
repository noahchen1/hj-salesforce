public class ReportConfigBuilder {
  public static ReportModels.ParsedFilterDefinition parse(
    ReportDefinitions.Definition source
  ) {
    ReportModels.ParsedFilterDefinition result = new ReportModels.ParsedFilterDefinition();

    result.sourceObject = source.sourceObject;
    result.isActive = source.isActive;
    result.selectExpressions = parseStringList(
      source.selectFieldsJson,
      'select fields'
    );
    result.baseFilters = parseFilters(source.baseFiltersJson, 'base filters');
    result.runtimeFilters = parseFilters(
      source.runtimeFiltersJson,
      'runtime filters'
    );
    result.groupByFields = parseStringList(
      source.groupByFieldsJson,
      'group by fields'
    );
    result.sortFields = parseStringMap(source.sortFieldsJson, 'sort fields');
    result.defaultSort = source.defaultSort;

    return result;
  }

  private static List<String> parseStringList(String jsonText, String label) {
    List<String> result = new List<String>();

    for (Object value : deserializeList(jsonText, label)) {
      result.add(String.valueOf(value));
    }

    return result;
  }

  private static Map<String, String> parseStringMap(
    String jsonText,
    String label
  ) {
    Map<String, String> result = new Map<String, String>();

    for (String key : deserializeMap(jsonText, label).keySet()) {
      result.put(key, String.valueOf(deserializeMap(jsonText, label).get(key)));
    }

    return result;
  }

  private static List<ReportModels.FilterDefinition> parseFilters(
    String jsonText,
    String label
  ) {
    List<ReportModels.FilterDefinition> result = new List<ReportModels.FilterDefinition>();

    for (Object item : deserializeList(jsonText, label)) {
      Map<String, Object> values = (Map<String, Object>) item;

      ReportModels.FilterDefinition filter = new ReportModels.FilterDefinition();

      filter.key = (String) values.get('key');
      filter.field = (String) values.get('field');
      filter.operator = (String) values.get('operator');
      filter.value = values.get('value');
      filter.valueType = (String) values.get('valueType');

      result.add(filter);
    }

    return result;
  }

  private static List<Object> deserializeList(String jsonText, String label) {
    if (String.isBlank(jsonText)) {
      return new List<Object>();
    }

    try {
      return (List<Object>) JSON.deserializeUntyped(jsonText);
    } catch (Exception e) {
      throw invalidConfiguration(label);
    }
  }

  private static Map<String, Object> deserializeMap(
    String jsonText,
    String label
  ) {
    if (String.isBlank(jsonText)) {
      return new Map<String, Object>();
    }

    try {
      return (Map<String, Object>) JSON.deserializeUntyped(jsonText);
    } catch (Exception e) {
      throw invalidConfiguration(label);
    }
  }

  private static AuraHandledException invalidConfiguration(String label) {
    return new AuraHandledException(
      'The report ' + label + ' configuration is invalid.'
    );
  }
}
