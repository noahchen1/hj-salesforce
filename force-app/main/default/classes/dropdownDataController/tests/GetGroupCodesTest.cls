@isTest
private class GetGroupCodesTest {
  @isTest
  static void testGetGroupCodes_success() {
    Sales_History__c salesHistory1 = new Sales_History__c(
      Name = 'Test Record 1',
      Group_Code__c = 'Group A'
    );
    Sales_History__c salesHistory2 = new Sales_History__c(
      Name = 'Test Record 2',
      Group_Code__c = 'Group B'
    );
    Sales_History__c salesHistory3 = new Sales_History__c(
      Name = 'Test Record 3',
      Group_Code__c = 'Group A'
    );
    insert new List<Sales_History__c>{
      salesHistory1,
      salesHistory2,
      salesHistory3
    };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getGroupCodes();
    Test.stopTest();

    System.assertEquals(
      2,
      options.size(),
      'Should return two unique group codes'
    );
    Set<String> groupCodeNames = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      groupCodeNames.add(opt.label);
      System.assertEquals(opt.label, opt.value, 'Label and value should match');
    }
    System.assert(groupCodeNames.contains('Group A'), 'Should contain Group A');
    System.assert(groupCodeNames.contains('Group B'), 'Should contain Group B');
  }

  @isTest
  static void testGetGroupCodes_emptyResults() {
    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getGroupCodes();
    Test.stopTest();

    System.assertEquals(0, options.size(), 'Should return empty list');
  }
}
