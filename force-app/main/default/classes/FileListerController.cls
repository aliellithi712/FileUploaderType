public with sharing class FileListerController {

    @AuraEnabled
    public static List<ContentVersion> getRelatedFiles(String recordId) {
        return [
            SELECT Id, Title, FileType, CreatedDate, type__c
            FROM ContentVersion
            WHERE FirstPublishLocationId = :recordId 
            ORDER BY CreatedDate DESC
        ];
    }
}