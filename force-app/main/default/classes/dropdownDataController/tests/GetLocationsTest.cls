@isTest
private class GetLocationsTest {
  @isTest
  static void testGetLocations() {
    breadwinner_ns__BW_Sales_Order__c order1 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order1',
      breadwinner_ns__LocationName__c = 'Location A'
    );
    breadwinner_ns__BW_Sales_Order__c order2 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order2',
      breadwinner_ns__LocationName__c = 'Location B'
    );
    breadwinner_ns__BW_Sales_Order__c order3 = new breadwinner_ns__BW_Sales_Order__c(
      Name = 'Order3',
      breadwinner_ns__LocationName__c = 'Location A'
    );
    insert new List<breadwinner_ns__BW_Sales_Order__c>{
      order1,
      order2,
      order3
    };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getLocations();
    Test.stopTest();

    System.assertEquals(
      2,
      options.size(),
      'Should return two unique locations'
    );
    Set<String> locationNames = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      locationNames.add(opt.label);
      System.assertEquals(opt.label, opt.value, 'Label and value should match');
    }
    System.assert(
      locationNames.contains('Location A'),
      'Should contain Location A'
    );
    System.assert(
      locationNames.contains('Location B'),
      'Should contain Location B'
    );
  }
}
