@IsTest
private class NetSuiteItemsListControllerTest {

    @IsTest
    static void initDataTest() {
        breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
            Name = 'Test Name',
            Base_Price__c = 100,
            breadwinner_ns__DisplayName__c = 'Test Display Name'
        );
        insert item;

        Test.startTest();
            NetSuiteItemsListController.InitData result = NetSuiteItemsListController.initData();
        Test.stopTest();

        System.assert(result.pageResult.netSuiteItems.size() > 0);
    }

    @IsTest
    static void getFilteredNetSuiteItemsTest() {
        breadwinner_ns__BW_Item__c item = new breadwinner_ns__BW_Item__c(
            Name = 'FilterMatchItem',
            Base_Price__c = 500,
            breadwinner_ns__DisplayName__c = 'Filter Display',
            ncf_item_stdweight__c = 1.5,
            ncf_item_stoneweight1__c = 0.75,
            ncf_item9__c = 'VendorA',
            ncf_item_promotioncode__c = 'Promo123',
            ncf_item_serialized_item_type__c = true,
            ncf_item_groupcode__c = 'GroupA',
            breadwinner_ns__ClassName__c = 'DivisionA',
            ncf_item_psgss_merc_dept__c = 'DeptA',
            ncf_item_ownertype__c = 'Retail',
            ncf_item_stoneshape1__c = 'Round',
            ncf_item_stonemmsize1_1__c = 5.5,
            ncf_item_materialtype1__c = 'Gold',
            ncf_item_stoneclarity1__c = 'VS1'
        );
        insert item;

        NetSuiteItemsListController.Filter filter = new NetSuiteItemsListController.Filter();
        filter.itemNumber = 'FilterMatchItem';
        filter.minPrice = '400';
        filter.maxPrice = '600';
        filter.caratWeightMin = '1.0';
        filter.caratWeightMax = '2.0';
        filter.displayName = 'Filter Display';
        filter.preferredVendor = 'VendorA';
        filter.promoCode = 'Promo123';
        filter.isSerialized = true;
        filter.groupCode = 'GroupA';
        filter.divisionName = 'DivisionA';
        filter.merchandiseDept = 'DeptA';
        filter.ownerType = 'Retail';
        filter.centerStoneShape = 'Round';
        filter.centerStoneLengthMin = '5';
        filter.centerStoneLengthMax = '6';
        filter.metalType = 'Gold';
        filter.centerStoneWeightMin = '0.5';
        filter.centerStoneWeightMax = '1.0';
        filter.centerStoneClarity = 'VS1';

        String filterJSON = JSON.serialize(filter);

        Test.startTest();
            NetSuiteItemsListController.PageResult result = 
                NetSuiteItemsListController.getFilteredNetSuiteItems(filterJSON, 'Name', 'ASC', 1);
        Test.stopTest();

        System.assertEquals(1, result.netSuiteItems.size());
        System.assertEquals(item.Id, result.netSuiteItems[0].Id);
    }

    @IsTest
    static void testRollUpWithLocation() {
        // Create location
        breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
            Name = 'TestLocation'
        );
        insert loc;

        // Create parent item
        breadwinner_ns__BW_Item__c parentItem = new breadwinner_ns__BW_Item__c(
            Name = 'PARENT001',
            Base_Price__c = 1000
        );
        insert parentItem;

        // Create child items pointing to parent
        breadwinner_ns__BW_Item__c child1 = new breadwinner_ns__BW_Item__c(
            Name = 'PARENT001_0001',
            Base_Price__c = 1000,
            breadwinner_ns__Parent__c = parentItem.Id,
            Total_Qty_On_Hand__c = 5
        );
        breadwinner_ns__BW_Item__c child2 = new breadwinner_ns__BW_Item__c(
            Name = 'PARENT001_0002',
            Base_Price__c = 1000,
            breadwinner_ns__Parent__c = parentItem.Id,
            Total_Qty_On_Hand__c = 3
        );
        insert new List<breadwinner_ns__BW_Item__c>{ child1, child2 };

        // Create inventory location records for children
        breadwinner_ns__BW_Inventory_Location__c inv1 = new breadwinner_ns__BW_Inventory_Location__c(
            breadwinner_ns__Item__c = child1.Id,
            breadwinner_ns__Location__c = loc.Id,
            breadwinner_ns__QuantityOnHand__c = 2,
            breadwinner_ns__QuantityAvailable__c = 2,
            breadwinner_ns__QuantityBackOrdered__c = 0
        );
        breadwinner_ns__BW_Inventory_Location__c inv2 = new breadwinner_ns__BW_Inventory_Location__c(
            breadwinner_ns__Item__c = child2.Id,
            breadwinner_ns__Location__c = loc.Id,
            breadwinner_ns__QuantityOnHand__c = 3,
            breadwinner_ns__QuantityAvailable__c = 3,
            breadwinner_ns__QuantityBackOrdered__c = 0
        );
        insert new List<breadwinner_ns__BW_Inventory_Location__c>{ inv1, inv2 };

        // Filter: rollUp + location
        NetSuiteItemsListController.Filter filter = new NetSuiteItemsListController.Filter();
        filter.itemNumber = 'PARENT001';
        filter.preferredLocation = 'TestLocation';
        filter.rollUpSubitemsChange = true;

        String filterJSON = JSON.serialize(filter);

        Test.startTest();
            NetSuiteItemsListController.PageResult result = 
                NetSuiteItemsListController.getFilteredNetSuiteItems(filterJSON, null, null, 1);
        Test.stopTest();

        // Should show parent item
        System.assertEquals(1, result.netSuiteItems.size());
        System.assertEquals(parentItem.Id, result.netSuiteItems[0].Id);

        // rollUpQty should have aggregated child quantities
        System.assertNotEquals(null, result.rollUpQty);
        Map<String, Decimal> qty = result.rollUpQty.get(parentItem.Id);
        System.assertNotEquals(null, qty);
        System.assertEquals(5, qty.get('LocationOnHand')); // 2 + 3
        System.assertEquals(5, qty.get('LocationQtyAvail')); // 2 + 3
    }

    @IsTest
    static void testRollUpWithLocationStandaloneParent() {
        // Create location
        breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
            Name = 'TestLocation'
        );
        insert loc;

        // Create standalone item (no children, no parent)
        breadwinner_ns__BW_Item__c standaloneItem = new breadwinner_ns__BW_Item__c(
            Name = 'STANDALONE001',
            Base_Price__c = 500,
            Total_Qty_On_Hand__c = 10
        );
        insert standaloneItem;

        // Create inventory location record for standalone
        breadwinner_ns__BW_Inventory_Location__c inv = new breadwinner_ns__BW_Inventory_Location__c(
            breadwinner_ns__Item__c = standaloneItem.Id,
            breadwinner_ns__Location__c = loc.Id,
            breadwinner_ns__QuantityOnHand__c = 7,
            breadwinner_ns__QuantityAvailable__c = 7,
            breadwinner_ns__QuantityBackOrdered__c = 0
        );
        insert inv;

        // Filter: rollUp + location
        NetSuiteItemsListController.Filter filter = new NetSuiteItemsListController.Filter();
        filter.itemNumber = 'STANDALONE001';
        filter.preferredLocation = 'TestLocation';
        filter.rollUpSubitemsChange = true;

        String filterJSON = JSON.serialize(filter);

        Test.startTest();
            NetSuiteItemsListController.PageResult result = 
                NetSuiteItemsListController.getFilteredNetSuiteItems(filterJSON, null, null, 1);
        Test.stopTest();

        // Standalone item should appear
        System.assertEquals(1, result.netSuiteItems.size());
        System.assertEquals(standaloneItem.Id, result.netSuiteItems[0].Id);

        // qty from its own inv record
        Map<String, Decimal> qty = result.rollUpQty.get(standaloneItem.Id);
        System.assertNotEquals(null, qty);
        System.assertEquals(7, qty.get('LocationOnHand'));
    }

    @IsTest
    static void testRollUpWithLocationAndOnHand() {
        // Create location
        breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
            Name = 'TestLocation'
        );
        insert loc;

        // Create parent + child with inv
        breadwinner_ns__BW_Item__c parentItem = new breadwinner_ns__BW_Item__c(
            Name = 'ONHAND001',
            Base_Price__c = 200
        );
        insert parentItem;

        breadwinner_ns__BW_Item__c child = new breadwinner_ns__BW_Item__c(
            Name = 'ONHAND001_0001',
            Base_Price__c = 200,
            breadwinner_ns__Parent__c = parentItem.Id
        );
        insert child;

        breadwinner_ns__BW_Inventory_Location__c inv = new breadwinner_ns__BW_Inventory_Location__c(
            breadwinner_ns__Item__c = child.Id,
            breadwinner_ns__Location__c = loc.Id,
            breadwinner_ns__QuantityOnHand__c = 4,
            breadwinner_ns__QuantityAvailable__c = 4,
            breadwinner_ns__QuantityBackOrdered__c = 0
        );
        insert inv;

        // Filter: rollUp + location + onHand
        NetSuiteItemsListController.Filter filter = new NetSuiteItemsListController.Filter();
        filter.itemNumber = 'ONHAND001';
        filter.preferredLocation = 'TestLocation';
        filter.rollUpSubitemsChange = true;
        filter.onHandQty = true;

        String filterJSON = JSON.serialize(filter);

        Test.startTest();
            NetSuiteItemsListController.PageResult result = 
                NetSuiteItemsListController.getFilteredNetSuiteItems(filterJSON, null, null, 1);
        Test.stopTest();

        System.assertEquals(1, result.netSuiteItems.size());
        System.assertEquals(parentItem.Id, result.netSuiteItems[0].Id);
    }

    @IsTest
    static void testEmptyPageResult() {
        NetSuiteItemsListController.Filter filter = new NetSuiteItemsListController.Filter();
        filter.itemNumber = 'NONEXISTENT_ITEM_XYZ';

        String filterJSON = JSON.serialize(filter);

        Test.startTest();
            NetSuiteItemsListController.PageResult result = 
                NetSuiteItemsListController.getFilteredNetSuiteItems(filterJSON, null, null, 1);
        Test.stopTest();

        System.assertEquals(0, result.netSuiteItems.size());
        System.assertEquals(false, result.hasMore);
    }

	@IsTest
    static void testComputedSortWithLocation() {
        breadwinner_ns__BW_Location__c loc = new breadwinner_ns__BW_Location__c(
            Name = 'SortLocation'
        );
        insert loc;

        breadwinner_ns__BW_Item__c item1 = new breadwinner_ns__BW_Item__c(
            Name = 'SORT001',
            Base_Price__c = 100,
            Total_Qty_On_Hand__c = 10
        );
        breadwinner_ns__BW_Item__c item2 = new breadwinner_ns__BW_Item__c(
            Name = 'SORT002',
            Base_Price__c = 200,
            Total_Qty_On_Hand__c = 20
        );
        insert new List<breadwinner_ns__BW_Item__c>{ item1, item2 };

        breadwinner_ns__BW_Inventory_Location__c inv1 = new breadwinner_ns__BW_Inventory_Location__c(
            breadwinner_ns__Item__c = item1.Id,
            breadwinner_ns__Location__c = loc.Id,
            breadwinner_ns__QuantityOnHand__c = 5,
            breadwinner_ns__QuantityAvailable__c = 5,
            breadwinner_ns__QuantityBackOrdered__c = 0
        );
        breadwinner_ns__BW_Inventory_Location__c inv2 = new breadwinner_ns__BW_Inventory_Location__c(
            breadwinner_ns__Item__c = item2.Id,
            breadwinner_ns__Location__c = loc.Id,
            breadwinner_ns__QuantityOnHand__c = 15,
            breadwinner_ns__QuantityAvailable__c = 15,
            breadwinner_ns__QuantityBackOrdered__c = 0
        );
        insert new List<breadwinner_ns__BW_Inventory_Location__c>{ inv1, inv2 };

        NetSuiteItemsListController.Filter filter = new NetSuiteItemsListController.Filter();
        filter.itemNumber = 'SORT';
        filter.preferredLocation = 'SortLocation';

        String filterJSON = JSON.serialize(filter);

        Test.startTest();
            NetSuiteItemsListController.PageResult result = 
                NetSuiteItemsListController.getFilteredNetSuiteItems(filterJSON, 'LocationOnHand', 'DESC', 1);
        Test.stopTest();

        System.assertEquals(2, result.netSuiteItems.size());
        // item2 (inv 15) should be first when DESC
        System.assertEquals(item2.Id, result.netSuiteItems[0].Id);
    }
}