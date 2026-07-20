public without sharing class Logger {
    
    private String className;
    private List<LogEvent__e> logEvents = new List<LogEvent__e>();

    public Logger(String className) {
        this.className = className;
    }

    public void logError(Exception ex) {
        System.debug('ERROR in ' + this.className + ': ' + ex.getMessage() + ' | ' + ex.getStackTraceString());
        logEvents.add(new LogEvent__e(
            ClassName__c = this.className,
            Message__c = ex.getMessage(),
            StackTrace__c = ex.getStackTraceString()
        ));
    }

    public void logError(Exception ex, String recordId) {
        System.debug('ERROR in ' + this.className + ': ' + ex.getMessage() + ' | ' + ex.getStackTraceString());
        logEvents.add(new LogEvent__e(
            ClassName__c = this.className,
            Message__c = ex.getMessage(),
            StackTrace__c = ex.getStackTraceString(),
            RecordId__c = recordId
        ));
    }

    public void publishLogs() {
        EventBus.publish(logEvents);
    }

}