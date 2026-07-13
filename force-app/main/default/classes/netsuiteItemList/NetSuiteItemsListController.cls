public with sharing class NetSuiteItemsListController {

    private static final Set<String> ALLOWED_SORT_FIELDS = new Set<String>{
        'Name', 'Base_Price__c', 'breadwinner_ns__DisplayName__c', 'ncf_item_stdweight__c',
        'ncf_item_stoneweight1__c', 'Total_Qty_Avail__c',
        'ncf_item_ownertype__c', 'ncf_item9__c', 'breadwinner_ns__ClassName__c',
        'ncf_item_psgss_merc_dept__c', 'ncf_item_groupcode__c',
        'ncf_item_datefirstreceipt__c', 'ncf_item_datelastreceipt__c',
        'breadwinner_ns__Cost__c', 'Margin_Percent__c', 'ncf_item_replacementcost__c',
        'Total_Weight_Displayed_in_Table__c', 'Id'
    };

    private static final Set<String> COMPUTED_SORT_FIELDS = new Set<String>{
        'LocationOnHand', 'LocationQtyAvail', 'LocationQtyInTransit'
    };

    private static final Map<String, String> INV_FIELD_MAP = new Map<String, String>{
        'LocationOnHand' => 'breadwinner_ns__QuantityOnHand__c',
        'LocationQtyAvail' => 'breadwinner_ns__QuantityAvailable__c',
        'LocationQtyInTransit' => 'breadwinner_ns__QuantityBackOrdered__c'
    };

    private static final String FULL_SELECT_FIELDS = 
        'SELECT ' +
        '   Name, ' +
        '   imageId__c, ' +
        '   Total_Qty_Avail__c, ' +
        '   Total_Qty_On_Hand__c, ' +
        '   Total_Qty_In_Transit__c, ' +
        '   breadwinner_ns__DisplayName__c, ' +
        '   ncf_item_stoneweight1__c, ' +
        '   ncf_item_stdweight__c, ' +
        '   Location_Stock__c, ' +
        '   (' +
        '       SELECT ' +
        '           breadwinner_ns__Location__r.Name, ' +
        '           breadwinner_ns__QuantityAvailable__c, ' +
        '           breadwinner_ns__QuantityOnHand__c,' +
        '           breadwinner_ns__QuantityBackOrdered__c' +
        '       FROM breadwinner_ns__BWInventoryLocations__r ' + 
        '   ), ' +
        '   Base_Price__c, ' +
        '   breadwinner_ns__Cost__c, ' +
        '   Margin_Percent__c, ' +
        '   ncf_item_replacementcost__c, ' +
        '   Total_Weight_Displayed_in_Table__c, ' +
        '   ncf_item_ownertype__c, ' +
        '   ncf_item9__c, ' +
        '   breadwinner_ns__ClassName__c, ' +
        '   ncf_item_psgss_merc_dept__c, ' +
        '   ncf_item_groupcode__c, ' +
        '   ncf_item_serialized_item_type__c, ' +
        '   ncf_item_watchserial__c, ' +
        '   ncf_item_datefirstreceipt__c, ' +
        '   ncf_item_datelastreceipt__c, ' +
        '   Is_On_Website__c ' +
        'FROM breadwinner_ns__BW_Item__c ';

    @AuraEnabled
    public static InitData initData() {
        InitData data = new InitData();

        PageResult pageResult = getFilteredNetSuiteItems('{}', null, null, 1);
        data.pageResult = pageResult;

        String netSuiteItemSObjectName = breadwinner_ns__BW_Item__c.class.getName();

        data.preferredVendorOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Preferred_Vendor__c);
        data.promoCodeOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Promotion_Code__c);
        data.groupCodeOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Group_Code_Picklist__c);
        data.divisionNameOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Division_Picklist__c);
        data.merchandiseDeptOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Merchandise_Department__c);
        data.ownerTypeOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Owner_Type__c);
        data.centerStoneShapeOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Stone_Shape__c);
        data.metalTypeOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Metal_Type__c);
        data.centerStoneClarityOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Stone_Clarity__c);
        data.preferredLocationOptions = PicklistHelper.getGlobalValueSet(netSuiteItemSObjectName, breadwinner_ns__BW_Item__c.Preferred_Location__c);

        return data;
    }

    @AuraEnabled
    public static PageResult getFilteredNetSuiteItems(String filterJSON, String sortField, String sortDirection, Integer pageNumber) {

        Filter filter = (Filter) JSON.deserialize(filterJSON, Filter.class);

        Boolean rollUp = filter.rollUpSubitemsChange != null && filter.rollUpSubitemsChange;
        Boolean hasLocation = String.isNotBlank(filter.preferredLocation);

        String whereClause = buildWhereClause(filter);
        Boolean needsAggregate = false;
        String orderBy = 'ORDER BY Id DESC ';

        if (String.isNotBlank(sortField)) {
            String soqlSortField = getSoqlSortField(sortField, filter);
            needsAggregate = soqlSortField == null && COMPUTED_SORT_FIELDS.contains(sortField);

            if (soqlSortField != null) {
                orderBy = 'ORDER BY ' + soqlSortField + ' ' + sortDirection + ' NULLS LAST ';
            } else if (needsAggregate) {
                orderBy = '';
            }
        }

        List<Id> allIds = new List<Id>();
        List<Id> subtotalIds = new List<Id>();

        if (rollUp) {
            Set<Id> foundItemIds = new Set<Id>();
            for (breadwinner_ns__BW_Item__c rec : Database.query(
                'SELECT Id FROM breadwinner_ns__BW_Item__c ' + whereClause + 'LIMIT 10000'
            )) {
                foundItemIds.add(rec.Id);
            }

            subtotalIds.addAll(foundItemIds);

            // Split: items WITH parent - get their parents. Items WITHOUT parent - show themselves.
            Set<Id> parentIds = new Set<Id>();
            Set<Id> standaloneIds = new Set<Id>();

            for (breadwinner_ns__BW_Item__c item : [
                SELECT Id, breadwinner_ns__Parent__c
                FROM breadwinner_ns__BW_Item__c
                WHERE Id IN :foundItemIds
            ]) {
                if (item.breadwinner_ns__Parent__c != null) {
                    parentIds.add(item.breadwinner_ns__Parent__c);
                } else {
                    standaloneIds.add(item.Id);
                }
            }

            allIds.addAll(parentIds);
            allIds.addAll(standaloneIds);

            // Ensure consistent order for pagination
            if (!allIds.isEmpty()) {
                List<Id> sortedAllIds = new List<Id>();
                Set<Id> allIdsSet = new Set<Id>(allIds);
                for (breadwinner_ns__BW_Item__c rec : Database.query(
                    'SELECT Id FROM breadwinner_ns__BW_Item__c WHERE Id IN :allIdsSet ' + orderBy
                )) {
                    sortedAllIds.add(rec.Id);
                }
                allIds = sortedAllIds;
            }
        } else {
            for (breadwinner_ns__BW_Item__c rec : Database.query(
                'SELECT Id FROM breadwinner_ns__BW_Item__c ' + whereClause + orderBy + 'LIMIT 10000'
            )) {
                allIds.add(rec.Id);
            }
            subtotalIds.addAll(allIds);
        }

        if (needsAggregate) {
            if (rollUp) {
                Map<Id, Map<String, Decimal>> qtyMap = getRollUpLocationQuantities(
                    new Set<Id>(allIds), hasLocation ? filter.preferredLocation : null
                );
                Map<Id, Decimal> valuesMap = new Map<Id, Decimal>();
                for (Id itemId : allIds) {
                    Map<String, Decimal> qty = qtyMap.get(itemId);
                    valuesMap.put(itemId, qty != null ? (qty.get(sortField) ?? 0) : 0);
                }
                allIds.sort(new InventoryComparator(valuesMap, sortDirection));
            } else {
                String invField = INV_FIELD_MAP.get(sortField);
                Map<Id, Decimal> valuesMap = getComputedValues(allIds, invField, filter.preferredLocation);
                allIds.sort(new InventoryComparator(valuesMap, sortDirection));
            }
        }

        List<Id> pageIds = slicePage(allIds, pageNumber);

        if (pageIds.isEmpty()) {
            PageResult result = new PageResult();
            result.netSuiteItems = new List<breadwinner_ns__BW_Item__c>();
            result.hasMore = false;
            result.subtotals = new Subtotals();
            result.showSubtotals = true;
            return result;
        }

        List<breadwinner_ns__BW_Item__c> records = Database.query(
            FULL_SELECT_FIELDS + 'WHERE Id IN :pageIds ' + orderBy
        );

        if (needsAggregate) {
            records = reorderToMatch(records, pageIds);
        }

        PageResult result = new PageResult();
        result.netSuiteItems = records;
        result.hasMore = (pageNumber * 50) < allIds.size();

        Integer totalCount = Database.countQuery(
            'SELECT COUNT() FROM breadwinner_ns__BW_Item__c ' + whereClause + 'LIMIT 10001'
        );
        Boolean showSubtotals = totalCount <= 10000;
        result.showSubtotals = showSubtotals;

        // RollUp: compute aggregated quantities for page
        if (rollUp) {
            result.rollUpQty = getRollUpLocationQuantities(
                new Set<Id>(pageIds), hasLocation ? filter.preferredLocation : null
            );
        }

        if (pageNumber == 1) {
            result.subtotals = calculateSubtotals(subtotalIds, filter);
        }

        return result;
    }

    private static String getSoqlSortField(String sortField, Filter filter) {

        if (ALLOWED_SORT_FIELDS.contains(sortField)) {
            return sortField;
        }

        // Computed fields without rollUp and without location - map to real field
        Boolean rollUp = filter.rollUpSubitemsChange != null && filter.rollUpSubitemsChange;
        if (COMPUTED_SORT_FIELDS.contains(sortField) && String.isBlank(filter.preferredLocation) && !rollUp) {
            if (sortField == 'LocationQtyAvail') {
                return 'Total_Qty_Avail__c';
            }
            if (sortField == 'LocationOnHand') {
                return 'Total_Qty_On_Hand__c';
            }
            if (sortField == 'LocationQtyInTransit') {
                return 'Total_Qty_In_Transit__c';
            }
        }

        return null;
    }

    /**
     * When RollUp is selected, quantities per parent are calculated by summing
     * across all children. If location is provided, only inv at that location is used.
     * If no location, inv from ALL locations is summed.
     * Parents without children are included with their own quantity.
     * Fallback to Total fields only when a subitem has NO inv records at ANY location.
     */
    private static Map<Id, Map<String, Decimal>> getRollUpLocationQuantities(Set<Id> parentIds, String location) {
        Map<Id, Map<String, Decimal>> result = new Map<Id, Map<String, Decimal>>();
        Boolean hasLocation = String.isNotBlank(location);

        // Step 1: Get all subitems of these parents
        Map<Id, breadwinner_ns__BW_Item__c> subitemsMap = new Map<Id, breadwinner_ns__BW_Item__c>([
            SELECT Id, breadwinner_ns__Parent__c,
                   Total_Qty_Avail__c, Total_Qty_On_Hand__c, Total_Qty_In_Transit__c
            FROM breadwinner_ns__BW_Item__c
            WHERE breadwinner_ns__Parent__c IN :parentIds
        ]);

        // Step 2: Get inv records for subitems
        Map<Id, breadwinner_ns__BW_Inventory_Location__c> invAtLocationMap = new Map<Id, breadwinner_ns__BW_Inventory_Location__c>();
        Map<Id, List<breadwinner_ns__BW_Inventory_Location__c>> allInvByItem = new Map<Id, List<breadwinner_ns__BW_Inventory_Location__c>>();
        Set<Id> subitemsWithAnyInv = new Set<Id>();

        if (!subitemsMap.isEmpty()) {
            for (breadwinner_ns__BW_Inventory_Location__c inv : [
                SELECT breadwinner_ns__Item__c,
                       breadwinner_ns__QuantityAvailable__c,
                       breadwinner_ns__QuantityOnHand__c,
                       breadwinner_ns__QuantityBackOrdered__c,
                       breadwinner_ns__Location__r.Name
                FROM breadwinner_ns__BW_Inventory_Location__c
                WHERE breadwinner_ns__Item__c IN :subitemsMap.keySet()
            ]) {
                Id itemId = inv.breadwinner_ns__Item__c;
                subitemsWithAnyInv.add(itemId);

                if (hasLocation && inv.breadwinner_ns__Location__r.Name == location) {
                    invAtLocationMap.put(itemId, inv);
                }

                if (!hasLocation) {
                    if (!allInvByItem.containsKey(itemId)) {
                        allInvByItem.put(itemId, new List<breadwinner_ns__BW_Inventory_Location__c>());
                    }
                    allInvByItem.get(itemId).add(inv);
                }
            }
        }

        // Step 3: For each subitem - determine qty and sum per parent
        Set<Id> parentsWithSubitems = new Set<Id>();
        for (breadwinner_ns__BW_Item__c sub : subitemsMap.values()) {
            Id parentId = sub.breadwinner_ns__Parent__c;
            parentsWithSubitems.add(parentId);

            Decimal qtyAvail = 0;
            Decimal qtyOnHand = 0;
            Decimal qtyInTransit = 0;

            if (hasLocation) {
                breadwinner_ns__BW_Inventory_Location__c inv = invAtLocationMap.get(sub.Id);
                if (inv != null) {
                    qtyAvail = inv.breadwinner_ns__QuantityAvailable__c ?? 0;
                    qtyOnHand = inv.breadwinner_ns__QuantityOnHand__c ?? 0;
                    qtyInTransit = inv.breadwinner_ns__QuantityBackOrdered__c ?? 0;
                } else if (subitemsWithAnyInv.contains(sub.Id)) {
                    qtyAvail = 0;
                    qtyOnHand = 0;
                    qtyInTransit = 0;
                } else {
                    qtyAvail = sub.Total_Qty_Avail__c ?? 0;
                    qtyOnHand = sub.Total_Qty_On_Hand__c ?? 0;
                    qtyInTransit = sub.Total_Qty_In_Transit__c ?? 0;
                }
            } else {
                List<breadwinner_ns__BW_Inventory_Location__c> invList = allInvByItem.get(sub.Id);
                if (invList != null) {
                    for (breadwinner_ns__BW_Inventory_Location__c inv : invList) {
                        qtyAvail += inv.breadwinner_ns__QuantityAvailable__c ?? 0;
                        qtyOnHand += inv.breadwinner_ns__QuantityOnHand__c ?? 0;
                        qtyInTransit += inv.breadwinner_ns__QuantityBackOrdered__c ?? 0;
                    }
                } else {
                    qtyAvail = sub.Total_Qty_Avail__c ?? 0;
                    qtyOnHand = sub.Total_Qty_On_Hand__c ?? 0;
                    qtyInTransit = sub.Total_Qty_In_Transit__c ?? 0;
                }
            }

            if (!result.containsKey(parentId)) {
                result.put(parentId, new Map<String, Decimal>{
                    'LocationQtyAvail' => 0,
                    'LocationOnHand' => 0,
                    'LocationQtyInTransit' => 0
                });
            }

            Map<String, Decimal> totals = result.get(parentId);
            totals.put('LocationQtyAvail', totals.get('LocationQtyAvail') + qtyAvail);
            totals.put('LocationOnHand', totals.get('LocationOnHand') + qtyOnHand);
            totals.put('LocationQtyInTransit', totals.get('LocationQtyInTransit') + qtyInTransit);
        }

        // Step 4: Parents without subitems - use their own qty
        Set<Id> parentsWithoutSubitems = new Set<Id>();
        for (Id pid : parentIds) {
            if (!parentsWithSubitems.contains(pid)) {
                parentsWithoutSubitems.add(pid);
            }
        }

        if (!parentsWithoutSubitems.isEmpty()) {
            Map<Id, breadwinner_ns__BW_Inventory_Location__c> selfInvAtLocation = new Map<Id, breadwinner_ns__BW_Inventory_Location__c>();
            Map<Id, List<breadwinner_ns__BW_Inventory_Location__c>> selfAllInvByItem = new Map<Id, List<breadwinner_ns__BW_Inventory_Location__c>>();
            Set<Id> standaloneWithAnyInv = new Set<Id>();

            for (breadwinner_ns__BW_Inventory_Location__c inv : [
                SELECT breadwinner_ns__Item__c,
                       breadwinner_ns__QuantityAvailable__c,
                       breadwinner_ns__QuantityOnHand__c,
                       breadwinner_ns__QuantityBackOrdered__c,
                       breadwinner_ns__Location__r.Name
                FROM breadwinner_ns__BW_Inventory_Location__c
                WHERE breadwinner_ns__Item__c IN :parentsWithoutSubitems
            ]) {
                Id itemId = inv.breadwinner_ns__Item__c;
                standaloneWithAnyInv.add(itemId);

                if (hasLocation && inv.breadwinner_ns__Location__r.Name == location) {
                    selfInvAtLocation.put(itemId, inv);
                }

                if (!hasLocation) {
                    if (!selfAllInvByItem.containsKey(itemId)) {
                        selfAllInvByItem.put(itemId, new List<breadwinner_ns__BW_Inventory_Location__c>());
                    }
                    selfAllInvByItem.get(itemId).add(inv);
                }
            }

            for (breadwinner_ns__BW_Item__c item : [
                SELECT Id, Total_Qty_Avail__c, Total_Qty_On_Hand__c, Total_Qty_In_Transit__c
                FROM breadwinner_ns__BW_Item__c
                WHERE Id IN :parentsWithoutSubitems
            ]) {
                Decimal qtyAvail = 0;
                Decimal qtyOnHand = 0;
                Decimal qtyInTransit = 0;

                if (hasLocation) {
                    breadwinner_ns__BW_Inventory_Location__c inv = selfInvAtLocation.get(item.Id);
                    if (inv != null) {
                        qtyAvail = inv.breadwinner_ns__QuantityAvailable__c ?? 0;
                        qtyOnHand = inv.breadwinner_ns__QuantityOnHand__c ?? 0;
                        qtyInTransit = inv.breadwinner_ns__QuantityBackOrdered__c ?? 0;
                    } else if (standaloneWithAnyInv.contains(item.Id)) {
                        qtyAvail = 0;
                        qtyOnHand = 0;
                        qtyInTransit = 0;
                    } else {
                        qtyAvail = item.Total_Qty_Avail__c ?? 0;
                        qtyOnHand = item.Total_Qty_On_Hand__c ?? 0;
                        qtyInTransit = item.Total_Qty_In_Transit__c ?? 0;
                    }
                } else {
                    List<breadwinner_ns__BW_Inventory_Location__c> invList = selfAllInvByItem.get(item.Id);
                    if (invList != null) {
                        for (breadwinner_ns__BW_Inventory_Location__c inv : invList) {
                            qtyAvail += inv.breadwinner_ns__QuantityAvailable__c ?? 0;
                            qtyOnHand += inv.breadwinner_ns__QuantityOnHand__c ?? 0;
                            qtyInTransit += inv.breadwinner_ns__QuantityBackOrdered__c ?? 0;
                        }
                    } else {
                        qtyAvail = item.Total_Qty_Avail__c ?? 0;
                        qtyOnHand = item.Total_Qty_On_Hand__c ?? 0;
                        qtyInTransit = item.Total_Qty_In_Transit__c ?? 0;
                    }
                }

                result.put(item.Id, new Map<String, Decimal>{
                    'LocationQtyAvail' => qtyAvail,
                    'LocationOnHand' => qtyOnHand,
                    'LocationQtyInTransit' => qtyInTransit
                });
            }
        }

        return result;
    }

    // Subtotals
    // When rollUp, subtotalIds are subitems - so hasLocation logic handles it naturally
    
    private static Subtotals calculateSubtotals(List<Id> allIds, Filter filter) {
        Subtotals sub = new Subtotals();
        Boolean hasLocation = String.isNotBlank(filter.preferredLocation);

        // Build inv map when location is selected
        Map<Id, breadwinner_ns__BW_Inventory_Location__c> invMap = new Map<Id, breadwinner_ns__BW_Inventory_Location__c>();
        if (hasLocation) {
            String locQuery = 'SELECT breadwinner_ns__Item__c, ' +
                'breadwinner_ns__QuantityAvailable__c, ' +
                'breadwinner_ns__QuantityOnHand__c, ' +
                'breadwinner_ns__QuantityBackOrdered__c ' +
                'FROM breadwinner_ns__BW_Inventory_Location__c ' +
                'WHERE breadwinner_ns__Item__c IN :allIds ' +
                'AND breadwinner_ns__Location__r.Name = \'' + String.escapeSingleQuotes(filter.preferredLocation) + '\'';
            for (breadwinner_ns__BW_Inventory_Location__c inv : Database.query(locQuery)) {
                invMap.put(inv.breadwinner_ns__Item__c, inv);
            }
        }

        for (breadwinner_ns__BW_Item__c item : [
            SELECT Base_Price__c, breadwinner_ns__Cost__c, Margin_Percent__c,
                ncf_item_replacementcost__c, Total_Weight_Displayed_in_Table__c,
                Total_Qty_Avail__c, Total_Qty_On_Hand__c, Total_Qty_In_Transit__c
            FROM breadwinner_ns__BW_Item__c
            WHERE Id IN :allIds
        ]) {
            sub.totalWeight += item.Total_Weight_Displayed_in_Table__c ?? 0;

            if (hasLocation) {
                breadwinner_ns__BW_Inventory_Location__c inv = invMap.get(item.Id);
                if (inv != null) {
                    sub.totalPrice += getTotalPrice(item.Base_Price__c, inv.breadwinner_ns__QuantityOnHand__c);
                    sub.totalCost += getTotalPrice(item.breadwinner_ns__Cost__c, inv.breadwinner_ns__QuantityOnHand__c);
                    sub.totalReplacementCost += getTotalPrice(item.ncf_item_replacementcost__c, inv.breadwinner_ns__QuantityOnHand__c);

                    sub.totalLocationQtyAvail += inv.breadwinner_ns__QuantityAvailable__c ?? 0;
                    sub.totalLocationOnHand += inv.breadwinner_ns__QuantityOnHand__c ?? 0;
                    sub.totalLocationQtyInTransit += inv.breadwinner_ns__QuantityBackOrdered__c ?? 0;
                } else {
                    sub.totalPrice += getTotalPrice(item.Base_Price__c, item.Total_Qty_On_Hand__c);
                    sub.totalCost += getTotalPrice(item.breadwinner_ns__Cost__c, item.Total_Qty_On_Hand__c);
                    sub.totalReplacementCost += getTotalPrice(item.ncf_item_replacementcost__c, item.Total_Qty_On_Hand__c);

                    sub.totalLocationQtyAvail += item.Total_Qty_Avail__c ?? 0;
                    sub.totalLocationOnHand += item.Total_Qty_On_Hand__c ?? 0;
                    sub.totalLocationQtyInTransit += item.Total_Qty_In_Transit__c ?? 0;
                }
            } else {
                sub.totalPrice += getTotalPrice(item.Base_Price__c, item.Total_Qty_On_Hand__c);
                sub.totalCost += getTotalPrice(item.breadwinner_ns__Cost__c, item.Total_Qty_On_Hand__c);
                sub.totalReplacementCost += getTotalPrice(item.ncf_item_replacementcost__c, item.Total_Qty_On_Hand__c);

                sub.totalLocationQtyAvail += item.Total_Qty_Avail__c ?? 0;
                sub.totalLocationOnHand += item.Total_Qty_On_Hand__c ?? 0;
                sub.totalLocationQtyInTransit += item.Total_Qty_In_Transit__c ?? 0;
            }
        }
        
        sub.totalWeight = sub.totalWeight.setScale(2, RoundingMode.HALF_UP);
        sub.totalPrice = sub.totalPrice.setScale(2, RoundingMode.HALF_UP);
        sub.totalCost = sub.totalCost.setScale(2, RoundingMode.HALF_UP);
        sub.totalReplacementCost = sub.totalReplacementCost.setScale(2, RoundingMode.HALF_UP);
        sub.totalLocationQtyAvail = sub.totalLocationQtyAvail.setScale(2, RoundingMode.HALF_UP);
        sub.totalLocationOnHand = sub.totalLocationOnHand.setScale(2, RoundingMode.HALF_UP);
        sub.totalLocationQtyInTransit = sub.totalLocationQtyInTransit.setScale(2, RoundingMode.HALF_UP);
        sub.totalMargin = sub.totalPrice != 0 
            ? (((sub.totalPrice - sub.totalCost) / sub.totalPrice) * 100).setScale(2, RoundingMode.HALF_UP)
            : 0;

        return sub;
    }

    private static Decimal getTotalPrice(Decimal price, Decimal quantity) {
        price = price ?? 0;
        quantity = quantity ?? 0;
        return price * quantity;
    }

    private static String buildWhereClause(Filter filter) {
        List<String> whereParts = buildWhereParts(filter);
        if (whereParts.isEmpty()) {
            return '';
        }
        return 'WHERE ' + String.join(whereParts, ' AND ') + ' ';
    }

    private static List<Id> slicePage(List<Id> allIds, Integer pageNumber) {
        Integer offset = (pageNumber - 1) * 50;
        List<Id> pageIds = new List<Id>();
        for (Integer i = offset; i < Math.min(offset + 50, allIds.size()); i++) {
            pageIds.add(allIds[i]);
        }
        return pageIds;
    }

    private static Map<Id, Decimal> getComputedValues(List<Id> itemIds, String invField, String preferredLocation) {
        Map<Id, Decimal> valuesMap = new Map<Id, Decimal>();

        String locQuery = 'SELECT breadwinner_ns__Item__c, ' + invField + 
            ' FROM breadwinner_ns__BW_Inventory_Location__c' +
            ' WHERE breadwinner_ns__Item__c IN :itemIds' +
            ' AND breadwinner_ns__Location__r.Name = \'' + String.escapeSingleQuotes(preferredLocation) + '\'';
        
        for (breadwinner_ns__BW_Inventory_Location__c inv : Database.query(locQuery)) {
            valuesMap.put(inv.breadwinner_ns__Item__c, (Decimal) inv.get(invField));
        }

        List<Id> missingIds = new List<Id>();
        for (Id itemId : itemIds) {
            if (!valuesMap.containsKey(itemId)) {
                missingIds.add(itemId);
            }
        }

        if (!missingIds.isEmpty()) {
            String fallbackField;
            if (invField == 'breadwinner_ns__QuantityOnHand__c') {
                fallbackField = 'Total_Qty_On_Hand__c';
            } else if (invField == 'breadwinner_ns__QuantityAvailable__c') {
                fallbackField = 'Total_Qty_Avail__c';
            } else {
                fallbackField = 'Total_Qty_In_Transit__c';
            }

            for (breadwinner_ns__BW_Item__c item : Database.query(
                'SELECT Id, ' + fallbackField + ' FROM breadwinner_ns__BW_Item__c WHERE Id IN :missingIds'
            )) {
                valuesMap.put(item.Id, (Decimal) item.get(fallbackField));
            }
        }

        return valuesMap;
    }

    private static List<breadwinner_ns__BW_Item__c> reorderToMatch(List<breadwinner_ns__BW_Item__c> records, List<Id> pageIds) {
        Map<Id, breadwinner_ns__BW_Item__c> recordMap = new Map<Id, breadwinner_ns__BW_Item__c>();
        for (breadwinner_ns__BW_Item__c rec : records) {
            recordMap.put(rec.Id, rec);
        }
        List<breadwinner_ns__BW_Item__c> ordered = new List<breadwinner_ns__BW_Item__c>();
        for (Id pid : pageIds) {
            if (recordMap.containsKey(pid)) {
                ordered.add(recordMap.get(pid));
            }
        }
        return ordered;
    }

    private static List<String> buildWhereParts(Filter filter) {
        List<String> whereParts = new List<String>();
        Boolean hasLocation = String.isNotBlank(filter.preferredLocation);

        if (String.isNotBlank(filter.itemNumber)) {
            whereParts.add('Name LIKE \'%' + String.escapeSingleQuotes(filter.itemNumber) + '%\'');
        }
        if (String.isNotBlank(filter.minPrice)) {
            whereParts.add('Base_Price__c >= ' + String.escapeSingleQuotes(filter.minPrice));
        }
        if (String.isNotBlank(filter.maxPrice)) {
            whereParts.add('Base_Price__c <= ' + String.escapeSingleQuotes(filter.maxPrice));
        }
        if (String.isNotBlank(filter.caratWeightMin)) {
            whereParts.add('ncf_item_stdweight__c >= ' + String.escapeSingleQuotes(filter.caratWeightMin));
        }
        if (String.isNotBlank(filter.caratWeightMax)) {
            whereParts.add('ncf_item_stdweight__c <= ' + String.escapeSingleQuotes(filter.caratWeightMax));
        }
        if (String.isNotBlank(filter.displayName)) {
            whereParts.add('breadwinner_ns__DisplayName__c LIKE \'%' + String.escapeSingleQuotes(filter.displayName) + '%\'');
        }
        if (String.isNotBlank(filter.preferredVendor)) {
            whereParts.add('ncf_item9__c = \'' + String.escapeSingleQuotes(filter.preferredVendor) + '\'');
        }
        if (String.isNotBlank(filter.promoCode)) {
            whereParts.add('ncf_item_promotioncode__c = \'' + String.escapeSingleQuotes(filter.promoCode) + '\'');
        }
        if (filter.isSerialized != null && filter.isSerialized) {
            whereParts.add('ncf_item_serialized_item_type__c = true');
        }
        if (String.isNotBlank(filter.groupCode)) {
            whereParts.add('ncf_item_groupcode__c = \'' + String.escapeSingleQuotes(filter.groupCode) + '\'');
        }
        if (String.isNotBlank(filter.divisionName)) {
            whereParts.add('breadwinner_ns__ClassName__c = \'' + String.escapeSingleQuotes(filter.divisionName) + '\'');
        }
        if (String.isNotBlank(filter.merchandiseDept)) {
            whereParts.add('ncf_item_psgss_merc_dept__c = \'' + String.escapeSingleQuotes(filter.merchandiseDept) + '\'');
        }
        if (String.isNotBlank(filter.ownerType)) {
            whereParts.add('ncf_item_ownertype__c = \'' + String.escapeSingleQuotes(filter.ownerType) + '\'');
        }
        if (filter.onWebsite != null && filter.onWebsite) {
            whereParts.add('Is_On_Website__c = true');
        }
        if (String.isNotBlank(filter.centerStoneShape)) {
            whereParts.add('ncf_item_stoneshape1__c = \'' + String.escapeSingleQuotes(filter.centerStoneShape) + '\'');
        }
        if (String.isNotBlank(filter.centerStoneLengthMin)) {
            whereParts.add('ncf_item_stonemmsize1_1__c >= ' + String.escapeSingleQuotes(filter.centerStoneLengthMin));
        }
        if (String.isNotBlank(filter.centerStoneLengthMax)) {
            whereParts.add('ncf_item_stonemmsize1_1__c <= ' + String.escapeSingleQuotes(filter.centerStoneLengthMax));
        }
        if (String.isNotBlank(filter.metalType)) {
            whereParts.add('ncf_item_materialtype1__c = \'' + String.escapeSingleQuotes(filter.metalType) + '\'');
        }
        if (String.isNotBlank(filter.centerStoneWeightMin)) {
            whereParts.add('ncf_item_stoneweight1__c >= ' + String.escapeSingleQuotes(filter.centerStoneWeightMin));
        }
        if (String.isNotBlank(filter.centerStoneWeightMax)) {
            whereParts.add('ncf_item_stoneweight1__c <= ' + String.escapeSingleQuotes(filter.centerStoneWeightMax));
        }
        if (String.isNotBlank(filter.centerStoneClarity)) {
            whereParts.add('ncf_item_stoneclarity1__c = \'' + String.escapeSingleQuotes(filter.centerStoneClarity) + '\'');
        }

        if (String.isNotBlank(filter.vendornum)) {
            whereParts.add(
                'breadwinner_ns__VendorName__c LIKE \'' +
                String.escapeSingleQuotes(filter.vendornum.trim()) +
                '%\''
            );
        }
        
        // Inventory / onHandQty conditions
        List<String> inventoryConditions = new List<String>();
        
        if (hasLocation) {
            inventoryConditions.add('breadwinner_ns__Location__r.Name = \'' + String.escapeSingleQuotes(filter.preferredLocation) + '\'');
        }

        if (filter.onHandQty != null && filter.onHandQty) {
            if (hasLocation) {
                inventoryConditions.add('breadwinner_ns__QuantityOnHand__c > 0');
            } else {
                whereParts.add('Total_Qty_On_Hand__c > 0');
            }
        }

        if (!inventoryConditions.isEmpty()) {
            String subQuery = 'Id IN (SELECT breadwinner_ns__Item__c FROM breadwinner_ns__BW_Inventory_Location__c WHERE ' 
                + String.join(inventoryConditions, ' AND ') + ')';
            whereParts.add(subQuery);
        }

        return whereParts;
    }



    public class InventoryComparator implements Comparator<Id> {
        private Map<Id, Decimal> values;
        private Integer dir;

        public InventoryComparator(Map<Id, Decimal> values, String sortDirection) {
            this.values = values;
            this.dir = sortDirection == 'ASC' ? 1 : -1;
        }

        public Integer compare(Id a, Id b) {
            Decimal valA = values.containsKey(a) ? values.get(a) : 0;
            Decimal valB = values.containsKey(b) ? values.get(b) : 0;
            if (valA > valB) return dir;
            if (valA < valB) return -dir;
            return 0;
        }
    }

    public class PageResult {
        @AuraEnabled public List<breadwinner_ns__BW_Item__c> netSuiteItems;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public Subtotals subtotals;
        @AuraEnabled public Boolean showSubtotals;
        @AuraEnabled public Map<Id, Map<String, Decimal>> rollUpQty;
    }

    public class Subtotals {
        @AuraEnabled public Decimal totalLocationQtyAvail = 0;
        @AuraEnabled public Decimal totalLocationOnHand = 0;
        @AuraEnabled public Decimal totalLocationQtyInTransit = 0;
        @AuraEnabled public Decimal totalPrice = 0;
        @AuraEnabled public Decimal totalCost = 0;
        @AuraEnabled public Decimal totalMargin = 0;
        @AuraEnabled public Decimal totalReplacementCost = 0;
        @AuraEnabled public Decimal totalWeight = 0;
    }

    public class InitData {
        @AuraEnabled public PageResult pageResult;

        @AuraEnabled public List<PicklistHelper.Option> preferredVendorOptions;
        @AuraEnabled public List<PicklistHelper.Option> promoCodeOptions;
        @AuraEnabled public List<PicklistHelper.Option> groupCodeOptions;
        @AuraEnabled public List<PicklistHelper.Option> divisionNameOptions;
        @AuraEnabled public List<PicklistHelper.Option> merchandiseDeptOptions;
        @AuraEnabled public List<PicklistHelper.Option> ownerTypeOptions;
        @AuraEnabled public List<PicklistHelper.Option> centerStoneShapeOptions;
        @AuraEnabled public List<PicklistHelper.Option> metalTypeOptions;
        @AuraEnabled public List<PicklistHelper.Option> centerStoneClarityOptions;
        @AuraEnabled public List<PicklistHelper.Option> preferredLocationOptions;
    }

    public class Filter {
        @AuraEnabled public String preferredLocation;
        @AuraEnabled public String itemNumber;
        @AuraEnabled public String minPrice;
        @AuraEnabled public String maxPrice;
        @AuraEnabled public String caratWeightMin;
        @AuraEnabled public String caratWeightMax;
        @AuraEnabled public String displayName;
        @AuraEnabled public String preferredVendor;
        @AuraEnabled public String promoCode;
        @AuraEnabled public Boolean isSerialized;
        @AuraEnabled public String groupCode;
        @AuraEnabled public String divisionName;
        @AuraEnabled public String merchandiseDept;
        @AuraEnabled public String ownerType;
        @AuraEnabled public Boolean onWebsite;
        @AuraEnabled public Boolean onHandQty;
        @AuraEnabled public String centerStoneShape;
        @AuraEnabled public String centerStoneLengthMin;
        @AuraEnabled public String centerStoneLengthMax;
        @AuraEnabled public String metalType;
        @AuraEnabled public String centerStoneWeightMin;
        @AuraEnabled public String centerStoneWeightMax;
        @AuraEnabled public String centerStoneClarity;
        @AuraEnabled public Boolean rollUpSubitemsChange;
        @AuraEnabled public String vendornum;
    }
    
}