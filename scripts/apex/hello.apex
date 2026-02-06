SELECT Id, Birthdate__c, OwnerId
FROM Account
WHERE Birthdate__c != NULL 
AND CALENDAR_MONTH(Birthdate__c) = 3