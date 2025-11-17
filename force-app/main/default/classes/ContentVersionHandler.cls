public with sharing class ContentVersionHandler {
    @AuraEnabled
    public static string assignType(String recordId , String type){
        try {
            ContentVersion cv = [SELECT Id, Type__c,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :recordId];
            cv.Type__c = type;
            update cv;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}