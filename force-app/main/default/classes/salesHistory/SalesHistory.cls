public with sharing class SalesHistory {
  public class LineDetails {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String item;
    @AuraEnabled
    public Decimal quantity;
    @AuraEnabled
    public Decimal amount;
    @AuraEnabled
    public String preferredVendor;
    @AuraEnabled
    public String location;
    @AuraEnabled
    public String department;
    @AuraEnabled
    public String division;
    @AuraEnabled
    public Date trandate;
  }

  public class LineDetailsComparator implements Comparator<LineDetails> {
    public Integer compare(LineDetails row1, LineDetails row2) {
      Integer returnValue = 0;

      if (row1.trandate < row2.trandate) {
        returnValue = 1;
      } else if (row1.trandate > row2.trandate) {
        returnValue = -1;
      }

      return returnValue;
    }
  }

  public class SalesHistoryCursor {
    @AuraEnabled
    public DateTime lastDate;
    @AuraEnabled
    public Id lastId;
  }

  public class SalesHistoryResponse {
    @AuraEnabled
    public List<LineDetails> rows;
    @AuraEnabled
    public Boolean hasNext;
    @AuraEnabled
    public Boolean hasPrev;
    @AuraEnabled
    public SalesHistoryCursor nextCursor;
    @AuraEnabled
    public SalesHistoryCursor prevCursor;
  }

  public static List<SalesHistory.LineDetails> reverseLineDetails(
    List<SalesHistory.LineDetails> originalList
  ) {
    List<SalesHistory.LineDetails> reversedList = new List<SalesHistory.LineDetails>();

    for (Integer i = originalList.size() - 1; i >= 0; i--) {
      reversedList.add(originalList.get(i));
    }

    return reversedList;
  }

  @AuraEnabled(cacheable=true)
  public static SalesHistoryResponse getSalesHistory(
    String customer,
    Integer pageSize,
    String direction, // "NEXT" | "PREV"
    String cursorJson,
    String sortBy,
    String sortDirection
  ) {
    Map<String, String> sortMap = new Map<String, String>{
      'amount' => 'breadwinner_ns__Amount__c',
      'trandate' => 'breadwinner_ns__ParentTransDate__c'
    };

    Map<String, String> ascSortMap = new Map<String, String>{
      'amount' => 'custrecord_aschitempricepaid__c',
      'trandate' => 'custrecord_aschorderdate__c'
    };

    SalesHistoryCursor cursor = null;

    if (String.isNotBlank(cursorJson)) {
      cursor = (SalesHistoryCursor) JSON.deserialize(
        cursorJson,
        SalesHistoryCursor.class
      );
    }

    String sortField = sortMap.containsKey(sortBy)
      ? sortMap.get(sortBy)
      : 'breadwinner_ns__ParentTransDate__c';

    String ascSortField = ascSortMap.containsKey(sortBy)
      ? ascSortMap.get(sortBy)
      : 'custrecord_aschorderdate__c';

    String sortDir = (String.isNotBlank(sortDirection) &&
      sortDirection.toLowerCase() == 'asc')
      ? 'ASC'
      : 'DESC';

    Boolean isNext = (direction == null || direction == 'NEXT');

    String effectiveSortDir = isNext
      ? sortDir
      : (sortDir == 'DESC' ? 'ASC' : 'DESC');

    String whereClause = 'breadwinner_ns__Transaction_Type__c IN (\'Invoice\', \'CreditMemo\')';
    String ascWhereClause = '';

    if (String.isNotBlank(customer)) {
      whereClause += ' AND breadwinner_ns__ParentCompanyIDName__c = :customer';
    }

    if (cursor != null) {
      String formattedDate = cursor.lastDate.formatGMT('yyyy-MM-dd');

      String op = isNext
        ? (sortDir == 'DESC' ? '<' : '>')
        : (sortDir == 'DESC' ? '>' : '<');

      whereClause +=
        ' AND (' +
        sortField +
        ' ' +
        op +
        ' ' +
        formattedDate +
        ')';

      ascWhereClause +=
        'WHERE ' +
        ascSortField +
        ' ' +
        op +
        ' ' +
        formattedDate;
    }

    String query =
      'SELECT ' +
      'Id, ' +
      'breadwinner_ns__Item__r.Name, ' +
      'breadwinner_ns__Quantity__c, ' +
      'breadwinner_ns__Amount__c, ' +
      'breadwinner_ns__Item__r.ncf_item9__c, ' +
      'breadwinner_ns__LocationName__c, ' +
      'breadwinner_ns__ClassName__c, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__DepartmentName__c, ' +
      'breadwinner_ns__ParentTransDate__c ' +
      'FROM breadwinner_ns__BW_Line_Item__c ' +
      'WHERE ' +
      whereClause +
      ' ORDER BY ' +
      sortField +
      ' ' +
      effectiveSortDir +
      ', Id ' +
      effectiveSortDir +
      ' LIMIT :pageSize';

    String ascQuery =
      'SELECT ' +
      'Id, ' +
      'custrecord_aschsku__c, ' +
      'custrecord_aschitemqty__c, ' +
      'custrecord_aschitempricepaid__c, ' +
      'custrecord_aschvendor__c, ' +
      'custrecord_aschstore__c, ' +
      'custrecord_aschitemdepartment__c, ' +
      'custrecord_aschitemdivision__c, ' +
      'custrecord_aschorderdate__c ' +
      'FROM nco_aschistoricalsales__c ' +
      ascWhereClause +
      ' ORDER BY ' +
      ascSortField +
      ' ' +
      effectiveSortDir +
      ', Id ' +
      effectiveSortDir +
      ' LIMIT :pageSize';

    List<breadwinner_ns__BW_Line_Item__c> records = Database.query(query);
    List<nco_aschistoricalsales__c> ascRecords = Database.query(ascQuery);

    List<LineDetails> rows = new List<LineDetails>();

    for (breadwinner_ns__BW_Line_Item__c r : records) {
      LineDetails row = new LineDetails();
      row.id = r.Id;
      row.item = r.breadwinner_ns__Item__r?.Name;
      row.quantity = r.breadwinner_ns__Quantity__c;
      row.amount = r.breadwinner_ns__Amount__c;
      row.preferredVendor = r.breadwinner_ns__Item__r?.ncf_item9__c;
      row.location = r.breadwinner_ns__LocationName__c;
      row.division = r.breadwinner_ns__ClassName__c;
      row.department = r.breadwinner_ns__Item__r
        ?.breadwinner_ns__DepartmentName__c;
      row.trandate = r.breadwinner_ns__ParentTransDate__c;
      rows.add(row);
    }

    for (nco_aschistoricalsales__c r : ascRecords) {
      LineDetails row = new LineDetails();
      row.id = r.Id;
      row.item = r.custrecord_aschsku__c;
      row.quantity = r.custrecord_aschitemqty__c;
      row.amount = r.custrecord_aschitempricepaid__c;
      row.preferredVendor = r.custrecord_aschvendor__c;
      row.location = r.custrecord_aschstore__c;
      row.division = r.custrecord_aschitemdivision__c;
      row.department = r.custrecord_aschitemdepartment__c;
      row.trandate = r.custrecord_aschorderdate__c;
      rows.add(row);
    }

    rows.sort(new LineDetailsComparator());

    if (!isNext)
      rows = reverseLineDetails(rows);

    if (rows.size() > pageSize) {
      List<LineDetails> truncated = new List<LineDetails>();

      for (Integer i = 0; i < pageSize && i < rows.size(); i++) {
        truncated.add(rows[i]);
      }
      rows = truncated;
    }

    SalesHistoryResponse res = new SalesHistoryResponse();

    res.rows = rows;

    if (!rows.isEmpty()) {
      LineDetails first = rows[0];
      LineDetails last = rows[rows.size() - 1];

      res.prevCursor = new SalesHistoryCursor();
      res.prevCursor.lastDate = first.trandate;
      res.prevCursor.lastId = first.id;

      res.nextCursor = new SalesHistoryCursor();
      res.nextCursor.lastDate = last.trandate;
      res.nextCursor.lastId = last.id;
    }

    res.hasNext = rows.size() == pageSize;
    res.hasPrev = (cursor != null);

    return res;
  }
}
