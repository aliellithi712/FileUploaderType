public class IQVIA_PicklistServiceImpl implements IQVIA_PicklistService {
    
    public List<String> getPicklist(String objectName, String recordTypeId, String picklistName) { 

        ConnectApi.PicklistValuesCollection result =
            ConnectApi.RecordUI.getPicklistValuesByRecordType(objectName, recordTypeId);

        String fieldName = picklistName;

        List<String> labels = new List<String>();

        if (result.picklistFieldValues != null &&
            result.picklistFieldValues.containsKey(fieldName)) {

            ConnectApi.PicklistValues sourceValues =
                result.picklistFieldValues.get(fieldName);

            if (sourceValues != null && sourceValues.values != null) {
                for (ConnectApi.PicklistValue v : sourceValues.values) {
                    labels.add(v.label);
                }
            }
        }
        return labels;
    }

}