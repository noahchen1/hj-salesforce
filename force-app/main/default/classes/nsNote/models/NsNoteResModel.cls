public with sharing class NsNoteResModel {
  public class ResponseJson {
    public String status;
    public List<ErrorDetail> errors;
    public List<NoteRecord> customObjectRecords;
  }

  public class ErrorDetail {
    public String code;
    public String message;
    public String detail;
    public String field;
    public String type;
  }

  public class NoteRecord {
    public String internalId;
    public CustomFieldList customFieldList;
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
