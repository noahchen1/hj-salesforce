public with sharing class NsNoteService {
  public static String saveNote(
    String nsEmployeeId,
    String nsSoId,
    String content
  ) {
    NsNoteValidator.validateSaveRequest(nsEmployeeId, nsSoId, content);

    Map<String, Object> noteReqeust = NsNotePayloadBuilder.buildSaveRequest(
      nsEmployeeId,
      nsSoId,
      content
    );

    Map<String, Object> requestPayload = NsNotePayloadBuilder.buildSavePayload(
      noteReqeust
    );

    System.debug(
      LoggingLevel.INFO,
      'NsNoteService.saveNote request: ' + JSON.serialize(requestPayload)
    );

    Map<String, Object> response = NetSuiteClient.call(requestPayload);

    System.debug(
      LoggingLevel.INFO,
      'InstructionService.saveInstruction response: ' + JSON.serialize(response)
    );

    NsNoteDataModel.NsNoteData noteData = NsNoteResHandler.handleResponse(
      response
    );

    return noteData.internalId;
  }

  public static List<NsNoteDataModel.NsNoteData> getNoteData(Id salesOrderId) {
    if (salesOrderId == null) {
      throw new AuraHandledException('Sales order Id is required.');
    }

    List<breadwinner_ns__BW_Sales_Order__c> orderRows = [
      SELECT breadwinner_ns__InternalId__c
      FROM breadwinner_ns__BW_Sales_Order__c
      WHERE Id = :salesOrderId
      LIMIT 1
    ];

    if (
      orderRows.isEmpty() ||
      String.isBlank(orderRows[0].breadwinner_ns__InternalId__c)
    ) {
      throw new AuraHandledException('Could not locate existing order.');
    }

    String soNsInternalId = orderRows[0].breadwinner_ns__InternalId__c;

    List<nco_notes_history__c> noteRows = [
      SELECT
        InternalId__c,
        custrecord_note_history_author__c,
        custrecord_note_history_transaction__c,
        custrecord_note_history_content__c,
        custrecord_note_history_lastmodifydate__c
      FROM nco_notes_history__c
      WHERE InternalId__c = '2401394'
    ];

    if (noteRows.isEmpty()) {
      throw new AuraHandledException('Could not find related notes');
    }

    Set<String> employeeIds = new Set<String>();

    for (nco_notes_history__c row : noteRows) {
      if (String.isNotBlank(row.custrecord_note_history_author__c)) {
        employeeIds.add(row.custrecord_note_history_author__c);
      }
    }

    Map<String, breadwinner_ns__BW_Employee__c> employeesByInternalId = new Map<String, breadwinner_ns__BW_Employee__c>();

    for (breadwinner_ns__BW_Employee__c employee : [
      SELECT breadwinner_ns__InternalId__c, Name
      FROM breadwinner_ns__BW_Employee__c
      WHERE breadwinner_ns__InternalId__c IN :employeeIds
    ]) {
      employeesByInternalId.put(employee.breadwinner_ns__InternalId__c, employee);
    }

    List<NsNoteDataModel.NsNoteData> noteData = new List<NsNoteDataModel.NsNoteData>();

    for (nco_notes_history__c row : noteRows) {
      breadwinner_ns__BW_Employee__c employee = employeesByInternalId.get(
        row.custrecord_note_history_author__c
      );

      if (employee == null) {
        throw new AuraHandledException(
          'Could not find NetSuite employee: ' +
          row.custrecord_note_history_author__c
        );
      }

      NsNoteDataModel.NsNoteData data = new NsNoteDataModel.NsNoteData();

      data.internalId = row.InternalId__c;
      data.nsEmployeeId = employee.breadwinner_ns__InternalId__c;
      data.nsEmployeeName = employee.Name;
      data.nsSoId = row.custrecord_note_history_transaction__c;
      data.content = row.custrecord_note_history_content__c;
      data.lastModified = row.custrecord_note_history_lastmodifydate__c;

      noteData.add(data);
    }

    return noteData;
  }
}
