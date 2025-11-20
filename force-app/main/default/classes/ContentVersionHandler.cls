public with sharing class ContentVersionHandler {
    @AuraEnabled
    public static string assignType( String recordId , String type){
        try {
            
            ContentVersion cv = [SELECT Id, Type__c,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :recordId];
            cv.Type__c = type;            
            update cv;
            // change the name of it append the name of the type 
            ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Id = :recordId];
            cd.Title = type + '_' + cd.Title;
            update cd;
            return 'Success';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}