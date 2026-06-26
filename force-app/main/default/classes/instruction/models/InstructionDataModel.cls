public with sharing class InstructionDataModel {
  public class InstructionData {
    @AuraEnabled
    public String internalId;

    @AuraEnabled
    public String nsEmployeeId;

    @AuraEnabled
    public String nsEmployeeName;

    @AuraEnabled
    public String nsSoId;

    @AuraEnabled
    public String instruction;

    @AuraEnabled
    public Datetime lastModified;

    public InstructionData() {
    }
  }
}
