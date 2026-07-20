@IsTest
public with sharing class LoggerTest {
    
    @IsTest
    static void logErrorTest() {
        
        Test.startTest();
            Logger logger = new Logger('TestClass');
            logger.publishLogs();

             try {
                Integer i = 1 / 0;
            } catch (Exception ex) {
                logger.logError(ex);
                logger.logError(ex, 'someRecordId');
                logger.publishLogs();
            }
        Test.stopTest();

        System.assertEquals(2, [SELECT Id FROM Log__c].size());
    }


}