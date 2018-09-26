public with sharing class GenerateJSONClass {

    private static String typeOfObject = ApexPages.currentPage().getParameters().get('type');
    private static String recordId = ApexPages.currentPage().getParameters().get('id');
    
    public Boolean isRecordAvailable {get; set;} {isRecordAvailable = false;}
    
    public Boolean isRecordSaved {get; set;} {isRecordSaved = false;}
        
    //currently selected object
    public String selectedObjectName{get; set;}
    
    //list of wrapper class storing the the records of the Sobjects
    public List<SObjectWrapper> listOfSObjectWrapper {get; set;}
    
    //class for JSON data
    public SoqlJSON sJSON{get; set;}
    
    //action type : READ, CREATE, DELETE, UPDATE
    public String actionType {get; set;}
    
    //sequence of the Filter data
    public String filterIndex {get; set;}
    
    //sequence of the field data
    public String fieldIndex {get; set;}
    
    //map of object api and label for reference purpose
    public Map<String, String> mapOfObjectApiAndLabel {get; set;}
    
    //currently selected related object name
    public String selectedRelObjectName {get; set;}
    
    //selectoptions list for related objects with its api name
    public List<SelectOption> listOfRelSobjects {get; set;}
    
    //object to store the Subquery data
    public SoqlJSON subquerySOQL {get; set;}
    
    //sequence of the Filter data for subquery
    public String filterIndex_Subquery {get; set;}
    
    //sequence of subquery from filter
    public String subqueryIndex {get; set;}
    
    //map of related objects ref field and its API name
    private Map<String, String> mapOfRelObjectFieldApiAndName = new Map<String, String>();
    
    //constructor
    public GenerateJSONClass(){
        
        //get list of all the available objects
        getSearchableObjects();
        
        //defaulting the action to read
        actionType = 'READ';
        
        //initializing a new SoqlJSON object
        sJSON = new SoqlJSON();
        
        //initializing a new query object
        sJSON.query = new SOqlJSON.SOQLQuery();
        
        loadExitingSOQLJson();
    }
    
    /**
    @author Manish
    @purpose Method for loading existing SOQL JSON 
    */
    public void loadExitingSOQLJson() {
        if(typeOfObject == 'v'){
            for(Validate__c v: [Select Validation__c, Type__c from Validate__c where id=: recordId LIMIT 1]){
                if(v.Type__c == 'SOQL' && !String.isBlank(v.Validation__c)) {
                    try{
                        sJSON = (SoqlJSON)JSON.deserialize(v.Validation__c,  SoqlJSON.class);
                        isRecordAvailable = true;
                    }catch(Exception e){
                        isRecordAvailable = false;
                        return;
                    }
                }else{
                    return;
                }
            }
        }else if(typeOfObject == 'r'){
            for(Reset__c r: [Select Reset_JSON__c, Reset_Type__c from Reset__c where id=: recordId LIMIT 1]){
                if(r.Reset_Type__c == 'SOQL' && !String.isBlank(r.Reset_JSON__c)) {
                    try{
                        sJSON = (SoqlJSON)JSON.deserialize(r.Reset_JSON__c, SoqlJSON.class);
                        isRecordAvailable = true;
                    }catch(Exception e){
                        isRecordAvailable = false;
                        return;
                    }
                }else{
                    return;
                }
            }
        }
        
        if(sJSON != null) {
            selectedObjectName = sJSON.objectName;
            actionType = sJSON.action;
        }
      
    }
    
    /**
    @author Manish
    @purpose initializing a new SoqlJSON object
    */
    public void refreshSOQL(){
        sJSON = new SoqlJSON();
        sJSON.query = new SOqlJSON.SOQLQuery();
    }
    
    /**
    @author Manish
    @purpose initializing a new Subquery SOQL object
    */
    public void refreshSubquerySOQL(){
        subquerySOQL = new SoqlJSON();
        subquerySOQL.query = new SoqlJSON.SOQLQuery();
        filterIndex_Subquery = '';
        selectedRelObjectName = '';
    }
    
    
    /**
    @author Manish
    @purpose list of available sorting orders
    */
    public List<SelectOption> getListOfSortingOrder(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- None --'));
        options.add(new SelectOption('ASC','ASC'));
        options.add(new SelectOption('DESC','DESC'));
        return options;
    }
    
    /**
    @author Manish
    @purpose list of available operators for filter clause
    */
    public List<SelectOption> getListOfOperators(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- Select Operator --'));
        options.add(new SelectOption('=',' Equals '));
        options.add(new SelectOption('!=',' Not Equals '));
        options.add(new SelectOption('>=',' Greater Then Equals '));
        options.add(new SelectOption('<=',' Less Then Equals '));
        return options;
    }
    
    /**
    @author Manish
    @purpose list of available types of filter, as per JSON class (added a number type, not tested yet)
    */
    public List<SelectOption> getListOfFilterType(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- Select Type --'));
        options.add(new SelectOption('String','String'));
        options.add(new SelectOption('Number','Number'));
        options.add(new SelectOption('Subquery','Subquery'));
        return options;
    }
    
    /**
    @author Manish
    @purpose list of available filter concatenation operator
    */
    public List<SelectOption> getListOfLogicEnds(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- None --'));
        options.add(new SelectOption('AND','AND'));
        options.add(new SelectOption('OR','OR'));
        return options;
    }
    
    /**
    @author Manish
    @purpose get list of the objects in Salesforce ORG
    */
    public List<String> getSearchableObjects(){
        List<String> listOfObjects = new List<String>(); 
        
        List<Schema.SObjectType> listOfSObject = Schema.getGlobalDescribe().values();
        for(SObjectType sObj : listOfSObject){
            if(sObj.getDescribe().isQueryable()
                && sObj.getDescribe().isAccessible()
                && sObj.getDescribe().isDeletable()){
                
                    listOfObjects.add(sObj.getDescribe().getName());
                    if(mapOfObjectApiAndLabel == null){
                        mapOfObjectApiAndLabel = new Map<String, String>();
                    }
                    mapOfObjectApiAndLabel.put(sObj.getDescribe().getName(), sObj.getDescribe().getLabel());
                    if(listOfSObjectWrapper == null){
                        listOfSObjectWrapper = new List<SObjectWrapper>();
                    }
                    listOfSObjectWrapper.add(new SObjectWrapper(sObj.getDescribe()));

            }
        }
        listOfObjects.sort();
        return listOfObjects;
    }
    
    
    /**
    @author Manish
    @purpose get a selctlist for all the fields for selected object
    */
    public List<SelectOption> getListOfFields(){
        return fetchSelectOptionsForObject(selectedObjectName, 'main');
    }
    
    /**
    @author Manish
    @purpose list of available related SObjects
    */
    public List<SelectOption> getListOfFieldsForRelSObject(){
        if(mapOfRelObjectFieldApiAndName.containsKey(selectedRelObjectName)){
            return fetchSelectOptionsForObject(mapOfRelObjectFieldApiAndName.get(selectedRelObjectName), 'related');
        }else{
            return new List<SelectOption>();
        }
    }
    
    /**
    @author Manish
    @purpose a new row of filter on th UI
    */
    public void addFilter(){
        if(sJSON.query.whereFields == null){
                sJSON.query.whereFields = new List<SoqlJSON.WhereConditions>();
        }
        sJSON.query.whereFields.add(new SoqlJSON.WhereConditions());
    }
    
    /**
    @author Manish
    @purpose a new row of filter on th UI for Subquery
    */
    public void addFilter_Subquery(){
        if(subquerySOQL.query.whereFields == null){
                subquerySOQL.query.whereFields = new List<SoqlJSON.WhereConditions>();
        }
        subquerySOQL.query.whereFields.add(new SoqlJSON.WhereConditions());
    }
    
    /**
    @author Manish
    @purpose a new row of fields value for Update/Create on th UI
    */
    public void addField(){
        if(sJSON.fieldValues == null){
                sJSON.fieldValues = new List<SoqlJSON.Fields>();
        }
        sJSON.fieldValues.add(new SoqlJSON.Fields());
    }
    
    /**
    @author Manish
    @purpose remove the selected filter form the UI
    */
    public void removeFilter(){
        if(filterIndex != null && filterIndex != ''){
            try {
                Integer i = Integer.valueOf(filterIndex);
                this.sJSON.query.whereFields.remove(i-1);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error in Removing Filter '+e.getMessage()));
            }
        }
        
    }
    
    /**
    @author Manish
    @purpose remove the selected filter form the UI for Subquery
    */
    public void removeFilter_Subquery(){
        if(filterIndex_Subquery != null && filterIndex_Subquery != ''){
            try {
                Integer i = Integer.valueOf(filterIndex_Subquery);
                this.subquerySOQL.query.whereFields.remove(i-1);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error in Removing Filter '+e.getMessage()));
            }
        }
        
    }
    
    /**
    @author Manish
    @purpose remove the selected field row form the UI for Subquery
    */
    public void removeField(){
        if(fieldIndex != null && fieldIndex != ''){
            try {
                Integer i = Integer.valueOf(fieldIndex);
                this.sJSON.fieldValues.remove(i-1);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error in Removing Field '+e.getMessage()));
            }
        }
        
    }
    
    /**
    @author Manish
    @purpose JSON String
    */
    public String JSONString{
        get{    
            if(sJSON != null){
                sJSON.action = actionType;
                sJSON.objectName = selectedObjectName;
                return JSON.serializePretty(sJSON);  
            }
            return '';
        }
        set;
    }
    
    /**
    @author Manish
    @purpose save the JSON to the record in database [NOTE this for loop will run only once so making a DML inside is no problem]
    */
    public void saveJSON(){
        if(typeOfObject == 'v'){
            for(Validate__c v : [Select Validation__c, Type__c from Validate__c where id=: recordId LIMIT 1]){
                v.Type__c = 'SOQL';
                v.Validation__c = JSONString;
                Database.Update(v);
                isRecordSaved = true;
                break;
            }
        }else if(typeOfObject == 'r'){
            for(Reset__c r : [Select Reset_JSON__c, Reset_Type__c from Reset__c where id=: recordId LIMIT 1]){
                r.Reset_Type__c = 'SOQL';
                r.Reset_JSON__c = JSONString;
                Database.Update(r);
                isRecordSaved = true;
                break;
            }
        }
    }
    
    public void generateSubQuery(){
        String generatedQuery = '';
        if(subquerySOQL != null && subquerySOQL.query != null){
            generatedQuery = '( SELECT Id';
            if(subquerySOQL.query.returnFields != null && subquerySOQL.query.returnFields.size() > 0){
                generatedQuery += ', ';
                for(Integer i = 0; i < subquerySOQL.query.returnFields.size(); i++){
                    generatedQuery += subquerySOQL.query.returnFields[i];
                    if(i < subquerySOQL.query.returnFields.size() - 1){
                        generatedQuery += ', '; 
                    }
                }
            }else{
                generatedQuery += ',';
            }
            if(selectedRelObjectName != null && generatedQuery != ''){
                generatedQuery += ' FROM '+selectedRelObjectName;
            }
            if(subquerySOQL.query.whereFields != null && subquerySOQL.query.whereFields.size() > 0){
                generatedQuery += ' WHERE';
                for(SoqlJSON.WhereConditions wr : subquerySOQL.query.whereFields){
                    generatedQuery += ' '+wr.whrField;
                    generatedQuery += ' '+wr.whrOperator;
                    generatedQuery += ' '+wr.whrValue;
                    if(wr.nextwhrANDOR != null && wr.nextwhrANDOR != ''){
                        generatedQuery += ' '+wr.nextwhrANDOR;
                    }
                }
            }
            if(subquerySOQL.query.orderFields != null && subquerySOQL.query.orderFields.size() > 0){
                generatedQuery += ' ';
                for(Integer i = 0; i < subquerySOQL.query.orderFields.size(); i++){
                    generatedQuery += subquerySOQL.query.orderFields[i];
                    if(i < subquerySOQL.query.orderFields.size() - 1){
                        generatedQuery += ', '; 
                    }
                }
            }
            if(subquerySOQL.query.orderDir != null && subquerySOQL.query.orderDir != ''){
               generatedQuery += ' ORDER BY '+subquerySOQL.query.orderDir;
            }
            if(subquerySOQL.query.limitQuery != null && subquerySOQL.query.limitQuery != ''){
               generatedQuery += ' LIMIT '+subquerySOQL.query.limitQuery;
            }
            generatedQuery += ' )';
        }
        
        if(generatedQuery != ''){
            if(subqueryIndex != null && subqueryIndex != ''){
                try {
                    Integer i = Integer.valueOf(subqueryIndex);
                    this.sJSON.query.whereFields[i-1].whrValue = generatedQuery;
                } catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error in Saving Subquery '+e.getMessage()));
                }
            }
        }
        
    }
    
    
    /**
    @author Manish
    @purpose wrapper class for the Objects (Standard and Custom)
    */
    public class SObjectWrapper{
        //constructor    
        public SObjectWrapper(Schema.DescribeSobjectResult sObjData){
            this.name  = sObjData.getLabel();
            this.api = sObjData.getName();
            if(sObjData.isCustom()){
                this.sObjtype = 'Custom';    
            }else{
                this.sObjtype = 'Standard';
            }
            /**
            for(DescribeDataCategoryGroupResult singleResult : Schema.describeDataCategoryGroups(sObjData.getSobjectType())){
                singleResult.getDescription(); 
            } 
            */
            //this.description =  sObjData.getDescription(); 
            
        }
        public String name {get; set;}
        public String api {get; set;}
        public String sObjtype {get; set;}
        public String description {get; set;}
    }
    
    
    /**
    @author Manish
    @purpose get the selectoptions of fields by providing the object name
    */
    private List<SelectOption> fetchSelectOptionsForObject(String selObjectName, String type){
        if(selObjectName == null || selObjectName == ''){
                return null;
        }
        
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--Select Field--'));
        
        if(type == 'main'){
            //initializing the list of selectoption fro related objects
            listOfRelSobjects = new List<SelectOption>();
            listOfRelSobjects.add(new SelectOption('', '--Select Object--'));
            
            mapOfRelObjectFieldApiAndName = new Map<String, String>();
        }
        
        //schema describe to get field map
        Map<String, Schema.sObjectField> fieldMap = Schema.getGlobalDescribe().get(selObjectName).getDescribe().fields.getMap();
        
        //list of fields to be displayed on the page
        List<String> fieldList = new List<String>();
        
        for(Schema.SObjectField sObjectField : fieldMap.values()){
        
            Schema.DescribeFieldResult descFd = sObjectField.getDescribe();
            if(descFd.getRelationshipName() != null ) {
            
                List<Schema.sObjectType> refObjects = descFd.getReferenceTo();
                if(refObjects != null && !refObjects.isEmpty()) {
                    Map<String, Schema.SObjectField> relObjDescribeMap = refObjects.get(0).getDescribe().fields.getMap();
                    
                    if(type == 'main'){
                        listOfRelSobjects.add(new SelectOption(descFd.getRelationshipName(),  descFd.getRelationshipName()));
                        mapOfRelObjectFieldApiAndName.put(descFd.getRelationshipName(), refObjects.get(0).getDescribe().getName());
                    }
                    
                    for(String relObjFieldName : relObjDescribeMap.keyset()){
                        fieldList.add(descFd.getRelationshipName()+'.'+ relObjFieldName);
                    }
                }
            } else {
                fieldList.add(descFd.getName());
            }
        }
        
        //sorting the fields 
        fieldList.sort();
        
        //adding to the select option
        for(String field : fieldList) {
            options.add(new Selectoption(field, field));
        }
        
        return options;
    }
    
    
    
}