public with sharing class FileListerController {

    public class FileWrapper {
        @AuraEnabled public ContentVersion file {get; set;}
        @AuraEnabled public String attachmentName {get; set;}
        @AuraEnabled public String attachmentType {get; set;}

        @AuraEnabled public String fileId { get; set; }
        @AuraEnabled public String Title { get; set; }
        @AuraEnabled public String Description { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public String ContentDocumentId { get; set; }


        public FileWrapper(ContentVersion cv, String type, String attachmentName) {
            this.file = cv;
            this.attachmentType = type;
            this.attachmentName = attachmentName;
        }

        public FileWrapper(String id, String Title, String Description, DateTime createdDate, String type, String ContentDocumentId, String attachmentName) {
        this.fileId = id;
        this.Title = Title;
        this.Description = Description;
        this.createdDate = createdDate;
        this.attachmentType = type;
        this.ContentDocumentId = ContentDocumentId;
        this.attachmentName = attachmentName;
        }
    }


    @AuraEnabled
    public static List<FileWrapper> getRelatedFiles(String recordId) {
        List<FileWrapper> wrapperList = new List<FileWrapper>();

        // 1. Fetch custom attachment mapping records
        Map<Id, Meeting_Attachment__c> attachmentMap = new Map<Id, Meeting_Attachment__c>([
            SELECT Id, Type__c,Name FROM Meeting_Attachment__c WHERE Meeting__c = :recordId
        ]);

        if (attachmentMap.isEmpty()) return wrapperList;

        // ==========================================================
        // EXTRACT MODERN FILES (ContentVersion)
        // ==========================================================
        List<ContentDocumentLink> cdlList = [
            SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :attachmentMap.keySet()
        ];

        if (!cdlList.isEmpty()) {
            Map<Id, Id> docToEntityMap = new Map<Id, Id>();
            for (ContentDocumentLink cdl : cdlList) {
                docToEntityMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }

            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId, Title, Description, CreatedDate
                FROM ContentVersion
                WHERE ContentDocumentId IN :docToEntityMap.keySet() AND IsLatest = true
            ]) {
                Id linkedEntityId = docToEntityMap.get(cv.ContentDocumentId);
                String typeValue = attachmentMap.get(linkedEntityId)?.Type__c;
                String name = attachmentMap.get(linkedEntityId)?.Name;

                wrapperList.add(new FileWrapper(cv.Id, cv.Title, cv.Description, cv.CreatedDate, typeValue, cv.ContentDocumentId,name));
            }
        }

        // ==========================================================
        // EXTRACT LEGACY RECORDS (Attachment)
        // ==========================================================
        for (Attachment att : [
            SELECT Id, ParentId, Name, Description, CreatedDate FROM Attachment WHERE ParentId IN :attachmentMap.keySet()
        ]) {
            String typeValue = attachmentMap.get(att.ParentId)?.Type__c;
            String name = attachmentMap.get(att.ParentId)?.Name;
            wrapperList.add(new FileWrapper(att.Id, att.Name, att.Description, att.CreatedDate, typeValue, null,name));
        }

        System.debug(wrapperList);
        return wrapperList;
    }




    @AuraEnabled
    public static OCE__Meeting__c getRecordStatus(String recordId) {
        return [
            SELECT OCE__Status__c FROM OCE__Meeting__c WHERE Id = :recordId
        ];
    }


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
    public static String changeNameDescriptionPicklist(
        String recordId,
        String name,
        String description,
        String sourceType,
        String targetType,
        String sourceCategoryFieldName,
        String targetCategoryFieldName,
        String meetingId
    ) {
        try {
            if (String.isBlank(recordId)) {
                return null;
            }

            // Standard Attachment Logic (00P Prefix)
            if (recordId.startsWith('00P')) {
                List<Attachment> attList = [
                    SELECT Id, Name, Description, Body, ContentType, IsPrivate, OwnerId
                    FROM Attachment
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                if (attList.isEmpty()) {
                    return null;
                }

                Attachment oldAtt = attList[0];
                Boolean requiresReparenting = String.isNotBlank(targetType) && String.isNotBlank(sourceType) && targetType != sourceType;

                if (requiresReparenting) {
                    List<Meeting_Attachment__c> newAttachments = [
                        SELECT Id FROM Meeting_Attachment__c
                        WHERE Type__c = :targetType AND Meeting__c = :meetingId
                        LIMIT 1
                    ];

                    if (!newAttachments.isEmpty()) {
                        Attachment newAtt = new Attachment(
                            Body = oldAtt.Body,
                            ContentType = oldAtt.ContentType,
                            IsPrivate = oldAtt.IsPrivate,
                            OwnerId = oldAtt.OwnerId,
                            Name = name,
                            Description = description,
                            ParentId = newAttachments[0].Id
                        );
                        insert newAtt;
                        delete oldAtt;
                        return 'success';
                    }
                    return null; // Target meeting attachment parent not found
                }
                else {
                    oldAtt.Name = name;
                    oldAtt.Description = description;
                    update oldAtt;
                    return 'success';
                }
            }
            // Files / ContentDocument Logic
            else {
                List<ContentVersion> cvList = [
                    SELECT Id, Title, Description
                    FROM ContentVersion
                    WHERE ContentDocumentId = :recordId
                    AND IsLatest = true
                    LIMIT 1
                ];

                if (cvList.isEmpty()) {
                    return null;
                }

                cvList[0].Title = name;
                cvList[0].Description = description;
                update cvList[0];

                if (String.isBlank(sourceCategoryFieldName) || String.isBlank(targetCategoryFieldName) || String.isBlank(sourceType) || String.isBlank(targetType)) {
                    return 'success'; // Title/Description updated, no reparenting requested
                }

                // Sanitize dynamic SOQL field names
                String cleanSourceField = String.escapeSingleQuotes(sourceCategoryFieldName);
                String cleanTargetField = String.escapeSingleQuotes(targetCategoryFieldName);

                String oldQuery = 'SELECT Id FROM Meeting_Attachment__c WHERE Meeting__c = :meetingId AND ' + cleanSourceField + ' = :sourceType LIMIT 1';
                String newQuery = 'SELECT Id FROM Meeting_Attachment__c WHERE Meeting__c = :meetingId AND ' + cleanTargetField + ' = :targetType LIMIT 1';

                List<Meeting_Attachment__c> oldAttachments = Database.query(oldQuery);
                List<Meeting_Attachment__c> newAttachments = Database.query(newQuery);

                if (oldAttachments.isEmpty() || newAttachments.isEmpty()) {
                    System.debug('Source or Target Meeting Attachment record not found.');
                    return null;
                }

                Id oldAttachmentId = oldAttachments[0].Id;
                Id newAttachmentId = newAttachments[0].Id;

                // Safe CDL query into List to prevent query exceptions
                List<ContentDocumentLink> oldCdls = [
                    SELECT Id FROM ContentDocumentLink
                    WHERE ContentDocumentId = :recordId AND LinkedEntityId = :oldAttachmentId
                ];

                if (!oldCdls.isEmpty()) {
                    delete oldCdls;
                }

                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = recordId,
                    LinkedEntityId = newAttachmentId,
                    ShareType = 'V'
                );
                insert cdl;

                return 'success';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}
