public with sharing class InstructionService {
  public static String saveInstruction(
    String nsInternalId,
    String nsEmployeeId,
    String nsSoId,
    String instruction
  ) {
    InstructionValidator.validateSaveRequest(nsEmployeeId, nsSoId, instruction);
    Boolean isUpdate = String.isNotBlank(nsInternalId);

    Map<String, Object> instructionRequest = InstructionPayloadBuilder.buildSaveRequest(
      nsInternalId,
      nsEmployeeId,
      nsSoId,
      instruction
    );

    Map<String, Object> requestPayload = InstructionPayloadBuilder.buildSavePayload(
      instructionRequest,
      isUpdate
    );

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.saveInstruction request: ' +
      JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.saveInstruction response: ' + JSON.serialize(response)
    );

    InstructionDataModel.InstructionData instructionData = InstructionResHandler.handleResponse(
      response
    );

    return instructionData.internalId;
  }

  public static List<InstructionDataModel.InstructionData> getInstructionData(
    Id salesOrderId
  ) {
    if (salesOrderId == null) {
      throw new AuraHandledException('Sales order Id is required.');
    }

    List<nco_repair_instructions__c> instructionRows = [
      SELECT
        InternalId__c,
        OwnerName__c,
        nid_record1__c,
        custrecord_instruction_comment__c,
        LastModified__c
      FROM nco_repair_instructions__c
      WHERE ncl_record1__c = :salesOrderId
    ];

    if (instructionRows.isEmpty()) {
      return new List<InstructionDataModel.InstructionData>();
    }

    Set<String> ownerNames = new Set<String>();

    for (nco_repair_instructions__c row : instructionRows) {
      if (String.isNotBlank(row.OwnerName__c)) {
        ownerNames.add(row.OwnerName__c);
      }
    }

    Map<String, breadwinner_ns__BW_Employee__c> employeesByName = new Map<String, breadwinner_ns__BW_Employee__c>();

    for (breadwinner_ns__BW_Employee__c employee : [
      SELECT breadwinner_ns__InternalId__c, Name
      FROM breadwinner_ns__BW_Employee__c
      WHERE Name = :ownerNames
    ]) {
      employeesByName.put(employee.Name, employee);
    }

    List<InstructionDataModel.InstructionData> instructionData = new List<InstructionDataModel.InstructionData>();

    for (nco_repair_instructions__c row : instructionRows) {
      breadwinner_ns__BW_Employee__c employee = employeesByName.get(
        row.OwnerName__c
      );

      if (employee == null) {
        throw new AuraHandledException(
          'Could not find NetSuite employee: ' + row.OwnerName__c
        );
      }

      InstructionDataModel.InstructionData data = new InstructionDataModel.InstructionData();

      data.internalId = row.InternalId__c;
      data.nsEmployeeId = employee.breadwinner_ns__InternalId__c;
      data.nsEmployeeName = employee.Name;
      data.nsSoId = row.nid_record1__c;
      data.instruction = row.custrecord_instruction_comment__c;
      data.lastModified = row.LastModified__c;

      instructionData.add(data);
    }

    return instructionData;
  }
}
