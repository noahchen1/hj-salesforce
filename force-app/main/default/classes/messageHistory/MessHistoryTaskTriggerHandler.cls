public with sharing class MessHistoryTaskTriggerHandler {

    private static final Logger LOGGER = new Logger(MessHistoryTaskTriggerHandler.class.getName()); 

    private static final String SYSTEM_ORIGIN_VALUE = 'NetSuite';
    private static final String STATUS_SENT = '3';
    // private static final Id DUMMY_ACCOUNT_ID = [
    //     SELECT Id
    //     FROM Account
    //     WHERE Name = 'Dummy Account'
    //     LIMIT 1
    // ]?.Id;

    
    public void createTaskOnInsert(List<nco_message_history__c> messageHistories) {
        try {
            Set<String> entityNames = new Set<String>();
            Set<String> authors = new Set<String>();

            for (nco_message_history__c messageHistory : messageHistories) {
                if (String.isNotBlank(messageHistory.custrecord_entity__c)) {
                    entityNames.add(messageHistory.custrecord_entity__c.trim());
                }
                if (String.isNotBlank(messageHistory.custrecord_author__c)) {
                    authors.add(messageHistory.custrecord_author__c.trim());
                }
            }

            Map<String, Account> accountsByNsInternalId = getAccountsByNsInternalId(entityNames);
            Map<String, User> usersByNsInternalId = getUsersByNsInternalId(authors);
            List<Task> tasks = buildTasks(messageHistories, accountsByNsInternalId, usersByNsInternalId);

            insert tasks;

        } catch (Exception ex) {
            LOGGER.logError(ex);
            LOGGER.publishLogs();
        }
    }


    private static Map<String, Account> getAccountsByNsInternalId(Set<String> entityNames) {
        Map<String, Account> accountsByNsInternalId = new Map<String, Account>();
        if (!entityNames.isEmpty()) {
            for (Account account : [
                SELECT Id, NetSuiteInternalId__c, OwnerId
                FROM Account
                WHERE NetSuiteInternalId__c IN :entityNames
            ]) {
                accountsByNsInternalId.put(account.NetSuiteInternalId__c, account);
            }
        }
        return accountsByNsInternalId;
    }

    private static Map<String, User> getUsersByNsInternalId(Set<String> authors) {
        Map<String, User> usersByNsInternalId = new Map<String, User>();
        if (!authors.isEmpty()) {
            for (User usr : [
                SELECT Id, breadwinner_ns__NetSuite_Employee_NS_Internal_ID__c
                FROM User
                WHERE breadwinner_ns__NetSuite_Employee_NS_Internal_ID__c IN : authors
            ]) {
                usersByNsInternalId.put(usr.breadwinner_ns__NetSuite_Employee_NS_Internal_ID__c, usr);
            }
        }
        return usersByNsInternalId;
    }

    private static List<Task> buildTasks(
        List<nco_message_history__c> messageHistories,
        Map<String, Account> accountsByNsInternalId,
        Map<String, User> usersByNsInternalId
    ) {
        List<Task> tasks = new List<Task>();

        for (nco_message_history__c messageHistory : messageHistories) {

            Task newTask;

            if (accountsByNsInternalId.containsKey(messageHistory.custrecord_entity__c)) {
                newTask = new Task();
                Account acc = accountsByNsInternalId.get(messageHistory.custrecord_entity__c);
                newTask.WhatId = acc.Id;
                if (usersByNsInternalId.containsKey(messageHistory.custrecord_author__c)) {
                    newTask.OwnerId = usersByNsInternalId.get(messageHistory.custrecord_author__c).Id;
                } else {
                    newTask.OwnerId = acc.OwnerId;
                }
            } else {
                continue;
            }

            newTask.Subject = messageHistory.custrecord_subject__c;

            if (messageHistory.custrecord_date_time__c != null) {
                newTask.ActivityDate = messageHistory.custrecord_date_time__c.date();
            }

            newTask.Description =
                'Is HTML: ' + messageHistory.custrecord_is_html_message__c + '\n' +
                'From: ' + (String.isNotBlank(messageHistory.custrecord_author_email__c) ? messageHistory.custrecord_author_email__c + '\n' : '\n') +
                'To: ' + (String.isNotBlank(messageHistory.custrecord_sent_to__c) ? messageHistory.custrecord_sent_to__c + '\n' : '\n') +
                'CC: ' + (String.isNotBlank(messageHistory.custrecord_cc__c) ? messageHistory.custrecord_cc__c + '\n' : '\n') +
                'BCC: ' + (String.isNotBlank(messageHistory.custrecord_bcc__c) ? messageHistory.custrecord_bcc__c + '\n' : '\n') +
                'Subject: ' + (String.isNotBlank(messageHistory.custrecord_subject__c) ? messageHistory.custrecord_subject__c + '\n' : '\n') +
                'Body: ' + (String.isNotBlank(messageHistory.custrecord_message__c) ? messageHistory.custrecord_message__c : '');
                
            newTask.Message_History__c = messageHistory.Id;
            newTask.System_Origin__c = 'NetSuite';
            newTask.Status = 'Completed';
            newTask.TaskSubtype = 'Email';
            newTask.Priority = 'Normal';

            tasks.add(newTask);
        }

        return tasks;
    }

}