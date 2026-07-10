public with sharing class CommentResModel {
  public class ResponseJson {
    public String status;
    public List<ErrorDetail> errors;
    public List<CommentRecord> customObjectRecords;

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

  public class CommentRecord {
    public String internalId;
    public OwnerRef owner;
    public CustomFieldList customFieldList;

    public CommentRecord() {
    }
  }

  public class OwnerRef {
    public String internalId;
    public String name;
  }

  public class CustomFieldList {
    public List<CustomField> customField;
  }

  public class CustomField {
    public String scriptId;
    public String value;
    public ValueLookup valueLookup;
  }

  public class ValueLookup {
    public String internalId;
    public String name;
  }
}
