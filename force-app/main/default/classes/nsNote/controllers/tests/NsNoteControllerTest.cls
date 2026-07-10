@isTest
private class NsNoteControllerTest {
  @isTest
  static void saveNote_success() {
    NetSuiteClient.testResponse = new Map<String, Object>{
      'validRequest' => true,
      'responseJSON' => '{"status":"200","errors":[],"customObjectRecords":[{"internalId":"NOTE-9988"}]}'
    };

    String internalId = NsNoteController.saveNote(
      null,
      '145',
      'SO-991',
      'Customer requested a clasp inspection.'
    );

    System.assertEquals('NOTE-9988', internalId);
    NetSuiteClient.testResponse = null;
  }

  @isTest
  static void getNoteData_nullSalesOrderId() {
    Boolean didThrow = false;
    try {
      NsNoteController.getNoteData(null);
    } catch (AuraHandledException e) {
      didThrow = true;
    }

    System.assert(didThrow, 'Expected a missing sales order exception');
  }

  @isTest
  static void getNoteData_noNotes_returnsEmptyList() {
    breadwinner_ns__BW_Sales_Order__c salesOrder = new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__InternalId__c = 'SO-NOTE-EMPTY'
    );
    insert salesOrder;

    Test.startTest();
    List<NsNoteDataModel.NsNoteData> result = NsNoteController.getNoteData(
      salesOrder.Id
    );
    Test.stopTest();

    System.assertEquals(0, result.size());
  }

  @isTest
  static void getNoteData_success() {
    breadwinner_ns__BW_Sales_Order__c salesOrder = new breadwinner_ns__BW_Sales_Order__c(
      breadwinner_ns__InternalId__c = 'SO-NOTE-001'
    );
    insert salesOrder;

    insert new breadwinner_ns__BW_Employee__c(
      Name = 'Note Employee',
      breadwinner_ns__InternalId__c = 'EMP-NOTE-001'
    );

    insert new nco_notes_history__c(
      InternalId__c = 'NOTE-001',
      custrecord_note_history_author__c = 'EMP-NOTE-001',
      custrecord_note_history_transaction__c = 'SO-NOTE-001',
      custrecord_note_history_content__c = 'Note content',
      custrecord_note_history_lastmodifydate__c = Date.today()
    );

    Test.startTest();
    List<NsNoteDataModel.NsNoteData> result = NsNoteController.getNoteData(
      salesOrder.Id
    );
    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals('NOTE-001', result[0].internalId);
    System.assertEquals('EMP-NOTE-001', result[0].nsEmployeeId);
    System.assertEquals('Note Employee', result[0].nsEmployeeName);
    System.assertEquals('SO-NOTE-001', result[0].nsSoId);
    System.assertEquals('Note content', result[0].content);
  }
}
