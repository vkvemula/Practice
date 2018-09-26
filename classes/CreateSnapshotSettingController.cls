/*
 * @Author: KnowledgeLover
 * @Date: July 28, 2013
 * @Description: Controller class for CreateSnapshotSetting.page
 */
public class CreateSnapshotSettingController {
   
    public List<z_MetaDumpSetting__c> lstSetting{get;set;}
    public String sObjectName{get;set;}
    public Id exerciseId{get;set;}
    
    
    //Constructor
    public CreateSnapshotSettingController(){
        lstSetting = new List<z_MetaDumpSetting__c>();
        exerciseId = Apexpages.currentPage().getParameters().get('exerciseId');
        if(exerciseId == null || String.valueOf(exerciseId).trim() == ''){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, 'Exercise Id is missing in parameters'));
        }else{
            for(z_MetaDumpSetting__c mds : [SELECT Id, Name__c, Exercise__c FROM z_MetaDumpSetting__c WHERE Exercise__c = :exerciseId]){
                lstSetting.add(mds);
                setOfSobjectApiAdded.add(mds.Name__c);
            }
            getSearchableObjects();
        }
        
    }
    
    //Function to store settings
    public void saveSettings(){
        try{
            if(lstSetting != null && lstSetting.size() > 0){
                upsert lstSetting;
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.CONFIRM, 'Object saved successfully!'));
                sObjectName = '';
                getSearchableObjects();
            }else{
                Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, 'No sObjects to save!'));
            }
        }catch(Exception ex){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    //Function to save sObjects to list
    public void addSObject(){
        if(sObjectName != null && sObjectName.trim() != ''){
            lstSetting.add(new z_MetaDumpSetting__c(name__c = sObjectName, Exercise__c = exerciseId));
            setOfSobjectApiAdded.add(sObjectName);
            sObjectName = '';
            getSearchableObjects();
        }
    }
    
    
    /* ********** UI STUFF ********************* */
    
    //list of wrapper class storing the the records of the Sobjects
    public List<SObjectWrapper> listOfSObjectWrapper {get; set;}
    
    //map of object api and label for reference purpose
    public Map<String, String> mapOfObjectApiAndLabel {get; set;}
    
    private List<Schema.SObjectType> listOfSObject = Schema.getGlobalDescribe().values();
    
    //set of already added sObjects api
    private Set<String> setOfSobjectApiAdded = new Set<String>();
    
    /**
    @author Manish
    @purpose get list of the objects in Salesforce ORG
    */
    public void getSearchableObjects(){
        List<String> listOfObjects = new List<String>(); 
        
        mapOfObjectApiAndLabel = new Map<String, String>();
        listOfSObjectWrapper = new List<SObjectWrapper>();
         
        for(SObjectType sObj : listOfSObject){
            if(sObj.getDescribe().isQueryable()
                && sObj.getDescribe().isAccessible()
                && sObj.getDescribe().isDeletable()){
                
                    listOfObjects.add(sObj.getDescribe().getName());
                    mapOfObjectApiAndLabel.put(sObj.getDescribe().getName(), sObj.getDescribe().getLabel());
                    listOfSObjectWrapper.add(new SObjectWrapper(sObj.getDescribe(), setOfSobjectApiAdded));
            }
        }
        
    }
    
    
    
    /**
    @author Manish
    @purpose wrapper class for the Objects (Standard and Custom)
    */
    public class SObjectWrapper{
        //constructor    
        public SObjectWrapper(Schema.DescribeSobjectResult sObjData, Set<String> setOfAddedApi){
            this.name  = sObjData.getLabel();
            this.api = sObjData.getName();
            if(sObjData.isCustom()){
                this.sObjtype = 'Custom';    
            }else{
                this.sObjtype = 'Standard';
            }
            if(setOfAddedApi.contains(sObjData.getName())){
                this.isAddedToList = true;
            }else{
                this.isAddedToList = false;
            }
            
        }
        
        public String name {get; set;}
        public String api {get; set;}
        public String sObjtype {get; set;}
        public Boolean isAddedToList {get; set;}
    }
}