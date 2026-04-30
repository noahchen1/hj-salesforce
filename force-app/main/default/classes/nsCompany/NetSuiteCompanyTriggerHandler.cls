public with sharing class NetSuiteCompanyTriggerHandler {
  public static Boolean bypassAccountCreation = false;
  private static Boolean isExecuting = false;
  private static final Logger LOGGER = new Logger(
    NetSuiteCompanyTriggerHandler.class.getName()
  );

  public void handleAfterInsert(List<breadwinner_ns__BW_Company__c> companies) {
    if (isExecuting || bypassAccountCreation)
      return;
    isExecuting = true;

    upsertAccounts(companies);
  }

  public void handleAfterUpdate(
    List<breadwinner_ns__BW_Company__c> companies,
    Map<Id, breadwinner_ns__BW_Company__c> oldCompanies
  ) {
    if (isExecuting || bypassAccountCreation)
      return;
    isExecuting = true;
    List<breadwinner_ns__BW_Company__c> validCompanies = new List<breadwinner_ns__BW_Company__c>();

    for (breadwinner_ns__BW_Company__c company : companies) {
      if (isCompanyChaned(company, oldCompanies)) {
        validCompanies.add(company);
      }
    }
    upsertAccounts(validCompanies);
  }

  public void upsertAccounts(List<breadwinner_ns__BW_Company__c> companies) {
    try {
      List<Account> accounts = getAccounts(companies, getSalesReps(companies));

      Database.UpsertResult[] upsertResults = Database.upsert(
        accounts,
        Account.NetSuiteInternalId__c,
        false
      );
      logErrors(upsertResults, accounts);
      updateCompanies(companies, upsertResults, accounts);
    } catch (Exception ex) {
      LOGGER.logError(ex);
    } finally {
      LOGGER.publishLogs();
      isExecuting = false;
    }
  }

  private List<Account> getAccounts(
    List<breadwinner_ns__BW_Company__c> companies,
    Set<String> salesReps
  ) {
    Map<String, Id> salesRepToUserId = UserSalesRepService.getSalesRepToUserIdMap(
      salesReps
    );

    Map<String, Account> accounts = new Map<String, Account>();

    for (breadwinner_ns__BW_Company__c company : companies) {
      Boolean isVendor = company.breadwinner_ns__Entity_Type__c == 'Vendor';

      if (isVendor) {
        continue;
      }
      Account acc = new Account();

      acc.NetSuiteInternalId__c = company.breadwinner_ns__InternalId__c;
      acc.Subsidiary__c = company.breadwinner_ns__Subsidiary__c;
      acc.Name = company.Name;
      acc.First_Name__c = company.breadwinner_ns__FirstName__c;
      acc.Middle_Name__c = company.breadwinner_ns__MiddleName__c;
      acc.Last_Name__c = company.breadwinner_ns__LastName__c;
      acc.Email__c = company.breadwinner_ns__Email__c;
      acc.Phone = company.breadwinner_ns__Phone__c;
      acc.Mobile_Phone__c = company.breadwinner_ns__MobilePhone__c;
      acc.BillingStreet =
        company.breadwinner_ns__BillingAddr1__c +
        (String.isNotBlank(company.breadwinner_ns__BillingAddr2__c)
          ? ', ' + company.breadwinner_ns__BillingAddr2__c
          : '');
      acc.BillingCity = company.breadwinner_ns__BillingCity__c;
      acc.BillingPostalCode = company.breadwinner_ns__BillingZip__c;
      acc.BillingStateCode = company.breadwinner_ns__BillingState__c;
      acc.BillingCountryCode = getCountryCode(
        company.breadwinner_ns__BillingCountry__c
      );
      acc.BillingCountry = company.breadwinner_ns__BillingCountry__c;
      // acc.BillingState = getStateNameByCode(company.breadwinner_ns__BillingState__c);
      acc.Gender__c = PicklistHelper.getPicklistApiNameByLabel(
        Account.SObjectType,
        Account.Gender__c,
        company.ncf_entity1__c
      );
      acc.AccountSource = PicklistHelper.getPicklistApiNameByLabel(
        Account.SObjectType,
        Account.AccountSource,
        company.ncf_entity_hamiltonleadsource__c
      );
      acc.Sales_Rep__c = company.breadwinner_ns__SalesRepName__c;
      acc.Birthdate__c = company.ncf_entity_birthdate__c;
      acc.Anniversary__c = company.ncf_entity_anniversary__c;
      acc.Lifetime_Spend_ASC_Text__c = company.ncf_entity_lifetime_spend_asc__c;
      acc.Total_Lifetime_Spend_Text__c = company.ncf_entity_lifetime_spend__c;
      acc.Ranking__c = company.ncf_entity2__c;
      acc.Is_Service_Only__c = company.ncf_entity_is_service_only__c;
      acc.Is_New_Customer__c = company.ncf_entity_is_new_customer__c;

      acc.Salutation__c = company.breadwinner_ns__Salutation__c;
      acc.Billing_Address_1__c = company.breadwinner_ns__BillingAddr1__c;
      acc.Billing_Address_2__c = company.breadwinner_ns__BillingAddr2__c;
      acc.DateCreatedInNetsuite__c = company.breadwinner_ns__DateCreated__c;

      acc.Is_Updated_by_NetSuite_Company__c = true;

      if (String.isNotBlank(company.breadwinner_ns__SalesRepName__c)) {
        String salesRep = company.breadwinner_ns__SalesRepName__c;

        if (salesRepToUserId.containsKey(salesRep)) {
          Id userId = salesRepToUserId.get(salesRep);
          acc.Recent_Sales_Rep__c = userId;
          acc.OwnerId = userId;
        }
      }

      accounts.put(acc.NetSuiteInternalId__c, acc);
    }

    return accounts.values();
  }

  public static String getCountryCode(String countryName) {
    for (
      Schema.PicklistEntry entry : Account.BillingCountryCode.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.getLabel().equalsIgnoreCase(countryName)) {
        return entry.getValue();
      }
    }
    return null;
  }

  private Set<String> getSalesReps(
    List<breadwinner_ns__BW_Company__c> companies
  ) {
    Set<String> salesReps = new Set<String>();

    for (breadwinner_ns__BW_Company__c company : companies) {
      if (String.isNotBlank(company.breadwinner_ns__SalesRepName__c)) {
        salesReps.add(company.breadwinner_ns__SalesRepName__c);
      }
    }

    return salesReps;
  }

  private void logErrors(
    Database.UpsertResult[] upsertResults,
    List<Account> accounts
  ) {
    for (Integer i = 0; i < upsertResults.size(); i++) {
      if (!upsertResults[i].isSuccess()) {
        Database.Error error = upsertResults[i].getErrors()[0];

        LOGGER.logError(
          new CustomException(
            error.getMessage() +
              ' | Fields: ' +
              error.getFields() +
              ' | Status: ' +
              error.getStatusCode()
          ),
          (accounts[i].Id == null
            ? accounts[i].NetSuiteInternalId__c
            : accounts[i].Id)
        );
      }
    }
  }

  private void updateCompanies(
    List<breadwinner_ns__BW_Company__c> companies,
    Database.UpsertResult[] upsertResults,
    List<Account> accounts
  ) {
    List<breadwinner_ns__BW_Company__c> companiesToUpdate = new List<breadwinner_ns__BW_Company__c>();

    for (Integer i = 0; i < upsertResults.size(); i++) {
      if (companies[i].breadwinner_ns__Salesforce_Account__c != null)
        continue;

      if (upsertResults[i].isSuccess()) {
        companiesToUpdate.add(
          new breadwinner_ns__BW_Company__c(
            Id = companies[i].Id,
            breadwinner_ns__Salesforce_Account__c = accounts[i].Id
          )
        );
      }
    }
    update companiesToUpdate;
  }

  private Boolean isCompanyChaned(
    breadwinner_ns__BW_Company__c company,
    Map<Id, breadwinner_ns__BW_Company__c> oldCompanies
  ) {
    breadwinner_ns__BW_Company__c oldCompany = oldCompanies.get(company.Id);

    return company.breadwinner_ns__InternalId__c !=
      oldCompany.breadwinner_ns__InternalId__c ||
      company.breadwinner_ns__Subsidiary__c !=
      oldCompany.breadwinner_ns__Subsidiary__c ||
      company.breadwinner_ns__FirstName__c !=
      oldCompany.breadwinner_ns__FirstName__c ||
      company.breadwinner_ns__MiddleName__c !=
      oldCompany.breadwinner_ns__MiddleName__c ||
      company.breadwinner_ns__LastName__c !=
      oldCompany.breadwinner_ns__LastName__c ||
      company.breadwinner_ns__Email__c != oldCompany.breadwinner_ns__Email__c ||
      company.breadwinner_ns__Phone__c != oldCompany.breadwinner_ns__Phone__c ||
      company.breadwinner_ns__MobilePhone__c !=
      oldCompany.breadwinner_ns__MobilePhone__c ||
      company.breadwinner_ns__BillingAddr1__c !=
      oldCompany.breadwinner_ns__BillingAddr1__c ||
      company.breadwinner_ns__BillingCity__c !=
      oldCompany.breadwinner_ns__BillingCity__c ||
      company.breadwinner_ns__BillingZip__c !=
      oldCompany.breadwinner_ns__BillingZip__c ||
      company.breadwinner_ns__BillingState__c !=
      oldCompany.breadwinner_ns__BillingState__c ||
      company.breadwinner_ns__BillingCountry__c !=
      oldCompany.breadwinner_ns__BillingCountry__c ||
      company.ncf_entity1__c != oldCompany.ncf_entity1__c ||
      company.ncf_entity_hamiltonleadsource__c !=
      oldCompany.ncf_entity_hamiltonleadsource__c ||
      company.breadwinner_ns__SalesRepName__c !=
      oldCompany.breadwinner_ns__SalesRepName__c ||
      company.ncf_entity_birthdate__c != oldCompany.ncf_entity_birthdate__c ||
      company.ncf_entity_anniversary__c !=
      oldCompany.ncf_entity_anniversary__c ||
      company.ncf_entity_lifetime_spend_asc__c !=
      oldCompany.ncf_entity_lifetime_spend_asc__c ||
      company.ncf_entity_lifetime_spend__c !=
      oldCompany.ncf_entity_lifetime_spend__c ||
      company.ncf_entity2__c != oldCompany.ncf_entity2__c ||
      company.ncf_entity_is_service_only__c !=
      oldCompany.ncf_entity_is_service_only__c ||
      company.ncf_entity_is_new_customer__c !=
      company.ncf_entity_is_new_customer__c ||
      company.breadwinner_ns__Salutation__c !=
      company.breadwinner_ns__Salutation__c ||
      company.Name != oldCompany.Name;
  }
}
