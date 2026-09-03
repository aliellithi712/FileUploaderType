public interface IQVIA_PicklistService {
    List<Map<String, String>> getPicklistMap(String objectApi, String recordTypeId, String picklistName);
    List<String> getPicklist(String objectApi, String recordTypeId, String picklistName);
}
