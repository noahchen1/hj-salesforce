public with sharing class SalesOrderResHandler {
  public static SalesOrderDataModel.SalesOrderData handleResponse(
    Map<String, Object> response
  ) {
    SalesOrderValidator.validateRawResponse(response);

    String jsonStr = extractJson(response);

    SalesOrderResModel.ResponseJson parsed = (SalesOrderResModel.ResponseJson) JSON.deserialize(
      jsonStr,
      SalesOrderResModel.ResponseJson.class
    );

    SalesOrderValidator.validateTypedBody(parsed);

    SalesOrderResModel.SalesOrder so = parsed.salesOrders[0];

    return SalesOrderMapper.mapSalesOrder(so);
  }

  private static String extractJson(Map<String, Object> response) {
    Object raw = response.get('responseJSON');

    return raw instanceof String ? (String) raw : JSON.serialize(raw);
  }
}
