public class NetSuiteClient {
  @TestVisible
  private static Map<String, Object> testResponse;

  public static Map<String, Object> call(Map<String, Object> payload) {
    if (Test.isRunningTest() && testResponse != null) {
      return testResponse;
    }

    return breadwinner_ns.BreadwinnerNetSuiteAPI.call(payload);
  }
}
