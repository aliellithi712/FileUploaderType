public with sharing class StringReturner {
    @AuraEnabled(cacheable=true)
    public static String getMessage() {
        return 'Hello from Apex!';
    }
}