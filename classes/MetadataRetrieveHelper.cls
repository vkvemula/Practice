/*
    author: Soe <soe@soe.im>
    
    this is created as part of CS2471
    
    this "REST" service is deployed on heroku @ https://cs2471-soe.herokuapp.com
    this endpoint must be added as a remote site
    
    examples:
        - initial retireve and posting of zip to the service
        - subsequent retrievals 
        
        https://gist.github.com/soe/5986740
        
-------------------------------------------------------------------------------------
	Change Log
-------------------------------------------------------------------------------------
@KnowledgeLover: Added custom setting for heroku service end point
*/

public class MetadataRetrieveHelper {

    public static String retrievePost(String process, String zipfileString) {
        Config__c endPoint = Config__c.getInstance('Heroku_Service');
	    if(endPoint != null && endPoint.value__c != null){
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        
	        req.setEndpoint(endpoint.value__c +'/retrieve/'+ UserInfo.getOrganizationId() +'/'+ process);
	        req.setMethod('POST');
	        req.setBody(zipfileString);
	        
	        HttpResponse res  = new HttpResponse(); 
	        res = h.send(req);
	
	        try {
	            res = h.send(req);
	            
	            return res.getBody();
	        } catch(System.CalloutException e) {
	            return res.toString();
	        }
	    }
	    return null;
    }
    
    public static String retrieveGet(String process, String path) {
        Config__c endPoint = Config__c.getInstance('Heroku_Service');
	    if(endPoint != null && endPoint.value__c != null){
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        
	        req.setEndpoint(endpoint.value__c +'/retrieve/'+ UserInfo.getOrganizationId() +'/'+ process +'?path='+ path);
	        req.setMethod('GET');
	        
	        HttpResponse res  = new HttpResponse(); 
	        res = h.send(req);
	
	        try {
	            res = h.send(req);
	            return res.getBody();
	        } catch(System.CalloutException e) {
	            return res.toString();
	        }
	    }
	    return null;
    }
}