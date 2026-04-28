public class NetSuiteClient {
  public static Map<String, Object> call(Map<String, Object> payload) {
    return breadwinner_ns.BreadwinnerNetSuiteAPI.call(payload);
  }
}