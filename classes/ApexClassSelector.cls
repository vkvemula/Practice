public class ApexClassSelector{
	
    @RemoteAction
    public static List<String> getClasses() {
    	MetadataService.MetadataPort service = new MetadataService.MetadataPort(); 
        service.SessionHeader = new MetadataService.SessionHeader_element(); 
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();        
        
        MetadataService.ListMetadataQuery m = new MetadataService.ListMetadataQuery();
        m.type_x = 'ApexClass';
        queries.add(m);     

        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 25);
        
        List<String> classes = new List<String>();
        for(MetadataService.FileProperties fileProperty : fileProperties) {
            if(fileProperty.fullName.startsWith('validationClass_'))
            	classes.add(fileProperty.fullName);
        }
        
        return classes;
    }
    
    @RemoteAction
    public static List<String> getParams(String className) {
    	Type t = Type.forName(className);
		validationClass v = (validationClass)t.newInstance();

    	return v.params();
    }
}