public class IContactModels {
  public class IContactContact {
    public String contactId;
    public String firstName;
    public String lastName;
    public String email;
  }
  public class IContactResponse {
    public List<IContactContact> contacts;
  }
  public class ListPayload {
    public String name;
    public String description;
    public Integer emailOwnerOnChange;
  }
  public class IContactList {
    public String listId;
    public String name;
    public String description;
  }
  public class IContactListResponse {
    public List<IContactList> lists;
  }
  public class SubPayload {
    public String contactId;
    public String listId;
    public String status;
  }
}
