public with sharing class ReportModels {
  public class ReportRequest {
    public String reportKey;
    public Map<String, Object> filters;
    public Integer pageSize;
    public Integer offsetSize;
    public String sortBy;
    public String sortDirection;
  }

  public class FilterDefinition {
    public String key;
    public String field;
    public String operator;
    public Object value;
    public String valueType;
  }

  public class ParsedFilterDefinition {
    public String sourceObject;
    public Boolean isActive;
    public List<String> selectExpressions;
    public List<FilterDefinition> baseFilters;
    public List<FilterDefinition> runtimeFilters;
    public List<String> groupByFields;
    public Map<String, String> sortFields;
    public String defaultSort;
  }

  public class ReportPage {
    @AuraEnabled
    public List<SObject> rows;
    @AuraEnabled
    public Boolean hasMore;
    @AuraEnabled
    public Integer pageSize;
    @AuraEnabled
    public Integer offsetSize;
  }

  public class QuerySpec {
    public String soql;
    public Map<String, Object> binds;

    public QuerySpec(String soql, Map<String, Object> binds) {
      this.soql = soql;
      this.binds = binds;
    }
  }
}
