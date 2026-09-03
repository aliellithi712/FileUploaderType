public class IQVIA_GetPicklistRTT {

    private IQVIA_PicklistService service;

    public IQVIA_GetPicklistRTT(IQVIA_PicklistService service) {
        this.service = service;
    }

    public IQVIA_GetPicklistRTT() {
        this.service = new IQVIA_PicklistServiceImpl();
    }

    // -------------------------
    // Non-Flow input
    // -------------------------


    public List<Map<String, String>> getValues(String obj, String rt, String pn) {
        return service.getPicklistMap(obj, rt, pn);
    }


    // -------------------------
    // Flow input
    // -------------------------
    public class Request {
        @InvocableVariable(required=true)
        public String objectName;

        @InvocableVariable(required=true)
        public String recordTypeId;

        @InvocableVariable(required=true)
        public String picklistName;
    }


    public class Response {
        @InvocableVariable
        public List<String> returnValues;
    }

    @InvocableMethod(label='Get Picklist Values by Record Type')
    public static List<Response> getValues(List<Request> requests) {

        IQVIA_GetPicklistRTT runner = new IQVIA_GetPicklistRTT();
        List<Response> results = new List<Response>();

            for (Request req : requests) {
                Response res = new Response();
                res.returnValues = runner.service.getPicklist(req.objectName, req.recordTypeId, req.picklistName);
                results.add(res);
    }
        return results;
    }
}
