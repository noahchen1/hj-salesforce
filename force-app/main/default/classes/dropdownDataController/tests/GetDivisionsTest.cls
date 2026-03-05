@isTest
private class GetDivisionsTest {
  @isTest
  static void testGetDivisions_success() {
    Sales_History__c salesHistory1 = new Sales_History__c(
      Name = 'Test Record 1',
      Division__c = 'Division A'
    );
    Sales_History__c salesHistory2 = new Sales_History__c(
      Name = 'Test Record 2',
      Division__c = 'Division B'
    );
    Sales_History__c salesHistory3 = new Sales_History__c(
      Name = 'Test Record 3',
      Division__c = 'Division A'
    );
    insert new List<Sales_History__c>{
      salesHistory1,
      salesHistory2,
      salesHistory3
    };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getDivisions();
    Test.stopTest();

    System.assertEquals(
      2,
      options.size(),
      'Should return two unique divisions'
    );
    Set<String> divisionNames = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      divisionNames.add(opt.label);
      System.assertEquals(opt.label, opt.value, 'Label and value should match');
    }
    System.assert(
      divisionNames.contains('Division A'),
      'Should contain Division A'
    );
    System.assert(
      divisionNames.contains('Division B'),
      'Should contain Division B'
    );
  }

  @isTest
  static void testGetDivisions_excludesOpeningBalanceAndShipping() {
    Sales_History__c salesHistory1 = new Sales_History__c(
      Name = 'Test Record 1',
      Division__c = 'Division A'
    );
    Sales_History__c salesHistory2 = new Sales_History__c(
      Name = 'Test Record 2',
      Division__c = 'Opening Balance'
    );
    Sales_History__c salesHistory3 = new Sales_History__c(
      Name = 'Test Record 3',
      Division__c = 'Shipping (7)'
    );
    insert new List<Sales_History__c>{
      salesHistory1,
      salesHistory2,
      salesHistory3
    };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getDivisions();
    Test.stopTest();

    System.assertEquals(1, options.size(), 'Should return only one division');
    System.assertEquals(
      'Division A',
      options[0].label,
      'Should return only Division A'
    );
  }

  @isTest
  static void testGetDivisions_emptyResults() {
    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getDivisions();
    Test.stopTest();

    System.assertEquals(0, options.size(), 'Should return empty list');
  }
}
