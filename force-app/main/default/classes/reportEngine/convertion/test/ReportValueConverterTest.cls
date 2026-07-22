@IsTest
private class ReportValueConverterTest {
  @IsTest
  static void convertsUntypedStringListToTypedStringList() {
    List<Object> values = new List<Object>{ 'Closed', 'Billed' };

    Object converted = ReportValueConverter.convert(values, null);

    System.assert(converted instanceof List<String>);
    System.assertEquals(
      new List<String>{ 'Closed', 'Billed' },
      (List<String>) converted
    );
  }

  @IsTest
  static void convertsTypedListsToTheirConfiguredType() {
    Object converted = ReportValueConverter.convert(
      new List<Object>{ '2026-07-22' },
      'Date'
    );

    System.assert(converted instanceof List<Date>);
    System.assertEquals(
      new List<Date>{ Date.newInstance(2026, 7, 22) },
      converted
    );
  }
}
