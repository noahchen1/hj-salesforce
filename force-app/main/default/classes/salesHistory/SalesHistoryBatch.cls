public with sharing class SalesHistoryBatch implements Database.Batchable<sObject>, Database.Stateful {
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

    // public Integer compareTo(Object compareTo) {
    //   LineDetails that = (LineDetails) compareTo;
    //   // Newest first (descending trandate)
    //   if (this.trandate == that.trandate)
    //     return 0;
    //   if (this.trandate == null)
    //     return 1;
    //   if (that.trandate == null)
    //     return -1;
    //   return that.trandate.compareTo(this.trandate);
    // }
  }

  // Stateful - keeps top 50 across all batches
  private List<LineDetails> top50 = new List<LineDetails>();

  // Custom Iterator to chain two QueryLocators
  public class ChainedQueryLocatorIterator implements Iterator<sObject> {
    private Iterator<sObject> current;
    private Iterator<sObject> nextIterator;

    public ChainedQueryLocatorIterator(
      Iterator<sObject> first,
      Iterator<sObject> second
    ) {
      this.current = first;
      this.nextIterator = second;
    }

    public Boolean hasNext() {
      if (current.hasNext())
        return true;
      if (nextIterator != null) {
        current = nextIterator;
        nextIterator = null;
        return current.hasNext();
      }
      return false;
    }

    public sObject next() {
      return current.next();
    }
  }

  // Custom Iterable that returns the chained iterator
  public class ChainedIterable implements Iterable<sObject> {
    private String query1;
    private String query2;

    public ChainedIterable(String q1, String q2) {
      this.query1 = q1;
      this.query2 = q2;
    }

    public Iterator<sObject> iterator() {
      Database.QueryLocator ql1 = Database.getQueryLocator(query1);
      Database.QueryLocator ql2 = Database.getQueryLocator(query2);
      return new ChainedQueryLocatorIterator(ql1.iterator(), ql2.iterator());
    }
  }

  public Iterable<sObject> start(Database.BatchableContext bc) {
    String query1 =
      'SELECT Id, breadwinner_ns__Item__r.Name, breadwinner_ns__Quantity__c, breadwinner_ns__Amount__c, ' +
      'breadwinner_ns__Item__r.ncf_item9__c, breadwinner_ns__LocationName__c, breadwinner_ns__ClassName__c, ' +
      'breadwinner_ns__Item__r.breadwinner_ns__DepartmentName__c, breadwinner_ns__ParentTransDate__c ' +
      'FROM breadwinner_ns__BW_Line_Item__c ' +
      'ORDER BY breadwinner_ns__ParentTransDate__c DESC'; // optional optimization

    String query2 =
      'SELECT Id, custrecord_aschsku__c, custrecord_aschitemqty__c, custrecord_aschitempricepaid__c, ' +
      'custrecord_aschvendor__c, custrecord_aschstore__c, custrecord_aschitemdepartment__c, ' +
      'custrecord_aschitemdivision__c, custrecord_aschorderdate__c ' +
      'FROM nco_aschistoricalsales__c ' +
      'ORDER BY custrecord_aschorderdate__c DESC'; // optional optimization

    return new ChainedIterable(query1, query2);
  }

  public void execute(Database.BatchableContext bc, List<sObject> scope) {
    for (sObject record : scope) {
      LineDetails ld = new LineDetails();

      if (record instanceof breadwinner_ns__BW_Line_Item__c) {
        breadwinner_ns__BW_Line_Item__c li = (breadwinner_ns__BW_Line_Item__c) record;
        ld.id = li.Id;
        ld.item = li.breadwinner_ns__Item__r?.Name;
        ld.quantity = li.breadwinner_ns__Quantity__c;
        ld.amount = li.breadwinner_ns__Amount__c;
        ld.preferredVendor = li.breadwinner_ns__Item__r?.ncf_item9__c;
        ld.location = li.breadwinner_ns__LocationName__c;
        ld.division = li.breadwinner_ns__ClassName__c;
        ld.department = li.breadwinner_ns__Item__r
          ?.breadwinner_ns__DepartmentName__c;
        ld.trandate = li.breadwinner_ns__ParentTransDate__c;
      } else if (record instanceof nco_aschistoricalsales__c) {
        nco_aschistoricalsales__c hist = (nco_aschistoricalsales__c) record;
        ld.id = hist.Id;
        ld.item = hist.custrecord_aschsku__c;
        ld.quantity = hist.custrecord_aschitemqty__c;
        ld.amount = hist.custrecord_aschitempricepaid__c;
        ld.preferredVendor = hist.custrecord_aschvendor__c;
        ld.location = hist.custrecord_aschstore__c;
        ld.division = hist.custrecord_aschitemdivision__c;
        ld.department = hist.custrecord_aschitemdepartment__c;
        ld.trandate = hist.custrecord_aschorderdate__c;
      }

      if (ld.trandate != null) {
        top50.add(ld);

        if (top50.size() > 50) {
          top50.remove(50); // keep newest 50
        }
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
    try {
      Cache.OrgPartition partition = Cache.Org.getPartition('default');
      String jsonData = JSON.serialize(top50);
      partition.put('SalesHistoryRecent50', jsonData);

      // Optional debug
      Object cached = partition.get('SalesHistoryRecent50');
      System.debug(
        'Cached SalesHistoryRecent50 size: ' +
        (cached != null ? ((String) cached).length() : 0)
      );
    } catch (Exception e) {
      System.debug('Cache put failed: ' + e.getMessage());
    }
  }
}
