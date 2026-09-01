public with sharing class AttachmentController {

    @RemoteAction
    public static List<String> getFileTypes(Id recordId) {
        List<ContentVersion> links = [
            SELECT type__c FROM ContentVersion WHERE FirstPublishLocationId = :recordId ORDER BY LastModifiedDate DESC
        ];

        List<String> fileTypes = new List<String>();
        for(ContentVersion link : links){
            fileTypes.add(link.type__c);
        }
        return fileTypes;
    }
}
