public class ReportValueConverter {
  public static Object convert(Object value, String valueType) {
    if (value instanceof List<Object>) {
      return convertList((List<Object>) value, valueType);
    }

    return convertSingle(value, valueType);
  }

  private static Object convertList(List<Object> values, String valueType) {
    String normalizedType = String.isBlank(valueType)
      ? 'string'
      : valueType.trim().toLowerCase();

    switch on normalizedType {
      when 'date' {
        List<Date> result = new List<Date>();
        for (Object value : values)
          result.add(Date.valueOf(String.valueOf(value)));
        return result;
      }
      when 'datetime' {
        List<Datetime> result = new List<Datetime>();
        for (Object value : values)
          result.add(Datetime.valueOf(String.valueOf(value)));
        return result;
      }
      when 'integer' {
        List<Integer> result = new List<Integer>();
        for (Object value : values)
          result.add(Integer.valueOf(String.valueOf(value)));
        return result;
      }
      when 'long' {
        List<Long> result = new List<Long>();
        for (Object value : values)
          result.add(Long.valueOf(String.valueOf(value)));
        return result;
      }
      when 'decimal', 'currency', 'percent' {
        List<Decimal> result = new List<Decimal>();
        for (Object value : values)
          result.add(Decimal.valueOf(String.valueOf(value)));
        return result;
      }
      when 'boolean' {
        List<Boolean> result = new List<Boolean>();
        for (Object value : values)
          result.add((Boolean) convertSingle(value, normalizedType));
        return result;
      }
      when 'id', 'string' {
        List<String> result = new List<String>();
        for (Object value : values)
          result.add(String.valueOf(value));
        return result;
      }
      when else {
        throw new AuraHandledException(
          'Unsupported report filter value type: ' + valueType
        );
      }
    }
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
          throw new AuraHandledException(
            'Invalid Boolean report filter value.'
          );
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
