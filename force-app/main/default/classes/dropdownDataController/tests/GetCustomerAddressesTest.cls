@isTest
private class GetCustomerAddressesTest {
    @isTest
    static void testGetCustomerAddresses_returnsMappedAddressOptions() {
        breadwinner_ns__BW_Company__c company = new breadwinner_ns__BW_Company__c(
            Name = 'Test Customer',
            breadwinner_ns__InternalId__c = 'CUST-001'
        );
        insert company;

        breadwinner_ns__BW_Company__c otherCompany = new breadwinner_ns__BW_Company__c(
            Name = 'Other Customer',
            breadwinner_ns__InternalId__c = 'CUST-002'
        );
        insert otherCompany;

        breadwinner_ns__BW_Address__c address1 = new breadwinner_ns__BW_Address__c(
            breadwinner_ns__Company__c = company.Id,
            breadwinner_ns__AddrText__c = '100 Main St',
            breadwinner_ns__DefaultShipping__c = true,
            breadwinner_ns__DefaultBilling__c = false,
            breadwinner_ns__InternalId__c = 'ADDR-001'
        );
        breadwinner_ns__BW_Address__c address2 = new breadwinner_ns__BW_Address__c(
            breadwinner_ns__Company__c = company.Id,
            breadwinner_ns__AddrText__c = '200 Oak Ave',
            breadwinner_ns__DefaultShipping__c = false,
            breadwinner_ns__DefaultBilling__c = true,
            breadwinner_ns__InternalId__c = 'ADDR-002'
        );
        breadwinner_ns__BW_Address__c addressOther = new breadwinner_ns__BW_Address__c(
            breadwinner_ns__Company__c = otherCompany.Id,
            breadwinner_ns__AddrText__c = '999 Ignore Rd',
            breadwinner_ns__DefaultShipping__c = true,
            breadwinner_ns__DefaultBilling__c = true,
            breadwinner_ns__InternalId__c = 'ADDR-999'
        );
        insert new List<breadwinner_ns__BW_Address__c>{
            address1,
            address2,
            addressOther
        };

        Test.startTest();
        List<DropdownDataController.AddressOption> options = DropdownDataController.getCustomerAddresses(
            company.Id
        );
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Should return only selected company addresses');

        Set<String> labels = new Set<String>();
        Set<String> internalIds = new Set<String>();
        Boolean foundDefaultShipping = false;
        Boolean foundDefaultBilling = false;

        for (DropdownDataController.AddressOption option : options) {
            labels.add(option.label);
            internalIds.add(option.nsInternalId);

            if (option.isDefaultShipping == true) {
                foundDefaultShipping = true;
            }
            if (option.isDefaultBilling == true) {
                foundDefaultBilling = true;
            }
        }

        System.assert(labels.contains('100 Main St'), 'Should include first address label');
        System.assert(labels.contains('200 Oak Ave'), 'Should include second address label');
        System.assert(internalIds.contains('ADDR-001'), 'Should include first address internal id');
        System.assert(internalIds.contains('ADDR-002'), 'Should include second address internal id');
        System.assertEquals(true, foundDefaultShipping, 'Should map default shipping flag');
        System.assertEquals(true, foundDefaultBilling, 'Should map default billing flag');
    }

    @isTest
    static void testGetCustomerAddresses_returnsEmptyWhenNoAddressesExist() {
        breadwinner_ns__BW_Company__c company = new breadwinner_ns__BW_Company__c(
            Name = 'No Address Customer',
            breadwinner_ns__InternalId__c = 'CUST-003'
        );
        insert company;

        Test.startTest();
        List<DropdownDataController.AddressOption> options = DropdownDataController.getCustomerAddresses(
            company.Id
        );
        Test.stopTest();

        System.assertEquals(0, options.size(), 'Should return no options for customer without addresses');
    }
}