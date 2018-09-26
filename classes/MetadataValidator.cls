/***************************************************************************
 Name 	    : MetadataValidator
 Created By : Kartik Viswanadha

****************************************************************************/

/*
	
	Metadata CRUD, This class is the main class to perform READ, CREATE, UPDATE, DELETE on the Salesforce Metadata. 
	
	Since we only need to know if the Metadata Component exists, there is no need to extract the Zip file, but just make sure that the callout is
	successful. And if there is a message in the Result, then the element retrieve is an error. 
	
	For CREATE, UPDATE & DELETE operations, we are using partly reflection via JSON String by Deserializing the String into the Salesforce Object. 

*/



public with sharing class MetadataValidator {
	private final static String ACTION_READ = 'READ';
	private final static String ACTION_DEEP_READ = 'DEEP_READ';
	private final static String ACTION_DELETE = 'DELETE';
	private final static String ACTION_UPDATE = 'UPDATE';
	private final static String ACTION_CREATE = 'CREATE';
	private final static Integer API_VERSION = 27;
	private final static String STATUS_IN_PROGRESS = 'InProgress';
	private final static String STATUS_ERROR = 'Error';
	
	public static MetadataJSON mdata;
	public static List<MetadataService.AsyncResult> testResults; // This is for test, as callouts are not possible in test.
	
	// Only for READS
	public static String validateMetadataREAD(String mjson){
		try{
			mdata = (MetadataJSON)JSON.deserialize(mjson,MetadataJSON.class);
		}catch(Exception ex){
			return null;
		}
		
		if(mdata.action == ACTION_READ){
			return retrieveMetadata(mdata.metadataType,mdata.metadataName);
		}
		
		if(mdata.action == ACTION_DEEP_READ){
			return retrieveMetadata(mdata);
		}
		
		return null;
	}
	
	// For CREATE, DELETE and UPDATE
	public static String validateMetadataDML(String action, String metadataType, String mPropertyJSON){
		if(action == ACTION_DELETE){
			return deleteMetadata(metadataType,mPropertyJSON);
		}
		
		if(action == ACTION_CREATE){
			return createmetadata(metadataType,mPropertyJSON);
		}
		
		if(action == ACTION_UPDATE){
			return updatemetadata(metadataType,mPropertyJSON);
		}
		return null;
	}
	
	// Retrieve the metadata
	public static String retrieveMetadata(MetadataJSON meta){
		// Construct unmanaged package with list of desired components to retrieve in zip
        MetadataService.MetadataPort service = createService();             
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion 	  = API_VERSION;
        retrieveRequest.packageNames  = null;
        retrieveRequest.singlePackage = true;
        retrieveRequest.specificFiles = null;
        retrieveRequest.unpackaged 	  = new MetadataService.Package_x();
        retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
        packageType.name = meta.metadataType; 
        packageType.members = new String[] { meta.metadataName };
        retrieveRequest.unpackaged.types.add(packageType);
        MetadataService.AsyncResult aresult;
        
        if(!Test.isRunningTest())
         	 aresult = service.retrieve(retrieveRequest);
        else
        	aresult = testResults[0];
        
        MetadataService.AsyncResult[] aResults = service.checkStatus(new String[] { aResult.Id });
 
		// only the first package
		//while(!aResults[0].done) {
		 aResults = service.checkStatus(new String[] { aResult.Id });
		//}
		integer i=0;
		while(i<10000){
			i++;
		} 
		 
		MetadataService.RetrieveResult retrieveResult = service.checkRetrieveStatus(aResult.Id);
			
        // messages must be null for successful retrieve
		if(retrieveResult.messages == null) {
		    // post the result
		    String resp = MetadataRetrieveHelper.retrievePost(aResult.Id, retrieveResult.zipFile);
		 
		    // response is a list of file paths in the zip file, seperated by comma
		    System.debug('resp:'+ resp);
		    System.debug('process id:'+ aResult.Id);
		    
		    String xmlContent = MetadataRetrieveHelper.retrieveGet(aResult.Id, meta.metadataType + '/' + meta.metadataName);	
        
        	system.debug('Content ' + xmlContent);
		}
		
		
        	
        return aresult.id;
	}
	
	// Retrieve the metadata
	public static String retrieveMetadata(String metadataType,String metaDataItem){
		// Construct unmanaged package with list of desired components to retrieve in zip
        MetadataService.MetadataPort service = createService();             
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion 	  = API_VERSION;
        retrieveRequest.packageNames  = null;
        retrieveRequest.singlePackage = true;
        retrieveRequest.specificFiles = null;
        retrieveRequest.unpackaged 	  = new MetadataService.Package_x();
        retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
        packageType.name = metadataType; 
        packageType.members = new String[] { metaDataItem };
        retrieveRequest.unpackaged.types.add(packageType);
        MetadataService.AsyncResult aresult;
        
        if(!Test.isRunningTest())
         	 aresult = service.retrieve(retrieveRequest);
        else
        	aresult = testResults[0];
        	
        return aresult.id;
	}
	
	// Delete the metadata
	public static String deleteMetadata(String metadataType,String metadata){
		
		MetadataService.MetadataPort service    			 = createService();
		MetadataService.Metadata mt 						 = new MetadataService.Metadata();	        
		mt												     = (MetadataService.Metadata)JSON.deserialize(metadata,Type.forName('MetadataService.'+metadataType));
		
		MetadataService.AsyncResult[] results;
		
		if(!Test.isRunningTest())
        	 results = service.deleteMetadata(new List<MetadataService.Metadata>{mt});
		else
			results = testResults;
			
		return results[0].id;
	}
	
	public static String createMetadata(String metadataType,String metadata){
		
		MetadataService.MetadataPort service    			 = createService();
		MetadataService.Metadata mt 						 = new MetadataService.Metadata();	        
		mt												     = (MetadataService.Metadata)JSON.deserialize(metadata,Type.forName('MetadataService.'+metadataType));
		
		MetadataService.AsyncResult[] results;
		
		if(!Test.isRunningTest())
         	results = service.create(new List<MetadataService.Metadata>{mt});
		else
			results = testResults;
			
		return results[0].id;
	}
	
	public static String updateMetadata(String metadataType,String metadata){
		MetadataService.MetadataPort service    			 = createService();
		MetadataService.Metadata mt 						 = new MetadataService.Metadata();	        
		mt												     = (MetadataService.Metadata)JSON.deserialize(metadata,Type.forName('MetadataService.'+metadataType));
		MetadataService.UpdateMetadata ut 					 = new MetadataService.UpdateMetadata();
		ut.metadata											 = mt;
		
		MetadataService.AsyncResult[] results;
		
		if(!Test.isRunningTest())
        	results = service.updateMetadata(new List<MetadataService.UpdateMetadata>{ut});
		else
			results = testResults;
		return results[0].id;
	}
	
	// Check the requests. using the Async ID.
	
	public static boolean checkAsyncRequest(String aresult, String action){
		// Check the status of the retrieve request
        
        MetadataService.MetadataPort service = createService();
        MetadataService.AsyncResult[] aysncResults;
        
        if(!Test.isRunningTest())
        	aysncResults = service.checkStatus(new String[] { aresult });
        else
        	aysncResults = testResults;
        
        if(aysncResults[0].done){
            // Errors?
            if(aysncResults[0].state == STATUS_ERROR){
                system.debug(aysncResults[0].message);
                return false;       
            }
            else{
				if(action == ACTION_READ){ // Retrieve only for READ Operations, rest, only check if request is successful
					MetadataService.RetrieveResult retrieveResult = new MetadataService.RetrieveResult();
	                 	
					if(!Test.isRunningTest())
						retrieveResult = service.checkRetrieveStatus(aresult);
	                else
		            	return true;
		                	
	                if(aysncResults[0].state == STATUS_IN_PROGRESS)
	                	return false;
		                
	                if(retrieveResult.messages != null && retrieveResult.messages.size() > 0){
		                for(MetadataService.RetrieveMessage msg : retrieveResult.messages){
		                	if(msg.problem != '' || msg.problem != null){
		                		return false;
		                	}
		                }
					}
	               	
	               	return true;
                 	
                 }else {
                 	if(aysncResults[0].state == STATUS_IN_PROGRESS)
                 		return false;
                 	else 
                 		return true;	
                 }
            }
        }
        else{
            return null;
        }   
        return null;
	}
	
	// Create the Session
	public static MetadataService.MetadataPort createService(){ 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    }  
}