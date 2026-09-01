// 1. Retrieve Record Type Names from meeting_attachments__c
List<Schema.RecordTypeInfo> attachmentRtInfos = Schema.SObjectType.meeting_attachments__c.getRecordTypeInfos();
Set<String> attachmentRtNames = new Set<String>();

for (Schema.RecordTypeInfo rtInfo : attachmentRtInfos) {
    if (rtInfo.isActive() && !rtInfo.isMaster()) {
        attachmentRtNames.add(rtInfo.getName());
    }
}

// 2. Retrieve Record Type Names from oce__meeting__c
List<Schema.RecordTypeInfo> meetingRtInfos = Schema.SObjectType.oce__meeting__c.getRecordTypeInfos();
Set<String> meetingRtNames = new Set<String>();

for (Schema.RecordTypeInfo rtInfo : meetingRtInfos) {
    if (rtInfo.isActive() && !rtInfo.isMaster()) {
        meetingRtNames.add(rtInfo.getName());
    }
}

// 3. Check for matches and log them
System.debug('--- Starting Record Type Name Matching Check ---');
for (String rtName : attachmentRtNames) {
    if (meetingRtNames.contains(rtName)) {
        System.debug('Match Found! Record Type Name: ' + rtName + ' exists in both objects.');
    }
}
System.debug('--- Matching Check Complete ---');
