@isTest
private class CustomerMapperTest {
  @isTest
  static void mapCustomer_success() {
    CustomerResModel.customer customer = new CustomerResModel.customer();

    customer.internalId = '12345';
    CustomerResModel.AddressBookAddress responseAddress = new CustomerResModel.AddressBookAddress();
    responseAddress.zip = '60601';
    responseAddress.state = 'IL';
    responseAddress.country = '_unitedStates';
    responseAddress.city = 'Chicago';
    responseAddress.attention = 'Front Desk';
    responseAddress.addressee = 'Grand Hotels & Resorts Ltd';
    responseAddress.addr2 = 'Suite 1500';
    responseAddress.addr1 = '2334 N. Michigan Avenue';

    CustomerResModel.AddressBookItem responseAddressBookItem = new CustomerResModel.AddressBookItem();
    responseAddressBookItem.addressbookAddress = responseAddress;
    responseAddressBookItem.internalId = '29188';

    CustomerResModel.AddressBookList responseAddressBookList = new CustomerResModel.AddressBookList();
    responseAddressBookList.addressbook = new List<CustomerResModel.AddressBookItem>{
      responseAddressBookItem
    };

    customer.addressbookList = responseAddressBookList;

    CustomerDataModel.CustomerData mappedCustomer = CustomerMappers.mapCustomer(
      customer
    );

    System.assertEquals(mappedCustomer.custNsInternalId, customer.internalId);
    System.assertEquals(1, mappedCustomer.Addresses.size());

    CustomerDataModel.Address mappedAddress = mappedCustomer.Addresses[0];

    System.assertEquals('60601', mappedAddress.zip);
    System.assertEquals('IL', mappedAddress.state);
    System.assertEquals('29188', mappedAddress.internalId);
    System.assertEquals('_unitedStates', mappedAddress.country);
    System.assertEquals('Chicago', mappedAddress.city);
    System.assertEquals('Front Desk', mappedAddress.attention);
    System.assertEquals('Grand Hotels & Resorts Ltd', mappedAddress.addressee);
    System.assertEquals('Suite 1500', mappedAddress.addr2);
    System.assertEquals('2334 N. Michigan Avenue', mappedAddress.addr1);
  }
}
