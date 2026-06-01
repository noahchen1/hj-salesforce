public with sharing class CustomerMappers {
  public static CustomerDataModel.CustomerData mapCustomer(
    CustomerResModel.customer customer
  ) {
    CustomerDataModel.CustomerData result = new CustomerDataModel.CustomerData();

    result.custNsInternalId = customer.internalId;
    result.Addresses = new List<CustomerDataModel.Address>();

    if (
      customer.addressbookList == null ||
      customer.addressbookList.addressbook == null
    ) {
      return result;
    }

    for (
      CustomerResModel.AddressBookItem address : customer.addressbookList.addressbook
    ) {
      if (address == null || address.addressbookAddress == null) {
        continue;
      }

      CustomerDataModel.Address addrData = new CustomerDataModel.Address();
      addrData.zip = address.addressbookAddress.zip;
      addrData.state = address.addressbookAddress.state;
      addrData.country = address.addressbookAddress.country;
      addrData.city = address.addressbookAddress.city;
      addrData.attention = address.addressbookAddress.attention;
      addrData.addressee = address.addressbookAddress.addressee;
      addrData.addr2 = address.addressbookAddress.addr2;
      addrData.addr1 = address.addressbookAddress.addr1;
      addrData.defaultShipping = address.defaultShipping;
      addrData.defaultBilling = address.defaultBilling;
      addrData.internalId = address.internalId;

      result.Addresses.add(addrData);
    }

    return result;
  }

  public static CustomerDataModel.Address deserializeAddress(
    String addressJson
  ) {
    if (String.isBlank(addressJson)) {
      return null;
    }

    try {
      return (CustomerDataModel.Address) JSON.deserialize(
        addressJson,
        CustomerDataModel.Address.class
      );
    } catch (Exception err) {
      AuraHandledException e = new AuraHandledException(
        'Invalid line address payload: ' + err.getMessage()
      );

      e.setMessage('Invalid line address payload: ' + err.getMessage());

      throw e;
    }
  }
}
