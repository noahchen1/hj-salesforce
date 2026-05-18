
@isTest
private class GetSubsidiaryLocationsTest {
    @isTest
    static void testGetSubsidiaryLocations_returnsLocationsForMatchingSubsidiary() {
        breadwinner_ns__BW_Subsidiary__c subA = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Subsidiary A',
            breadwinner_ns__InternalId__c = 'SUB-A'
        );
        breadwinner_ns__BW_Subsidiary__c subB = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Subsidiary B',
            breadwinner_ns__InternalId__c = 'SUB-B'
        );
        insert new List<breadwinner_ns__BW_Subsidiary__c>{ subA, subB };

        breadwinner_ns__BW_Location__c locA1 = new breadwinner_ns__BW_Location__c(
            Name = 'Location A1',
            breadwinner_ns__InternalId__c = 'LOC-A1',
            breadwinner_ns__Subsidiary__c = subA.Id
        );
        breadwinner_ns__BW_Location__c locA2 = new breadwinner_ns__BW_Location__c(
            Name = 'Location A2',
            breadwinner_ns__InternalId__c = 'LOC-A2',
            breadwinner_ns__Subsidiary__c = subA.Id
        );
        breadwinner_ns__BW_Location__c locB1 = new breadwinner_ns__BW_Location__c(
            Name = 'Location B1',
            breadwinner_ns__InternalId__c = 'LOC-B1',
            breadwinner_ns__Subsidiary__c = subB.Id
        );
        insert new List<breadwinner_ns__BW_Location__c>{ locA1, locA2, locB1 };

        Test.startTest();
        List<DropdownDataController.Option> options = DropdownDataController.getSubsidiaryLocations(
            'SUB-A'
        );
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Should return only locations for subsidiary SUB-A');

        Set<String> labels = new Set<String>();
        Set<String> values = new Set<String>();
        for (DropdownDataController.Option option : options) {
            labels.add(option.label);
            values.add(option.value);
        }

        System.assert(labels.contains('Location A1'), 'Should include Location A1');
        System.assert(labels.contains('Location A2'), 'Should include Location A2');
        System.assert(!labels.contains('Location B1'), 'Should not include location from other subsidiary');
        System.assert(values.contains('LOC-A1'), 'Should include internal id LOC-A1');
        System.assert(values.contains('LOC-A2'), 'Should include internal id LOC-A2');
        System.assert(!values.contains('LOC-B1'), 'Should not include internal id LOC-B1');
    }

    @isTest
    static void testGetSubsidiaryLocations_returnsEmptyWhenNoLocationsMatch() {
        breadwinner_ns__BW_Subsidiary__c sub = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Subsidiary C',
            breadwinner_ns__InternalId__c = 'SUB-C'
        );
        insert sub;

        Test.startTest();
        List<DropdownDataController.Option> options = DropdownDataController.getSubsidiaryLocations(
            'NON-EXISTENT'
        );
        Test.stopTest();

        System.assertEquals(0, options.size(), 'Should return empty list when no locations match the subsidiary');
    }
}