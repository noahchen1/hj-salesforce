public with sharing class InstructionResModel {
  public class ResponseJson {
    public String status;
    public List<ErrorDetail> errors;
    public List<InstructionRecord> customObjectRecords;

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

  public class InstructionRecord {
    public String internalId;
    public OwnerRef owner;
    public CustomFieldList customFieldList;

    public InstructionRecord() {
    }
  }

  public class OwnerRef {
    public String internalId;
    public String name;

    public OwnerRef() {
    }
  }

  public class CustomFieldList {
    public List<CustomField> customField;

    public CustomFieldList() {
    }
  }

  public class CustomField {
    public String scriptId;
    public String value;
    public ValueLookup valueLookup;

    public CustomField() {
    }
  }

  public class ValueLookup {
    public String internalId;
    public String name;

    public ValueLookup() {
    }
  }
}
