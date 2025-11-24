public with sharing class FileListerController {

    @AuraEnabled
    public static List<ContentVersion> getRelatedFiles(String recordId) {
        return [
            SELECT Id, Title, FileType, CreatedDate, type__c, ContentDocumentId
            FROM ContentVersion
            WHERE FirstPublishLocationId = :recordId 
            ORDER BY CreatedDate DESC
        ];
    }


    @AuraEnabled
    public static OCE__Meeting__c getRecordStatus(String recordId) {
        return [
            SELECT OCE__Status__c FROM OCE__Meeting__c WHERE Id = :recordId
        ];
    }

}