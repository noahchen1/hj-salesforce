public with sharing class CommentDataModel {
  public class CommentData {
    @AuraEnabled
    public String internalId;

    @AuraEnabled
    public String nsEmployeeId;

    @AuraEnabled
    public String nsSoId;

    @AuraEnabled
    public String comment;

    @AuraEnabled
    public String lastModified;

    public CommentData() {
    }
  }
}
