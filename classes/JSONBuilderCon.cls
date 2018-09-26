/***************************************************************************
 Name       : JSONBuilderCon
 Created By : Kartik Viswanadha

****************************************************************************/

/*
    
    This is controller class that helps in building the JSOn Structure for any Metadata Type. This also saves the record as RESET Action on the Question Record from which this
    page is called. 
    
    Change Log:
    1. @sfdcdev11981  11 July, 2013  Replace the validate__c object with Reset__c object. Now reset object will hold reset details and validate__c
                                        will hold only validation details.
    2. @sfdcdev11981  20 July, 2013  Added logic to support JSONBuilder to generate metadata JSON string when called from validate record. To support this 
                                    a new parameter (rt value as 'r' for reset and 'v' for vaidate) is added to the URL calling the JSONBuilder to identify the calling record type.
                                
*/
public with sharing class JSONBuilderCon {

    public Map<String,String> metadataFieldVals {get;set;}
    public String selectedType                  {get;set;}
    public String jsonString                    {get;set;}
    public String action                        {get;set;}
    public boolean isError                      {get;set;}
    
    /* boolean to indicate whether to show properties form or not */
    public Boolean showMetaDataFieldsValues {
        get{
           if(String.isNotBlank(action) && action != 'READ'){
               return true;
           }else{
               return false;
           }
        }
        private set;
    }
    
    /* object of MetaDataReadJSON class to store data for READ action */
    public MetaDataReadJSON readJSON {
        get{
            if(readJSON == null){
                readJSON = new MetaDataReadJSON();
            }
            return readJSON;
        } 
        set;
    }
    
    
    private String questionId;
    
    // @sfdcdev11981  To hold selected reset record.
    private Reset__c selectedReset;
    
    // @sfdcdev11981  To hold selected validate record.
    private Validate__c selectedValidate;
    
    private Map<String,String> dupeCheckMap;
    
    public JSONBuilderCon(){
        
        isError           = false;
        metadataFieldVals = new Map<String,String>();
        dupeCheckMap      = new Map<String,String>();
        
        questionId = Apexpages.currentPage().getParameters().get('id'); 
        
        String reqType = Apexpages.currentPage().getParameters().get('rt'); 
        
        if(String.isBlank(reqType)) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Request type parameter is missing.'));
            return;
        }
        
        if(reqType == 'v') loadValidateRecord(questionId);
        if(reqType == 'r') loadResetRecord(questionId);
            
    }
    
    /*
        @sfdcdev11981 Method for loading reset record if request type is reset i.e 'r'
    */
    public void loadResetRecord(String questionId) {
        // @sfdcdev11981    Replace the validate__c object with Reset__c
        // Removed the reset action related list. Fields added directly on reset object. 
        List<Reset__c> resets = [Select Id, Name, Reset_Type__c, Reset_JSON__c, Action__c, Metadata_Type__c from Reset__c where Id = :questionId];
        
        //Checking weather reset records existing or not for the selected question id. 
        if(resets == null || resets.isEmpty()) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'No reset record available for the selected question [ '+ questionId +']'));
            return;
        }
        
        selectedReset = resets.get(0);
        /*
        @sfdcdev11981  No need of this validation further as reset action fields are moved to reset object. 
        if(selectedReset.Reset_Actions__r != null && selectedReset.Reset_Actions__r.size() > 0){
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'There is already a RESET Available'));
        }
        */
        
        if(selectedReset.Reset_Type__c != 'Metadata'){
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Reset Actions can only be added for Metadata Type Questions for now'));
        }
    }
    
    /*
        @sfdcdev11981 Method for loading validate record if request type is vaidate i.e 'v'
    */
    public void loadValidateRecord(String questionId) {
        
        List<Validate__c> validates = [Select Id, Name, Body__c, Class__c, Sequence__c, NonValidation__c, Validation__c, Type__c, Validation_Logic__c from Validate__c where Id = :questionId];
        
        //Checking weather validates records existing or not for the selected question id. 
        if(validates == null || validates.isEmpty()) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'No validate record available for the selected question [ '+ questionId +']'));
            return;
        }
        
        selectedValidate = validates.get(0);
        
        if(selectedValidate.Type__c != 'Metadata'){
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Only Metadata Type Questions are supported for generation'));
        }
    }
    
    public List<SelectOption> getallActions(){
        
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('','-- Choose Type --'));
        options.add(new SelectOption('CREATE','CREATE'));
        options.add(new SelectOption('UPDATE','UPDATE'));
        options.add(new SelectOption('DELETE','DELETE'));
        options.add(new SelectOption('READ','READ'));
        return options;
        
    }
    
    public List<SelectOption> getallTypes(){
        
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- Choose Type --'));
        
        List<String> allTypes =  new List<String>();
        allTypes.addAll(MetadataHelper.returnMedataTypes());
        allTypes.sort();
        
        for(String s : allTypes){
            options.add(new SelectOption(s,s));
        }
        
        return options;
        
    }
    
    public void buildJSONasInput(){
        
        if(selectedType == '' || selectedType == null){
            return;
        }
        
        jsonString = JSON.serializePretty(MetadataHelper.returnMetadataTypeObject(selectedType));
        JSONParser parser = JSON.createParser(jsonString);
        
        while (parser.nextToken() != null) {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                
                String fieldName = parser.getText();
                
                parser.nextToken();
                
                if(parser.getText() == 'null' || parser.getText() == '' || parser.getText() == null){
                    metadataFieldVals.put(fieldName,' ');
                }
            }
        }
        
        system.debug('map ' + metadataFieldVals);
        
    }
    
    public void generateJSONforRESET(){
        if(action == 'READ'){
            readJSON.action = action;
            readJSON.metadataType = selectedType;
            jsonString = JSON.serializePretty(readJSON); 
        }else{
            dupeCheckMap      = new Map<String,String>();
            
            JSONParser parser = JSON.createParser(jsonString);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            
            while (parser.nextToken() != null) {
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    
                    String fieldName = parser.getText();
                    
                    if(!dupeCheckMap.containsKey(fieldName)){
                        dupeCheckMap.put(fieldName,'1'); // Dupe checks in the Object when doing Metadata Extends.
                        gen.writeFieldName(fieldName);
                        parser.nextToken();
                        if(parser.getCurrentToken() == JSONToken.START_ARRAY){
                            gen.writeStartArray();
                            parser.nextToken();
                            while(parser.getCurrentToken() != JSONToken.END_ARRAY){
                                gen.writeObject(parser.getText());
                                parser.nextToken();
                            }
                            gen.writeEndArray();
                                
                        }else{
                            metadataFieldVals.put('type',selectedType); // Make sure that Type is filled in
                            if(metadataFieldVals.get(fieldName) != null && metadataFieldVals.get(fieldName) != ' ')
                                gen.writeObject(metadataFieldVals.get(fieldName));
                            else
                                gen.writeNull();
                        }
                    }
                }
            }
            
            gen.writeEndObject();
            
            jsonString = gen.getAsString();
        }
            
        system.debug('Pretty' + jsonString);
    }
    
    /*  
        @sfdcdev11981
        Method used for saving reset details. 
        Updated the method to save reset action details directly on reset object.
    */
    public Pagereference saveReset(){
        /*
        Reset_Action__c rAction = new Reset_Action__c();
        
        rAction.Action__c        = action;
        rAction.Metadata_Type__c = selectedType;
        
        // @sfdcdev11981    Replaced the validate__c object with Reset__c object 
        rAction.Reset__c      = questionId; 
        rAction.Reset_JSON__c    = jsonString;
        insert rAction;
        */
        
        // @sfdcdev11981  setting the reset action related fields.
        if(selectedReset != null) {
            selectedReset.Action__c = action;
            selectedReset.Metadata_Type__c = selectedType;
            selectedReset.Reset_JSON__c    = jsonString;
            update selectedReset;
        }
        
        // setting Validation__c with generated metadata json string
        if(selectedValidate != null) {
            selectedValidate.Validation__c = jsonString;
            update selectedValidate;
        }
        
        return new Pagereference('/'+questionId);
    }
    
    /*
        @sfdcdev11981
        Added this method to allow user to move back from JSON Builder page without doing any thing. 
    */
    public Pagereference cancel() {
        return new Pagereference('/'+questionId);
    }
    
    /**
    @author Manish
    @purpose wrapper to store the Metadata READ action fields
    */
    public class MetaDataReadJSON{
        public String action {get; set;}
        public String metadataType {get; set;}
        public String metadataName {get; set;}
    }
}