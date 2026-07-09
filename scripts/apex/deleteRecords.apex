ObjectMassDelete batch = new ObjectMassDelete('nco_message_history__c');
Database.executeBatch(batch, 2000);