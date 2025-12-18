@isTest
private class OpenSpecialOrdersControllerTest {
  static Id order1Id;
  static Id order2Id;
  static Id item1Id;
  static Id item2Id;

  static void setupData() {
    breadwinner_ns__BW_Company__c newCustomer = new breadwinner_ns__BW_Company__c(
      Name = 'Test Customer'
    );
    insert newCustomer;

    breadwinner_ns__BW_Sales_Order__c order1 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order1',
      breadwinner_ns__Entity__c = newCustomer.Id,
      ncf_body_special_date__c = Date.newInstance(2025, 10, 5),
      ncf_body_is_special_order__c = true,
      breadwinner_ns__Status__c = 'Open',
      ncf_body_special_order_date__c = Date.newInstance(2025, 12, 1),
      ncf_body_special_comments__c = 'Test Comments',
      breadwinner_ns__SalesRepName__c = 'Test Rep',
      ncf_body_special_item_type__c = 'TypeA',
      ncf_body_special_statuses__c = 'In Progress',
      breadwinner_ns__LocationName__c = 'Loc1'
    );

    breadwinner_ns__BW_Sales_Order__c order2 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order2',
      breadwinner_ns__Entity__c = newCustomer.Id,
      ncf_body_special_date__c = Date.newInstance(2025, 10, 6),
      ncf_body_is_special_order__c = true,
      breadwinner_ns__Status__c = 'Open',
      ncf_body_special_order_date__c = Date.newInstance(2025, 12, 2),
      ncf_body_special_comments__c = 'Other Comments',
      breadwinner_ns__SalesRepName__c = 'Other Rep',
      ncf_body_special_item_type__c = 'TypeB',
      ncf_body_special_statuses__c = 'Inactive',
      breadwinner_ns__LocationName__c = 'Loc2'
    );
    insert new List<breadwinner_ns__BW_Sales_Order__c>{ order1, order2 };

    breadwinner_ns__BW_Item__c item1 = new breadwinner_ns__BW_Item__c(
      Name = 'item1',
      ncf_item9__c = 'VendorA'
    );

    breadwinner_ns__BW_Item__c item2 = new breadwinner_ns__BW_Item__c(
      Name = 'item2',
      ncf_item9__c = 'ROLEX WATCH U.S.A., INC'
    );

    insert new List<breadwinner_ns__BW_Item__c>{ item1, item2 };

    breadwinner_ns__BW_Line_Item__c lineItem1 = new breadwinner_ns__BW_Line_Item__c(
      breadwinner_ns__Sales_Order__c = order1.Id,
      breadwinner_ns__Item__c = item1.id,
      ncf_col_special_sku__c = 'SKU1',
      ncf_col_special_order_number__c = 'Vend1',
      ncf_col_special_quoted_price__c = 100
    );

    breadwinner_ns__BW_Line_Item__c lineItem2 = new breadwinner_ns__BW_Line_Item__c(
      breadwinner_ns__Sales_Order__c = order2.Id,
      breadwinner_ns__Item__c = item2.id,
      ncf_col_special_sku__c = 'SKU2',
      ncf_col_special_order_number__c = 'Vend2',
      ncf_col_special_quoted_price__c = 200
    );

    insert new List<breadwinner_ns__BW_Line_Item__c>{ lineItem1, lineItem2 };
  }

  @isTest
  static void testGetOpenSpecialOrders_success() {
    setupData();

    Test.startTest();
    // salesRep filter
    List<breadwinner_ns__BW_Line_Item__c> results = OpenSpecialOrdersController.getOpenSpecialOrders(
      'Test Rep',
      null,
      null,
      null,
      null,
      null,
      null,
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by salesRep');

    // customer filter
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      'Test Customer',
      null,
      null,
      null,
      null,
      null,
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(2, results.size(), 'Should filter by customer');

    // vendor filter
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      'VendorA',
      null,
      null,
      null,
      null,
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by vendor');

    // location filter
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      'Loc1',
      null,
      null,
      null,
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by location');

    // status filter
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      null,
      'In Progress',
      null,
      null,
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by status');

    // itemType filter
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      null,
      null,
      'TypeA',
      null,
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by itemType');

    // vendornum filter (case-insensitive)
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      null,
      null,
      null,
      'vend1',
      false,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by vendornum');

    // showActiveOrdersOnly filter (should exclude Inactive)
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      true,
      null,
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should only show active orders');

    // comments filter (containsIgnoreCase)
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
      'Test Comments',
      new List<String>(),
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should filter by comments');

    // hideRolexOrTudor filter
    results = OpenSpecialOrdersController.getOpenSpecialOrders(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
      null,
      new List<String>{ 'ROLEX WATCH U.S.A., INC' },
      10,
      0,
      'customer',
      'asc'
    );
    System.assertEquals(1, results.size(), 'Should hide Rolex vendor');

    // sortBy and sortDirection (just to cover code)
    results = OpenSpecialOrdersController.getOpenSpecialOrders(2);
    System.assert(results.size() > 0, 'Should sort by quotedPrice desc');
    System.assert(
      results[0].ncf_col_special_quoted_price__c == 200,
      'Should return order with the higer quoted price as the first result'
    );

    Test.stopTest();
  }

  @isTest
  static void testGetOpenSpecialOrders_exception() {
    Test.startTest();

    try {
      OpenSpecialOrdersController.getOpenSpecialOrders(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        false,
        null,
        new List<String>(),
        -1,
        0,
        'quotedPrice',
        'desc'
      );

      System.assert(false, 'Exception should have been thrown');
    } catch (AuraHandledException e) {
      System.Assert(
        e.getMessage() != null,
        'Exception message should not be null'
      );
    }

    Test.stopTest();
  }
}
