public with sharing class FileListerController {

    public class FileWrapper {
    @AuraEnabled public ContentVersion file {get; set;}
    @AuraEnabled public String attachmentName {get; set;}
    @AuraEnabled public String attachmentType {get; set;}

    public FileWrapper(ContentVersion cv, String type, String attachmentName) {
        this.file = cv;
        this.attachmentType = type;
        this.attachmentName = attachmentName;
    }}


    @AuraEnabled
    public static List<FileWrapper> getRelatedFiles(String recordId) {
        List<FileWrapper> wrapperList = new List<FileWrapper>();


        Map<Id, Meeting_Attachment__c> attachmentMap = new Map<Id, Meeting_Attachment__c>([
            SELECT Id,Type__c,Name
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

        for (ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,LinkedEntity.Name,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :attachmentIds]) {
            contentDocumentIds.add(cdl.ContentDocumentId);
            docToInstances.put(cdl.ContentDocumentId, cdl);
        }

        for(ContentVersion c : [SELECT Id, ContentDocumentId, Title, description, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]){
            docToVersion.put(c.ContentDocumentId, c);
        }

        for (ContentDocumentLink cdl : docToInstances.values()) {
            String typeValue = attachmentMap.get(cdl.LinkedEntityId).Type__c;
            String attachmentName = attachmentMap.get(cdl.LinkedEntityId).Name;
            wrapperList.add(new FileWrapper(docToVersion.get(cdl.ContentDocumentId), typeValue,attachmentName));
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


    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String recordId, String type) {
        try {
            String objectName = 'Meeting_Attachment__c';
            String recordTypeId = IQVIARecordTypeUtils.getMatchingRecordTypeId(recordId,objectName);

            IQVIA_PicklistService picklistService = new IQVIA_PicklistServiceImpl();
            IQVIA_GetPicklistRTT runner = new IQVIA_GetPicklistRTT(picklistService);
            List<Map<String, String>> options = runner.getValues(objectName, recordTypeId, type);

            // Schema.SObjectField fieldToken = Meeting_Attachment__c.SObjectType.getDescribe().fields.getMap().get(type);

            // if (fieldToken != null) {
            //     Schema.DescribeFieldResult fieldResult = fieldToken.getDescribe();

            //     for (Schema.PicklistEntry p : fieldResult.getPicklistValues()) {
            //         if (p.isActive()) {
            //             options.add(new Map<String, String>{
            //                 'label' => p.getLabel(),
            //                 'value' => p.getValue()
            //             });
            //         }
            //     }
            // }

            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static string changeNameDescriptionPicklist(
        String recordId,
        String name,
        String description,
        String sourceType,
        String targetType,
        String sourceCategoryFieldName,
        String targetCategoryFieldName,
        String meetingId
        ){
        try {
            List<ContentVersion> cv = [ Select Id, Title, description FROM ContentVersion WHERE ContentDocumentId = :recordId ];
            cv[0].Title = name;
            cv[0].description = description;
            update cv[0];

                try {
                    if (String.isBlank(sourceCategoryFieldName) || String.isBlank(targetCategoryFieldName) || String.isBlank(sourceType) || String.isBlank(targetType)) {
                        return null;
                    }

                    String oldQuery = 'SELECT Id, Name FROM Meeting_Attachment__c ' +
                                    'WHERE Meeting__c = :meetingId ' +
                                    'AND ' + sourceCategoryFieldName + ' = :sourceType LIMIT 1';

                    String newQuery = 'SELECT Id, Name FROM Meeting_Attachment__c ' +
                                    'WHERE Meeting__c = :meetingId ' +
                                    'AND ' + targetCategoryFieldName + ' = :targetType LIMIT 1';

                    List<Meeting_Attachment__c> oldAttachments = Database.query(oldQuery);
                    List<Meeting_Attachment__c> newAttachments = Database.query(newQuery);

                    if (oldAttachments.isEmpty()) {
                        System.debug('No source attachment record found for field ' + sourceCategoryFieldName + ' = ' + sourceType);
                        return null;
                    }

                    Id oldAttachmentId = oldAttachments[0].Id;
                    Id newAttachmentId = newAttachments[0].Id;

                    ContentDocumentLink oldCdl = [Select Id FROM ContentDocumentLink WHERE ContentDocumentId = :recordId AND LinkedEntityId = :oldAttachmentId];
                    delete oldCdl;

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = recordId;
                    cdl.LinkedEntityId = newAttachmentId;
                    cdl.ShareType = 'V';
                    insert cdl;

                    return 'success';
                } catch (Exception e) {
                    throw new AuraHandledException(e.getMessage());
                }



        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}
