public class IQVIARecordTypeUtils {

    public static String getMatchingRecordTypeId(Id sourceRecordId, String targetObjectApiName) {
        if (sourceRecordId == null || String.isBlank(targetObjectApiName)) {
            return null;
        }

        Schema.SObjectType sourceType = sourceRecordId.getSObjectType();
        String sourceObjectName = sourceType.getDescribe().getName();

        String queryString = 'SELECT RecordTypeId FROM ' + String.escapeSingleQuotes(sourceObjectName) + ' WHERE Id = :sourceRecordId LIMIT 1';
        SObject sourceRecord = Database.query(queryString);
        Id sourceRecordTypeId = (Id) sourceRecord.get('RecordTypeId');

        if (sourceRecordTypeId == null) {
            System.debug('Source record has no Record Type assigned.');
            return null;
        }

        Schema.DescribeSObjectResult sourceDescribe = sourceType.getDescribe();
        String recordTypeName = sourceDescribe.getRecordTypeInfosById().get(sourceRecordTypeId).getName();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(targetObjectApiName);
        if (targetType == null) {
            System.debug('Target object API name is invalid: ' + targetObjectApiName);
            return null;
        }

        Map<String, Schema.RecordTypeInfo> targetRtMapByName = targetType.getDescribe().getRecordTypeInfosByName();

        if (targetRtMapByName.containsKey(recordTypeName)) {
            Id targetRecordTypeId = targetRtMapByName.get(recordTypeName).getRecordTypeId();
            return targetRecordTypeId;
        }

        System.debug('No matching Record Type found on ' + targetObjectApiName + ' for Name: ' + recordTypeName);
        return null;
    }
}
