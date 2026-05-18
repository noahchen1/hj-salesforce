
@isTest
private class GetSubsidiariesTest {
    @isTest
    static void testGetSubsidiaries_returnsOnlyAllowedSubsidiaries() {
        breadwinner_ns__BW_Subsidiary__c includedOne = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Included Subsidiary 1',
            breadwinner_ns__InternalId__c = '10'
        );
        breadwinner_ns__BW_Subsidiary__c includedTwo = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Included Subsidiary 2',
            breadwinner_ns__InternalId__c = '40'
        );

        // These should be filtered out by controller logic.
        breadwinner_ns__BW_Subsidiary__c excluded31 = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Excluded 31',
            breadwinner_ns__InternalId__c = '31'
        );
        breadwinner_ns__BW_Subsidiary__c excluded32 = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Excluded 32',
            breadwinner_ns__InternalId__c = '32'
        );
        breadwinner_ns__BW_Subsidiary__c excluded33 = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Excluded 33',
            breadwinner_ns__InternalId__c = '33'
        );

        insert new List<breadwinner_ns__BW_Subsidiary__c>{
            includedOne,
            includedTwo,
            excluded31,
            excluded32,
            excluded33
        };

        Test.startTest();
        List<DropdownDataController.Option> options = DropdownDataController.getSubsidiaries();
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Should return only subsidiaries not excluded by internal id');

        Set<String> labels = new Set<String>();
        Set<String> values = new Set<String>();
        for (DropdownDataController.Option option : options) {
            labels.add(option.label);
            values.add(option.value);
        }

        System.assert(labels.contains('Included Subsidiary 1'), 'Should include first allowed subsidiary');
        System.assert(labels.contains('Included Subsidiary 2'), 'Should include second allowed subsidiary');
        System.assert(values.contains('10'), 'Should include allowed internal id 10');
        System.assert(values.contains('40'), 'Should include allowed internal id 40');
        System.assert(!values.contains('31'), 'Should not include internal id 31');
        System.assert(!values.contains('32'), 'Should not include internal id 32');
        System.assert(!values.contains('33'), 'Should not include internal id 33');
    }

    @isTest
    static void testGetSubsidiaries_returnsEmptyWhenOnlyExcludedExist() {
        breadwinner_ns__BW_Subsidiary__c excluded31 = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Excluded 31',
            breadwinner_ns__InternalId__c = '31'
        );
        breadwinner_ns__BW_Subsidiary__c excluded32 = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Excluded 32',
            breadwinner_ns__InternalId__c = '32'
        );
        breadwinner_ns__BW_Subsidiary__c excluded33 = new breadwinner_ns__BW_Subsidiary__c(
            Name = 'Excluded 33',
            breadwinner_ns__InternalId__c = '33'
        );

        insert new List<breadwinner_ns__BW_Subsidiary__c>{
            excluded31,
            excluded32,
            excluded33
        };

        Test.startTest();
        List<DropdownDataController.Option> options = DropdownDataController.getSubsidiaries();
        Test.stopTest();

        System.assertEquals(0, options.size(), 'Should return empty list when only excluded subsidiaries exist');
    }
}