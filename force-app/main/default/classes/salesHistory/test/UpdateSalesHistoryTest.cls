@isTest
private class UpdateSalesHistoryTest {
  private static List<breadwinner_ns__BW_Line_Item__c> getLineItems(Id lineId) {
    return [
      SELECT
        Id,
        Name,
        breadwinner_ns__Invoice__r.Name,
        breadwinner_ns__Credit_Memo__r.Name,
        breadwinner_ns__Invoice__r.breadwinner_ns__SalesRepName__c,
        breadwinner_ns__Credit_Memo__r.breadwinner_ns__SalesRepName__c,
        breadwinner_ns__Invoice__r.ncf_body_salesrep2__c,
        breadwinner_ns__Credit_Memo__r.ncf_body_salesrep2__c,
        breadwinner_ns__Invoice__r.breadwinner_ns__Entity__c,
        breadwinner_ns__Credit_Memo__r.breadwinner_ns__Entity__c,
        breadwinner_ns__ParentSalesforceAccount__c,
        breadwinner_ns__Amount__c,
        Amount_after_Discounts__c,
        breadwinner_ns__Item__c,
        breadwinner_ns__Item__r.Name,
        breadwinner_ns__Item__r.breadwinner_ns__Cost__c,
        breadwinner_ns__ClassName__c,
        breadwinner_ns__Item__r.breadwinner_ns__ClassName__c,
        Item_Merchandise_Department__c,
        breadwinner_ns__Item__r.ncf_item_psgss_merc_dept__c,
        Item_Group_Code__c,
        breadwinner_ns__Item__r.ncf_item_groupcode__c,
        breadwinner_ns__Item__r.Base_Price__c,
        breadwinner_ns__CostEstimate__c,
        breadwinner_ns__Quantity__c,
        breadwinner_ns__ParentTransDate__c,
        breadwinner_ns__LocationName__c,
        breadwinner_ns__Item__r.ncf_item9__c,
        breadwinner_ns__Item__r.breadwinner_ns__VendorName__c,
        breadwinner_ns__Transaction_Type__c
      FROM breadwinner_ns__BW_Line_Item__c
      WHERE Id = :lineId
    ];
  }

  private static List<nco_aschistoricalsales__c> getAscHistoryItems(Id itemId) {
    return [
      SELECT
        Id,
        Name,
        custrecord_aschassociate1__c,
        custrecord_aschassociate2__c,
        Account__c,
        NetSuite_Company__c,
        custrecord_aschitempricepaid__c,
        NetSuite_Item__c,
        custrecord_aschsku__c,
        custrecord_aschtitemcost__c,
        custrecord_aschitemdivision__c,
        custrecord_aschitemdepartment__c,
        custrecord_aschitemgroupcode__c,
        custrecord_aschitemretail__c,
        custrecord_aschitemqty__c,
        custrecord_aschorderdate__c,
        custrecord_aschstore__c,
        custrecord_aschvendor__c,
        custrecord_aschvendoritemnum__c
      FROM nco_aschistoricalsales__c
      WHERE Id = :itemId
    ];
  }

  @isTest
  static void testIsValidTransactionTypeWithInvoice() {
    System.assert(UpdateSalesHistory.isValidTransactionType('Invoice'));
  }

  @isTest
  static void testIsValidTransactionTypeWithCashSale() {
    System.assert(UpdateSalesHistory.isValidTransactionType('CashSale'));
  }

  @isTest
  static void testIsValidTransactionTypeWithCashRefund() {
    System.assert(UpdateSalesHistory.isValidTransactionType('CashRefund'));
  }

  @isTest
  static void testIsValidTransactionTypeWithCreditMemo() {
    System.assert(UpdateSalesHistory.isValidTransactionType('CreditMemo'));
  }

  @isTest
  static void testIsValidTransactionTypeWithNull() {
    System.assert(!UpdateSalesHistory.isValidTransactionType(null));
  }

  @isTest
  static void testIsValidTransactionTypeWithBlank() {
    System.assert(!UpdateSalesHistory.isValidTransactionType(''));
  }

  @isTest
  static void testGetUpdatesFromNsLineItemsWithNull() {
    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromNsLineItems(
      null
    );

    System.assertNotEquals(null, result);
    System.assertEquals(0, result.get('toInsert').size());
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromNsLineItemsWithNoReps() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Invoice__c invoice = new breadwinner_ns__BW_Invoice__c(
      Name = 'INV-001'
    );
    insert invoice;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line Item',
      breadwinner_ns__Transaction_Type__c = 'Invoice',
      breadwinner_ns__Invoice__c = invoice.Id
    );

    insert lineItem;

    List<breadwinner_ns__BW_Line_Item__c> lineItems = getLineItems(lineItem.Id);

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromNsLineItems(
      lineItems
    );

