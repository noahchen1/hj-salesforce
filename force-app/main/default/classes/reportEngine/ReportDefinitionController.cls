public with sharing class ReportDefinitionController {
  @AuraEnabled(cacheable=true)
  public static ReportDefinitions.Definition getUiDefinition(String reportKey) {
    ReportDefinitions.Definition definition = ReportDefinitions.get(reportKey);
    if (definition == null || !definition.isActive) {
      throw new AuraHandledException('The requested report is unavailable.');
    }
    return definition;
  }
}
