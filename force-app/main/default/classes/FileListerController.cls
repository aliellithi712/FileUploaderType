public with sharing class FileListerController {

    public class FileWrapper {
    @AuraEnabled public ContentVersion file {get; set;}
    @AuraEnabled public String attachmentType {get; set;}

    public FileWrapper(ContentVersion cv, String type) {
        this.file = cv;
        this.attachmentType = type;
    }
}

    @AuraEnabled
    public static List<FileWrapper> getRelatedFiles(String recordId) {
        List<FileWrapper> wrapperList = new List<FileWrapper>();


        Map<Id, Meeting_Attachment__c> attachmentMap = new Map<Id, Meeting_Attachment__c>([
            SELECT Id,Type__c
            FROM Meeting_Attachment__c
            WHERE Id IN (Select LinkedEntityId FROM ContentDocumentLink) AND Meeting__c = :recordId
        ]);

        if (attachmentMap.isEmpty()) {
            return wrapperList;
        }

        Set <Id> attachmentIds = attachmentMap.keySet();
        Set <Id> contentDocumentIds = new Set<Id>();
        map<Id, ContentDocumentLink> docToInstances = new Map<Id, ContentDocumentLink>();
        Map<Id, ContentVersion> docToVersion = new Map<Id, ContentVersion>();

        for (ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :attachmentIds]) {
            contentDocumentIds.add(cdl.ContentDocumentId);
            docToInstances.put(cdl.ContentDocumentId, cdl);
        }

        for(ContentVersion c : [SELECT Id, ContentDocumentId, Title, description, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]){
            docToVersion.put(c.ContentDocumentId, c);
        }

        for (ContentDocumentLink cdl : docToInstances.values()) {
            String typeValue = attachmentMap.get(cdl.LinkedEntityId).Type__c;
            wrapperList.add(new FileWrapper(docToVersion.get(cdl.ContentDocumentId), typeValue));
        }

        return wrapperList;
    }



    @AuraEnabled
    public static OCE__Meeting__c getRecordStatus(String recordId) {
        return [
            SELECT OCE__Status__c FROM OCE__Meeting__c WHERE Id = :recordId
        ];
    }

    /*
    @AuraEnabled
    public static Case getRecordStatus(String recordId) {
        return [
            SELECT Status FROM Case WHERE Id = :recordId
        ];
    }
        */

    @AuraEnabled
    public static string deleteRecord(String recordId){
        try {
            ContentDocument cd = [Select Id FROM ContentDocument WHERE Id = :recordId ];
            delete cd;
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static List<Map<String, String>> getPicklistVlaues(){
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();

        // Describe the field
        Schema.DescribeFieldResult fieldResult = Meeting_Attachment__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry p: pList) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', p.getLabel());
            option.put('value', p.getValue());
            options.add(option);
        }
        return options;
    }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string changeNameDescriptionPicklist(String recordId, String name, String description, String newType, String oldType, String meetingId){
        try {
            List<ContentVersion> cv = [ Select Id, Title, description FROM ContentVersion WHERE ContentDocumentId = :recordId ];
            cv[0].Title = name;
            cv[0].description = description;
            update cv[0];

            if (newType != oldType && newType != null && oldType != null) {
                try {

                    Meeting_Attachment__c oldAssignedAttachment = [Select Id, Name, Type__c FROM Meeting_Attachment__c WHERE Type__c = :oldType AND Meeting__c = :meetingId];

                    Meeting_Attachment__c newAssignedAttachment = [Select Id, Name, Type__c FROM Meeting_Attachment__c WHERE Type__c = :newType AND Meeting__c = :meetingId];

                    //delete the old content document link
                    ContentDocumentLink oldCdl = [Select Id FROM ContentDocumentLink WHERE ContentDocumentId = :recordId AND LinkedEntityId = :oldAssignedAttachment.Id];
                    delete oldCdl;

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = recordId; // Get this from the ContentVersion
                    cdl.LinkedEntityId = newAssignedAttachment.Id;       // The ID of the Meeting Attachment
                    cdl.ShareType = 'V';                           // 'V' for Viewer permission
                    insert cdl;
                } catch (Exception e) {

                }
            }

            return 'success';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}