    System.assertEquals(
      1,
      result.get('toInsert').size(),
      'Should create 1 Sales_History record with no reps'
    );
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromNsLineItemsWithOneReps() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Invoice__c invoice = new breadwinner_ns__BW_Invoice__c(
      Name = 'INV-001',
      breadwinner_ns__SalesRepName__c = 'Test Rep'
    );
    insert invoice;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line Item',
      breadwinner_ns__Transaction_Type__c = 'Invoice',
      breadwinner_ns__Invoice__c = invoice.Id
    );

    insert lineItem;

    List<breadwinner_ns__BW_Line_Item__c> lineItems = getLineItems(lineItem.Id);

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromNsLineItems(
      lineItems
    );

    System.assertEquals(
      1,
      result.get('toInsert').size(),
      'Should create 1 Sales_History record with One rep'
    );
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromNsLineItemsWithTwoReps() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Invoice__c invoice = new breadwinner_ns__BW_Invoice__c(
      Name = 'INV-001',
      breadwinner_ns__SalesRepName__c = 'Test Rep',
      ncf_body_salesrep2__c = 'Test Rep 2'
    );
    insert invoice;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line Item',
      breadwinner_ns__Transaction_Type__c = 'Invoice',
      breadwinner_ns__Invoice__c = invoice.Id
    );

    insert lineItem;

    List<breadwinner_ns__BW_Line_Item__c> lineItems = getLineItems(lineItem.Id);

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromNsLineItems(
      lineItems
    );

    System.assertEquals(
      2,
      result.get('toInsert').size(),
      'Should create 1 Sales_History record with One rep'
    );
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromNsLineItemsWithExistingSalesHistory() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    breadwinner_ns__BW_Invoice__c invoice = new breadwinner_ns__BW_Invoice__c(
      Name = 'INV-001',
      breadwinner_ns__SalesRepName__c = 'Test Rep'
    );
    insert invoice;

    breadwinner_ns__BW_Line_Item__c lineItem = new breadwinner_ns__BW_Line_Item__c(
      Name = 'Test Line Item',
      breadwinner_ns__Transaction_Type__c = 'Invoice',
      breadwinner_ns__Invoice__c = invoice.Id
    );

    insert lineItem;

    List<breadwinner_ns__BW_Line_Item__c> lineItems = getLineItems(lineItem.Id);

    Sales_History__c salesHistory = new Sales_History__c(
      Name = 'Test Sales History',
      Source__c = 'NS',
      Source_Id__c = String.valueOf(lineItem.Id) + '_1',
      NetSuite_Line_Item__c = lineItem.Id
    );

    insert salesHistory;

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromNsLineItems(
      lineItems
    );

    System.assertEquals(0, result.get('toInsert').size());
    System.assertEquals(1, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromAscHistoryWithNull() {
    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromAscHistory(
      null
    );

    System.assertNotEquals(null, result);
    System.assertEquals(0, result.get('toInsert').size());
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromAscHistoryWithNoReps() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c ascItem = new nco_aschistoricalsales__c(
      Name = 'ASC-001',
      Account__c = acct.Id,
      custrecord_aschitempricepaid__c = 100,
      custrecord_aschitemqty__c = 5
    );
    insert ascItem;

    List<nco_aschistoricalsales__c> ascItems = getAscHistoryItems(ascItem.Id);

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromAscHistory(
      ascItems
    );

    System.assertEquals(
      1,
      result.get('toInsert').size(),
      'Should create 1 Sales_History record with no reps'
    );
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromAscHistoryWithOneRep() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c ascItem = new nco_aschistoricalsales__c(
      Name = 'ASC-002',
      Account__c = acct.Id,
      custrecord_aschassociate1__c = 'Test Rep',
      custrecord_aschitempricepaid__c = 100,
      custrecord_aschitemqty__c = 5
    );
    insert ascItem;

    List<nco_aschistoricalsales__c> ascItems = getAscHistoryItems(ascItem.Id);

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromAscHistory(
      ascItems
    );

    System.assertEquals(
      1,
      result.get('toInsert').size(),
      'Should create 1 Sales_History record with one rep'
    );
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromAscHistoryWithTwoReps() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c ascItem = new nco_aschistoricalsales__c(
      Name = 'ASC-003',
      Account__c = acct.Id,
      custrecord_aschassociate1__c = 'Test Rep',
      custrecord_aschassociate2__c = 'Test Rep 2',
      custrecord_aschitempricepaid__c = 200,
      custrecord_aschitemqty__c = 10
    );
    insert ascItem;

    List<nco_aschistoricalsales__c> ascItems = getAscHistoryItems(ascItem.Id);

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromAscHistory(
      ascItems
    );

    System.assertEquals(
      2,
      result.get('toInsert').size(),
      'Should create 2 Sales_History records for two reps'
    );
    System.assertEquals(0, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }

  @isTest
  static void testGetUpdatesFromAscHistoryWithExistingSalesHistory() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    nco_aschistoricalsales__c ascItem = new nco_aschistoricalsales__c(
      Name = 'ASC-004',
      Account__c = acct.Id,
      custrecord_aschassociate1__c = 'Test Rep',
      custrecord_aschitempricepaid__c = 100,
      custrecord_aschitemqty__c = 5
    );
    insert ascItem;

    List<nco_aschistoricalsales__c> ascItems = getAscHistoryItems(ascItem.Id);

    Sales_History__c salesHistory = new Sales_History__c(
      Name = 'Test ASC Sales History',
      Source__c = 'ASC',
      Source_Id__c = String.valueOf(ascItem.Id) + '_1',
      ASC_Historical_Sales__c = ascItem.Id
    );
    insert salesHistory;

    Map<String, List<Sales_History__c>> result = UpdateSalesHistory.getUpdatesFromAscHistory(
      ascItems
    );

    System.assertEquals(0, result.get('toInsert').size());
    System.assertEquals(1, result.get('toUpdate').size());
    System.assertEquals(0, result.get('toDelete').size());
  }
}
