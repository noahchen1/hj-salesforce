List<breadwinner_ns__BW_Line_Item__c> item = [
    SELECT
    Id
    FROM breadwinner_ns__BW_Line_Item__c
    WHERE Id = 'a0XWJ000002FqH5'
];

System.debug('Item: ' + item);