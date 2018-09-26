public class MetadataRetrieveDemo{
    
    @RemoteAction
    public static List<String> getMetadataItems(String metadataType) {
    	MetadataService.MetadataPort service = new MetadataService.MetadataPort(); 
        service.SessionHeader = new MetadataService.SessionHeader_element(); 
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();        
        
        MetadataService.ListMetadataQuery m = new MetadataService.ListMetadataQuery();
        m.type_x = metadataType;
        queries.add(m);     

        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 25);
        
        List<String> items = new List<String>();
        for(MetadataService.FileProperties fileProperty : fileProperties)
            items.add(fileProperty.fullName); 
        
        return items;
    }
    
    @RemoteAction
    public static List<String> getMetadataItem(String metadataType, String metadataItem) {
        // this example request for metadata retrieve and then post to the heroku service
        MetadataService.MetadataPort service = MetadataValidator.createService();             
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion    = 27;
        retrieveRequest.packageNames  = null;
        retrieveRequest.singlePackage = true;
        retrieveRequest.specificFiles = null;
         
        retrieveRequest.unpackaged    = new MetadataService.Package_x();
        retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
        packageType.name = metadataType; //'ApexClass'; 
        packageType.members = new String[] { metadataItem }; // { 'MetadataValidator' };
         
        retrieveRequest.unpackaged.types.add(packageType);
         
        MetadataService.AsyncResult aResult = service.retrieve(retrieveRequest);
        MetadataService.AsyncResult[] aResults = service.checkStatus(new String[] { aResult.Id });
         
        // only the first package
        while(!aResults[0].done) {
            aResults = service.checkStatus(new String[] { aResult.Id });
        }
         
        MetadataService.RetrieveResult retrieveResult = service.checkRetrieveStatus(aResults[0].Id);
         
        // messages must be null for successful retrieve
        if(retrieveResult.messages == null) {
            // post the result
            String resp = MetadataRetrieveHelper.retrievePost(aResult.Id, retrieveResult.zipFile);
         
            // response is a list of file paths in the zip file, seperated by comma
            //System.debug('resp:'+ resp);
            //System.debug('process id:'+ aResult.Id);
            
            return new List<String>{ UserInfo.getOrganizationId(), aResult.Id, resp };
        }
        	
        return null;
           
    }
}