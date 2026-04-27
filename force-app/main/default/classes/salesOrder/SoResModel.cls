public class SoResModel {
  public class ResponseJson {
    public String status;
    public List<Object> errors;
    public List<SalesOrder> salesOrders;
  }

  public class SalesOrder {
    public String internalId;
    public Long tranDate;
    public String memo;
    public RecordRef entity;
    public RecordRef salesRep;
    public RecordRef subsidiary;
    public RecordRef location;
    public ItemList itemList;
    public CustomFieldList customFieldList;
  }

  public class ItemList {
    public List<SalesOrderItem> item;
  }

  public class SalesOrderItem {
    public RecordRef item;
    public Decimal quantity;
    public String rate;
    public Decimal amount;
    public String line;
  }

  public class CustomFieldList {
    public List<CustomField> customField;
  }

  public class CustomField {
    public String scriptId;
    public String value;
    public RecordRef valueLookup;
  }

  public class RecordRef {
    public String name;
    public String internalId;
  }
}
