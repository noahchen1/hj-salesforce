@IsTest
public with sharing class MessHistoryTaskTriggerHandlerTest {

    @IsTest
    static void createTaskOnInsertTest() {
        Account acc = new Account(
            NetSuiteInternalId__c = 'Dummy Account',
            Name = 'Dummy Account'
        );
        insert acc;


        Test.startTest();
            insert new nco_message_history__c(
                custrecord_entity__c = 'Dummy Account',
                custrecord_subject__c = 'Test Subject',
                custrecord_is_incoming__c = true,
                custrecord_date_time__c = System.now(),
                custrecord_author_email__c = 'sender@test.com',
                custrecord_sent_to__c = 'receiver@test.com',
                custrecord_cc__c = 'cc@test.com',
                custrecord_bcc__c = 'bcc@test.com',
                custrecord_is_html_message__c = true,
                custrecord_message__c = '<b>Hello world!</b>'
            );
        Test.stopTest();

        List<Task> tasks = [
            SELECT Id
            FROM Task
            WHERE Subject = 'Test Subject'
        ];

        System.assertEquals(1, tasks.size(), 'Must create one Task record');

        // EmailMessage result = emailMessages[0];
        // System.assertEquals('Test Subject', result.Subject);
        // System.assertEquals('NetSuite', result.System_Origin__c);
    }
}