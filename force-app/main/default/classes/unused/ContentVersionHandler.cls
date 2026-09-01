public with sharing class ContentVersionHandler {
    @AuraEnabled
    public static String assignType(Integer len, List<String> recordIds, String type) {
        try {
            List<ContentVersion> CVs = [
                SELECT Id, Type__c, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :recordIds];

            // Collect ContentDocumentIds
            Set<Id> docIds = new Set<Id>();
            for (ContentVersion cv : CVs) {
                cv.Type__c = type;
                docIds.add(cv.ContentDocumentId);
            }

            // Bulk query ContentDocuments
            Map<Id, ContentDocument> docs = new Map<Id, ContentDocument>(
                [SELECT Id, Title FROM ContentDocument WHERE Id IN :docIds]
            );

            // Update titles
            for (ContentVersion cv : CVs) {
                ContentDocument cd = docs.get(cv.ContentDocumentId);
                cd.Title = type + '_' + cd.Title;
            }

            // Perform DML
            update CVs;
            update docs.values();

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}