Id nsJobId = Database.executeBatch(new NsSalesHistoryBatch(), 200);
System.debug('nsJobId: ' + nsJobId);
Id ascJobId = Database.executeBatch(new AscSalesHistoryBatch(), 200);
System.debug('ascJobId: ' + ascJobId);
