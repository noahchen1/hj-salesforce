@isTest
private class GetDepartmentsTest {
  @isTest
  static void testGetDepartments_success() {
    Sales_History__c salesHistory1 = new Sales_History__c(
      Name = 'Test Record 1',
      Department__c = 'Department A'
    );
    Sales_History__c salesHistory2 = new Sales_History__c(
      Name = 'Test Record 2',
      Department__c = 'Department B'
    );
    Sales_History__c salesHistory3 = new Sales_History__c(
      Name = 'Test Record 3',
      Department__c = 'Department A'
    );
    insert new List<Sales_History__c>{
      salesHistory1,
      salesHistory2,
      salesHistory3
    };

    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getDepartments();
    Test.stopTest();

    System.assertEquals(
      2,
      options.size(),
      'Should return two unique departments'
    );
    Set<String> departmentNames = new Set<String>();
    for (DropdownDataController.Option opt : options) {
      departmentNames.add(opt.label);
      System.assertEquals(opt.label, opt.value, 'Label and value should match');
    }
    System.assert(
      departmentNames.contains('Department A'),
      'Should contain Department A'
    );
    System.assert(
      departmentNames.contains('Department B'),
      'Should contain Department B'
    );
  }

  @isTest
  static void testGetDepartments_emptyResults() {
    Test.startTest();
    List<DropdownDataController.Option> options = DropdownDataController.getDepartments();
    Test.stopTest();

    System.assertEquals(0, options.size(), 'Should return empty list');
  }
}
