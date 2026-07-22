public class ReportValueConverter {
  public static Object convert(Object value, String valueType) {
    if (value instanceof List<Object>) {
      return convertList((List<Object>) value, valueType);
    }

    return convertSingle(value, valueType);
  }

  private static List<Object> convertList(
    List<Object> values,
    String valueType
  ) {
    List<Object> result = new List<Object>();

    for (Object value : values) {
      result.add(convertSingle(value, valueType));
    }

    return result;
  }

  private static Object convertSingle(Object value, String valueType) {
    if (value == null || String.isBlank(valueType)) {
      return value;
    }

    switch on valueType.trim().toLowerCase() {
      when 'date' {
        return Date.valueOf(String.valueOf(value));
      }
      when 'datetime' {
        return Datetime.valueOf(String.valueOf(value));
      }
      when 'integer' {
        return Integer.valueOf(String.valueOf(value));
      }
      when 'long' {
        return Long.valueOf(String.valueOf(value));
      }
      when 'decimal', 'currency', 'percent' {
        return Decimal.valueOf(String.valueOf(value));
      }
      when 'boolean' {
        String normalized = String.valueOf(value).toLowerCase();

        if (normalized != 'true' && normalized != 'false') {
          throw new AuraHandledException('Invalid Boolean report filter value.');
        }

        return normalized == 'true';
      }
      when 'id', 'string' {
        return String.valueOf(value);
      }
      when else {
        throw new AuraHandledException(
          'Unsupported report filter value type: ' + valueType
        );
      }
    }
  }
}
