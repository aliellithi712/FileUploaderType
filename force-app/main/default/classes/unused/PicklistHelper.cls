public class PicklistHelper {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> values = new List<String>();

        // Get the object describe
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) return values;

        // Get the field describe
        Schema.DescribeFieldResult fieldResult = objType.getDescribe().fields.getMap().get(fieldName).getDescribe();

        // Extract picklist values
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getLabel());
        }

        return values;
    }
}