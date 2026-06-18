public with sharing class NsFileResModel {
  public class ResponseJson {
    public String status;
    public List<ErrorDetail> errors;
    public String fileInternalId;

    public ResponseJson() {
    }
  }

  public class ErrorDetail {
    public String code;
    public String message;
    public String detail;
    public String field;
    public String type;

    public ErrorDetail() {
    }
  }
}
