/*
@author sfdcdev11981

Given class is used to handle creation of SOQL JSON using inputs provided by User through intuitive UI.

*/
public with sharing class SOQLJSONBuilderFormController {
	
	public String selectedObjectName {get;set;}
	public String selectedActionType {get;set;}
	
	public boolean isObjectNameSelected {get {return !String.isBlank(selectedObjectName); } private set;}
	
	public List<SelectOption> sObjectSelectOptionList {get;set;}
	public List<Selectoption> fieldOptions {get;set;}
	
	// Field values used to hold field and value for update and create action.
	public List<SoqlJSON.Fields> fieldValues {get;set;}
	
	// Field for holding selected query fields
	public List<String> selectedQueryFields {get;set;}
	
	public boolean showFieldValueSection {get;set;}
	public boolean showWhereClauseSection {get;set;}
	
	public String fieldValueIndexToDelete {get; set;}
	public String whereClauseIndexToDelete {get; set;}
	
	public SoqlJSON soqlJsonObj {get;set;}
	public String jsonString {get; private set;}
	
	// Field to hold the json success and failure state
	public boolean generateJSONSuccess {get;set;}
	
	public List<SelectOption> selectedQueryFieldOption {get;set;}
	public List<SelectOption> selectedOrderByFieldOption {get;set;}
	public List<SoqlJSON.WhereConditions> whereFields {get;set;}
	
	private Map<String, Schema.SObjectType> globalDescribe;
	private String validateRecId;
	
	public SOQLJSONBuilderFormController() {
		
		validateRecId = Apexpages.currentPage().getParameters().get('id');
		
		generateJSONSuccess = false;
		
		// By defaut both section will be false.
		showFieldValueSection = false;
		showWhereClauseSection = false;
			
		globalDescribe = Schema.getGlobalDescribe(); 
		sObjectSelectOptionList = getSObjectList();
		
		// Exiting JSON SQOL laoding for editing if exist.
		loadExitingSOQLJson();
	}
	
	/*
		Method for loading existing SOQL JSON and represent it in on form for editing.
	*/
	public void loadExitingSOQLJson() {
		List<Validate__c> validateList = [Select Validation__c, Type__c from Validate__c where id=: validateRecId];
		
		if(!validateList.isEmpty()) {
			Validate__c validateRec = validateList.get(0);
			
			// Checking for SOQL type and processing non blank Validation__c value.
			if(validateRec.Type__c == 'SOQL' && !String.isBlank(validateRec.Validation__c)) {

				// Deserializing to get SoqlJSON object.
				soqlJsonObj = (SoqlJSON)JSON.deserialize(validateRec.Validation__c,SoqlJSON.class);
				
				if(soqlJsonObj != null) {
					
					selectedObjectName = soqlJsonObj.objectName;
					selectedActionType = soqlJsonObj.action;
					
					selectedQueryFieldOption = new List<SelectOption>();
					selectedOrderByFieldOption = new List<SelectOption>();
					whereFields = new List<SoqlJSON.WhereConditions>();
					fieldValues = new List<SoqlJSON.Fields>();
					
					if(selectedActionType == 'CREATE' ) {
						showFieldValueSection = true;
					} 
					else 
					{
						showWhereClauseSection = true;
						showFieldValueSection = selectedActionType == 'UPDATE' ? true: false;
						
						SoqlJSON.SOQLQuery soqlQuery = new SoqlJSON.SOQLQuery();
						soqlQuery.returnFields = soqlJsonObj.query.returnFields;
						
						// Adding field values 
						if(soqlJsonObj.fieldValues != null) {
							for(SoqlJSON.Fields f : soqlJsonObj.fieldValues) {
								fieldValues.add(f);
							}
						}
						
						if(soqlJsonObj.query != null) {
							
							// adding existing where clause.
							if(soqlJsonObj.query.whereFields != null && !soqlJsonObj.query.whereFields.isEmpty()) {
								for(SoqlJSON.WhereConditions wc : soqlJsonObj.query.whereFields) {
									whereFields.add(wc);
								}
							}
							
							// Adding return fields.
							if(soqlJsonObj.query.returnFields != null && !soqlJsonObj.query.returnFields.isEmpty()) {
								for(String fld : soqlJsonObj.query.returnFields) {
									selectedQueryFieldOption.add(new Selectoption(fld, fld));
								}
							}
							
							// Adding order by fields.
							if(soqlJsonObj.query.orderFields != null && !soqlJsonObj.query.orderFields.isEmpty()) {
								for(String fld : soqlJsonObj.query.orderFields) {
									selectedOrderByFieldOption.add(new Selectoption(fld, fld));
								}
							}
						}
					}
				}
			}
		}
	}
	
	/*
		Added method to describe as get list of all standar and custom fields. 
	*/
	public List<SelectOption> getSObjectList() {
		List<SelectOption> sobjectsSelectOptList = new List<SelectOption>();
		
		//set ot store an ordered list of sobjects (by name)
		Set<String> objsOrderName = new Set<String>();
		
		Map<String,String> sobjNamesLabels = new Map<String,String>();
		
		for(Schema.Sobjecttype sot : globalDescribe.values())
		{
			Schema.Describesobjectresult dr = sot.getDescribe();
			if(dr.isAccessible() && dr.isCustomSetting()==false  && dr.isDeprecatedAndHidden()==false
				&& dr.isQueryable() && dr.isUpdateable() && dr.isDeletable())
			{
				sobjNamesLabels.put(dr.getName(), dr.getlabel());
				objsOrderName.add(dr.getName());
			}
		}
		
		System.assert(objsOrderName.size()>0,'No object found.');
		
		//creates a list to make it order its elements
		
		List<String> nameList = new List<String>(objsOrderName);
		nameList.sort();
		
		sobjectsSelectOptList.add(new selectoption('', '--None--'));
		for(String name : nameList)
		{
			sobjectsSelectOptList.add(new SelectOption(name,sobjNamesLabels.get(name)));
		}
		return sobjectsSelectOptList;
	}
	
	
	/*
		Getting available action supported by application.
		Need to keep this in sync. So need to get these values from common class.
	*/
	public List<SelectOption> getallActions(){
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('','-- None --'));
		options.add(new SelectOption('READ','READ'));
		options.add(new SelectOption('CREATE','CREATE'));
		options.add(new SelectOption('UPDATE','UPDATE'));
		options.add(new SelectOption('DELETE','DELETE'));
		
		return options;
	}
	
	public List<SelectOption> getOrderByOptions(){
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('','-- None --'));
		options.add(new SelectOption('ASC','ASC'));
		options.add(new SelectOption('DESC','DESC'));
		return options;
	}
	
	public List<SelectOption> getWhereOperatorOptions(){
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('','-- None --'));
		options.add(new SelectOption('=',' Equals '));
		options.add(new SelectOption('>=',' Greater Then Equals '));
		options.add(new SelectOption('<=',' Less Then Equals '));
		options.add(new SelectOption('!=',' Not Equals '));
		return options;
	}
	
	public List<SelectOption> getWhereClauseTypeOptions(){
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('','-- None --'));
		options.add(new SelectOption('String','String'));
		options.add(new SelectOption('Subquery','Subquery'));
		return options;
	}
	
	public List<SelectOption> getANDOROptions(){
		List<SelectOption> options = new List<SelectOption>();
		
		options.add(new SelectOption('','-- None --'));
		options.add(new SelectOption('AND','AND'));
		options.add(new SelectOption('OR','OR'));
		return options;
	}
	
	/*
		Getting field option for multi select components. 
	*/
	public List<SelectOption> getMultiselectFieldOption() {
		List<SelectOption> multiSelectFieldOptions = new List<SelectOption>();
		prepareObjectFieldOptions();
		multiSelectFieldOptions.addAll(fieldOptions);
		multiSelectFieldOptions.remove(0);
		return multiSelectFieldOptions;
	}
	
	public void onObjectChange() {
		prepareObjectFieldOptions();
		showSelectedActionForm();
	}
	
	/*
		Method for preparing field list option for selected object name.
	*/
	public void prepareObjectFieldOptions() {
		fieldOptions = new List<Selectoption>();
		fieldOptions.add(new selectoption('', '--None--'));
		
		// selectedObjectName is null or blank, return from the method.
		if(String.isBlank(selectedObjectName)) return;
		
		// Describing object get it field api names.
		Map<String, Schema.sObjectField> fieldMap = globalDescribe.get(selectedObjectName).getDescribe().fields.getMap();
		
		List<String> fieldList = new List<String>();
		
		for(Schema.SObjectField sObjectFld : fieldMap.values()){
			Schema.DescribeFieldResult dfr = sObjectFld.getDescribe();
		}
		
		for(Schema.SObjectField sObjectField : fieldMap.values()){
        
            Schema.DescribeFieldResult dfr = sObjectField.getDescribe();
            
            // Checking if it a relation type field or not and filtering out some system relation ship fields to 
            // keep the field list small as possible. If these are required given check can be removed.
        	if(dfr.getRelationshipName() != null && (dfr.getRelationshipName() != 'CreatedBy' 
        		&& dfr.getRelationshipName() != 'LastModifiedBy' && dfr.getRelationshipName() != 'Owner')) {
        	
        		List<Schema.sObjectType> refObjects = dfr.getReferenceTo();
                if(refObjects != null && !refObjects.isEmpty()) {
                    Map<String, Schema.SObjectField> relObjDescribeMap = refObjects.get(0).getDescribe().fields.getMap();
                    
                    // Looping to relation ship object fields to add related fields.
                    for(String relObjFieldName : relObjDescribeMap.keyset()){
                        fieldList.add(dfr.getRelationshipName()+'.'+ relObjFieldName);
                    }
                }
        	} else {
        		fieldList.add(dfr.getName());
        	}
		}
		fieldList.sort();
		
		for(String fieldName : fieldList) {
	   		fieldOptions.add(new Selectoption(fieldName, fieldName));
		}
	}
	
	
	/*
		Method for showing action form section based on select action.
	*/
	public void showSelectedActionForm() {
		
		if(String.isBlank(selectedActionType)) return;
		selectedQueryFieldOption = new List<SelectOption>();
		selectedOrderByFieldOption = new List<SelectOption>();
		whereFields = new List<SoqlJSON.WhereConditions>();
		
		fieldValues = new List<SoqlJSON.Fields>();
		// By default adding two fieldValues 
		fieldValues.add(new SoqlJSON.Fields());
		fieldValues.add(new SoqlJSON.Fields());
		
		jsonString = '';
		
		soqlJsonObj = new SoqlJSON();
		soqlJsonObj.objectName = selectedObjectName;
		soqlJsonObj.action = selectedActionType;
		
		showFieldValueSection = false;
		showWhereClauseSection = false;
		
		if(selectedActionType == 'CREATE' ) {
			showFieldValueSection = true;
		} 
		else 
		{
			showWhereClauseSection = true;
			showFieldValueSection = selectedActionType == 'UPDATE' ? true: false;
			
			SoqlJSON.SOQLQuery soqlQuery = new SoqlJSON.SOQLQuery();
			soqlQuery.returnFields = new List<String>();
			
			whereFields.add(new SoqlJSON.WhereConditions());
			whereFields.add(new SoqlJSON.WhereConditions());
			
			soqlQuery.orderFields = new List<String>();
			soqlJsonObj.query = soqlQuery;
		}
	}
	
	
	public void addFieldValueRow() {
		this.fieldValues.add(new SoqlJSON.Fields());
	}
	
	public void deleteFieldValueRow() {
		try {
			Integer index = Integer.valueOf(fieldValueIndexToDelete);
			this.fieldValues.remove(index-1);
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Unexpected error: '+e.getMessage()));
		}
	}
	
	public void addNewWhereClauseRow() {
		this.whereFields.add(new SoqlJSON.WhereConditions());
	}
	
	public void deleteWhereClauseRow() {
		try {
			Integer index = Integer.valueOf(whereClauseIndexToDelete);
			this.whereFields.remove(index-1);
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Unexpected error: '+e.getMessage()));
		}
	}
	
	/*
		Method for generating the JSON for user input values and saving it to the validate record and then 
		moving back the user to validate record.
	*/
	public void generateAndSaveJSON() {
		generateJSONSuccess = false;
		
		if(soqlJsonObj != null) {
			
			// Removing any invalid or incomplete fieldValues.
			List<SoqlJSON.Fields> createUpdateFieldValues = new List<SoqlJSON.Fields>();
			for(SoqlJSON.Fields f : fieldValues) {
				// If field name is missing excape the row entry. 
				if(String.isEmpty(f.fieldName)) continue;
				
				createUpdateFieldValues.add(f);
			}
			soqlJsonObj.fieldValues = createUpdateFieldValues;
			
			if(soqlJsonObj.query != null) {
				// Adding query fields.
				if(!selectedQueryFieldOption.isEmpty()) {
					List<String> returnFields = new List<String>();
					for(SelectOption op : selectedQueryFieldOption) {
						returnFields.add(op.getValue());
					}
					soqlJsonObj.query.returnFields = returnFields;
				}
				
				// adding order by fields 
				if(!selectedOrderByFieldOption.isEmpty()) {
					List<String> orderByFields = new List<String>();
					for(SelectOption op : selectedOrderByFieldOption) {
						orderByFields.add(op.getValue());
					}
					soqlJsonObj.query.orderFields = orderByFields;
				}
				
				// Removing any invalid or incomplete where field row entry
				List<SoqlJSON.WhereConditions> whereFieldsToAdd = new List<SoqlJSON.WhereConditions>();
				for(SoqlJSON.WhereConditions wc : whereFields) {
					// Where field is missing excape the row entry. 
					if(String.isEmpty(wc.whrField)) continue;
					
					whereFieldsToAdd.add(wc);
				}
				soqlJsonObj.query.whereFields = whereFieldsToAdd;
			}

			jsonString = JSON.serializePretty(soqlJsonObj);
			
			//Validate the generated SOQL string before saving to the validate record.
			// Setting save point to roll back things after prforming validation. 
        	Savepoint sp = Database.setSavepoint();
			try {
				// Commenting the SOQLValidator call as currently SOQLValidator method is not smart
				// enough to support all field types i.e double and other.
				//boolean success = SOQLValidator.validationSOQL(jsonString); 
				
				// roll any update, delete or create performed as part of validate soql method. 
				//Database.rollback(sp);
			} catch(Exception e) {
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'SOQL Validation failed. Error: '+ e.getMessage()));
				// roll any update, delete or create performed as part of validate soql method. 
				Database.rollback(sp);
				return;
			}
			
			List<Validate__c> validateList = [Select Validation__c from Validate__c where id=: validateRecId];
			if(!validateList.isEmpty()) {
				Validate__c validate = validateList.get(0);
				validate.Validation__c = jsonString;
				update validate;
			}
		}
		system.debug('Generated json string : ' + jsonString);
		generateJSONSuccess = true;
	}
	
	/*
		Reset the json form.
	*/
	public void reset() {
		showSelectedActionForm();
	}
	
}