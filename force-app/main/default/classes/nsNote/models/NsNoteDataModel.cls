public with sharing class NsNoteDataModel {
  public class NsNoteData {
    @AuraEnabled
    public String internalId;

    @AuraEnabled
    public String nsEmployeeId;

    @AuraEnabled
    public String nsEmployeeName;

    @AuraEnabled
    public String nsSoId;

    @AuraEnabled
    public String content;

    @AuraEnabled
    public Date lastModified;

    public NsNoteData() {
    }
  }
}
