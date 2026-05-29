public with sharing class CustomerResModel {
  public class ResponseJson {
    public String status;
    public List<ErrorDetail> errors;
    public List<Customer> customers;

    public ResponseJson() {}
  }

  public class ErrorDetail {
    public String code;
    public String message;
    public String detail;
    public String field;
    public String type;

    public ErrorDetail() {}
  }

  public class customer {
    public String internalId;

    public customer() {}
  }
}
