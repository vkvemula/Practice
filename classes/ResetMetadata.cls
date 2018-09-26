/*
 * @Author: KnowledgeLover
 * @Date: July 28, 2013
 * @Description: Apex class to reset metadata from snapshots.
 */
public with sharing class ResetMetadata {
	private map<String, z_SObjectDescription__c> mapNewSobjects{get;set;}
	private map<String, z_SObjectDescription__c> mapOldSobjects{get;set;}
	private map<String, z_FieldDescription__c> mapNewFields{get;set;}
	private map<String, z_FieldDescription__c> mapOldFields{get;set;}
	private list<MetadataService.Metadata> lstDelete{get;set;}
	private list<MetadataService.UpdateMetadata> lstUpdate{get;set;}
	private List<MetadataCreateJob.Item> lstJobItems{get;set;}
	private MetadataService.MetadataPort service{get;set;}
	private Boolean isFirstField{get;set;}
	private Id exerciseId{get;set;}
	
	//Constructor
	public ResetMetadata(String exerciseId){
		this.exerciseId = exerciseId;
		init();
		performOperation();
	}
	
	//Function to iniitialize member variables
	private void init(){
		mapOldSobjects = new map<String, z_SObjectDescription__c>();
		mapNewSobjects = new map<String, z_SObjectDescription__c>();
		
		mapNewFields = new map<String, z_FieldDescription__c>();
		mapOldFields = new map<String, z_FieldDescription__c>();
		
		lstDelete = new list<MetadataService.Metadata>();
		lstUpdate = new list<MetadataService.UpdateMetadata>();
		
		lstJobItems = new List<MetadataCreateJob.Item>();
		
		isFirstField = true;
		service = createService();	
	}
	
	//function to perform metadata operation
	private void performOperation(){
		List<z_SObjectDescription__c> lstSObject = [Select Id,z.localName__c, z.label__c, z.labelPlural__c, z.Name,Snapshot_Status__c,
														(Select Name, z_SObjectDescription__c,isCustom__c, label__c, scale__c, precision__c,
			                                                length__c, relationshipName__c, picklistentries__c, isNillable__c,
															localName__c, calculatedFormula__c, name__c,
		                                                	type__c From z_FieldDescription__r ) 
		                                            from z_SObjectDescription__c z where Exercise__c = :exerciseId];
		
		createMaps(lstSObject);
		identifyMetadataOperations();
		
		//Iterate on all sObject list
		/*for(z_SObjectDescription__c sObj: lstSObject){
		    if(sObj.z_FieldDescription__r != null && sObj.z_FieldDescription__r.size() > 0){
				for(z_FieldDescription__c fieldToProcess: sObj.z_FieldDescription__r){
					MetadataService.CustomField custField = createFieldDefinition(sObj.localName__c, fieldToProcess, false);
		            if(custField != null){
						if(isFirstField){
							lstJobItems.add(new MetadataCreateJob.Item(custField, null, true));
							isFirstField = false;
						}else{
							lstJobItems.add(new MetadataCreateJob.Item(custField));
						}
					}
				}
			}
			
			//MetadataCreateJob.run(lstJobItems,new MetadataCreateJob.EmailNotificationMetadataAsyncCallback());
		}*/
	}
	
	//Function to create map of old and new metadata snapshots
	private void createMaps(List<z_SObjectDescription__c> lstSObject){
		//Iterate on all sObject list
		for(z_SObjectDescription__c sObj: lstSObject){
			if(sObj.Snapshot_Status__c == 'New'){
				mapNewSobjects.put(sObj.localName__c, sObj);
				createFieldMap(sObj.localName__c, sObj.z_FieldDescription__r, mapNewFields);
			}else if(sObj.Snapshot_Status__c == 'Old'){
				mapOldSobjects.put(sObj.localName__c, sObj);
				createFieldMap(sObj.localName__c, sObj.z_FieldDescription__r, mapOldFields);
			}
		}
	}
	
	//Function to identify metadata operation - create, delte update
	private void identifyMetadataOperations(){
		//Iterate on new object map and identify objects to delete
		for(String newObjectKey: mapNewSobjects.keySet()){
			if(! mapOldSobjects.containsKey(newObjectKey)){
				deleteSObject(newObjectKey);
			}else{
				//Remove map entries from old and new map
				mapNewSobjects.remove(newObjectKey);
				mapOldSobjects.remove(newObjectKey);
			}
		}
		
		//Iterate on new fields map and identify fields to delete/update
		for(String newFieldKey: mapNewFields.keySet()){
			if(! mapOldFields.containsKey(newFieldKey)){
				//Add fields to delete list
				deleteField(newFieldKey);
			}else {
				String oldFieldDefinition = JSON.serialize(mapOldFields.get(newFieldKey));
				String newFieldDefinition = JSON.serialize(mapNewFields.get(newFieldKey));
				//Field already exists thus update field
				if(oldFieldDefinition != newFieldDefinition){
					updateField(newFieldKey);
				}else{
					system.debug('--Fields are same');
				}
			}
		}
		
		//Delete custom object and list
		if(lstDelete != null && lstDelete.size() > 0){
			service.deleteMetadata(lstDelete);
		}
		
		//Update metadata information
		if(lstUpdate != null && lstUpdate.size() > 0){
			service.updateMetadata(lstUpdate);
		}
		
		//Iterate on old object map and create objects remaining
		for(String sObjectKey: mapOldSobjects.keySet()){
			createSObject(sObjectKey);
		}
		
		//Iterate on old field map to create custom fields
		for(String oldFieldKey: mapOldFields.keySet()){
			MetadataService.CustomField custField = createFieldDefinition(oldFieldKey, mapOldFields.get(oldFieldKey), true);
            if(custField != null){
				if(isFirstField){
					lstJobItems.add(new MetadataCreateJob.Item(custField, null, true));
					isFirstField = false;
				}else{
					lstJobItems.add(new MetadataCreateJob.Item(custField));
				}
			}
		}
		
		//Run job item to create metadata information
		MetadataCreateJob.run(lstJobItems,new MetadataCreateJob.EmailNotificationMetadataAsyncCallback());
		
	}
	
	//Function to create map of Sobject and its fields
	private void createFieldMap(String objectName, list<z_FieldDescription__c> lstFields, map<String, z_FieldDescription__c> mapFields){
		if(lstFields != null && lstFields.size() > 0){
			for(z_FieldDescription__c field: lstFields){
				mapFields.put((objectName + '.' + field.localName__c) ,field);
			}
		}
	}
	
	//Function to delete SObject and its field info from map
	private void deleteSObject(String sObjectName){
		//Add sObject to delete list
		MetadataService.CustomObject customObject = new MetadataService.CustomObject();
		customObject.fullName = sObjectName;
		lstDelete.add(customObject);
		
		//Remove field Information
		for(String newFieldKey: mapNewFields.keySet()){
			if(newFieldKey.contains(sObjectName + '.')){
				mapNewFields.remove(newFieldKey);
			}
		}
		mapNewSobjects.remove(sObjectName);
	}
	
	//Function to delete fields
	private void deleteField(String fieldName){
		MetadataService.CustomField custField = createFieldDefinition(fieldName, mapNewFields.get(fieldName), true);
		if(custField != null){
			lstDelete.add(custField);
			mapNewFields.remove(fieldName);
		}
	}
	
	//Function to update fields
	private void updateField(String newFieldKey){
		MetadataService.CustomField fieldToUpdate = createFieldDefinition(newFieldKey, mapOldFields.get(newFieldKey), true);
		if(fieldToUpdate != null){
			MetadataService.UpdateMetadata updateMetadata = new MetadataService.UpdateMetadata();
		    updateMetadata.currentName = newFieldKey;
		    updateMetadata.metadata = fieldToUpdate;
			lstUpdate.add(updateMetadata);
			
			//remove map entries
			mapOldFields.remove(newFieldKey);
			mapNewFields.remove(newFieldKey);
		}
	}
	
	//Function to create custom objects
	private void createSObject(String sObjectNameToCreate){
		z_SObjectDescription__c sObjectDescription = mapOldSobjects.get(sObjectNameToCreate);
		
		if(sObjectDescription != null && sObjectDescription.isCreateable__c){
			//Create SObject
			MetadataService.CustomObject customObject = new MetadataService.CustomObject();
			customObject.fullName = sObjectNameToCreate;
			customObject.label = sObjectDescription.label__c;
			customObject.pluralLabel = sObjectDescription.labelPlural__c;
			customObject.nameField = new MetadataService.CustomField();
			customObject.nameField.type_x = 'Text';
			customObject.nameField.label = sObjectDescription.label__c;
			customObject.deploymentStatus = 'Deployed';
			customObject.sharingModel = 'ReadWrite';
			
			lstJobItems.add(new MetadataCreateJob.Item(customObject));
		}
	}

	//Function to create custom fields
	private MetadataService.CustomField createFieldDefinition(String sObjectName, z_FieldDescription__c fieldToProcess, Boolean isFullNamePassed){
	    if(fieldToProcess != null && fieldToProcess.isCustom__c && !fieldToProcess.Name.equalsIgnoreCase('Name')){
		    MetadataService.CustomField customField = new MetadataService.CustomField();
		    if(isFullNamePassed){
		    	customField.fullName = sObjectName;
		    }else{
		    	customField.fullName = sObjectName + '.' + fieldToProcess.localName__c;
		    }
		    customField.label = fieldToProcess.label__c;
			
			//Set formula properties
			if(fieldToProcess.calculatedFormula__c != null && fieldToProcess.calculatedFormula__c != ''){
				customField.formula = fieldToProcess.calculatedFormula__c;
				if(fieldToProcess.type__c.equalsIgnoreCase('string')){
					customField.formulaTreatBlanksAs = 'BlankAsBlank ';
				}else{
					customField.formulaTreatBlanksAs = 'BlankAsZero';
				}
			}
			if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('String') && (fieldToProcess.calculatedFormula__c == null || fieldToProcess.calculatedFormula__c == '')){
				//Create a text field
				customField.type_x = 'Text';
				customField.length = Integer.valueOf(fieldToProcess.length__c);
			}else if(fieldToProcess.type__c != null && (fieldToProcess.type__c.equalsIgnoreCase('Picklist') || 
							fieldToProcess.type__c.equalsIgnoreCase('MULTIPICKLIST')) && fieldToProcess.picklistentries__c != null){
			    if(fieldToProcess.type__c.equalsIgnoreCase('Picklist')){
			    	customField.type_x = 'Picklist';
			    }else{
			    	customField.type_x = 'MultiselectPicklist';
			    	customField.visibleLines = 3;
			    }
			    metadataservice.Picklist picklistField = new metadataservice.Picklist();
			    picklistField.sorted= false;
			    List<metadataservice.PicklistValue> lstPicklistToCreate = new List<metadataservice.PicklistValue>();
			    
			    //Get picklist definitions from the Sobject fields object
			    List<String> lstPicklistEntries = fieldToProcess.picklistentries__c.split('\\n');
			    for(String pick: lstPicklistEntries){
			    	//Create picklist entries
			    	metadataservice.PicklistValue pickEntry = new metadataservice.PicklistValue();
			    	pickEntry.fullName = pick.split(':')[0].trim();
			    	pickEntry.default_x = false ;
			    	lstPicklistToCreate.add(pickEntry);
			    }
			    
			    picklistField.picklistValues = lstPicklistToCreate;
			    customField.picklist = picklistField ;
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('REFERENCE') && fieldToProcess.relationshipName__c != null && fieldToProcess.relationshipName__c != ''){
				//Create lookup or master detail relationship filed
				if(!fieldToProcess.isNillable__c){
					//Only master detail relationship have  nillable = false
					customField.type_x = 'MasterDetail';
				}else{
					customField.type_x = 'Lookup';
				}
				//Set relationship details
				customField.relationshipLabel = fieldToProcess.relationshipName__c.replaceAll('__r','');
				customField.relationshipName = fieldToProcess.relationshipName__c.replaceAll('__r','');
				customField.referenceTo = fieldToProcess.relationshipName__c.replaceAll('__r','__c');
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('boolean')){
				customField.type_x = 'Checkbox';
				customField.defaultValue = 'false';
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('currency')){
				//Create currency field
				customField.type_x = 'Currency';
				customField.scale = Integer.valueOf(fieldToProcess.scale__c);
				customField.precision = Integer.valueOf(fieldToProcess.precision__c);
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('TextArea') && Integer.valueOf(fieldToProcess.length__c) == 255){
				customField.type_x = 'TextArea';
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('TextArea') && Integer.valueOf(fieldToProcess.length__c) > 255){
				customField.type_x = 'LongTextArea';
				customField.length = Integer.valueOf(fieldToProcess.length__c);
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('Email')){
				customField.type_x = 'Email';
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('percent')){
				customField.type_x = 'Percent';
				customField.scale = Integer.valueOf(fieldToProcess.scale__c);
				customField.precision = Integer.valueOf(fieldToProcess.precision__c);
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('Double')){
				customField.type_x = 'Number';
				customField.scale = Integer.valueOf(fieldToProcess.scale__c);
				customField.precision = Integer.valueOf(fieldToProcess.precision__c);
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('DateTime')){
				customField.type_x = 'DateTime';
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('Date')){
				customField.type_x = 'Date';
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('Phone')){
				customField.type_x = 'Phone';
			}else if(fieldToProcess.type__c != null && fieldToProcess.type__c.equalsIgnoreCase('Url')){
				customField.type_x = 'Url';
			}else{
				return null;
			}
		   
		    return customField;
	    }else{
	    	return null;
	    }
	}
	
	//Function to get metadata service instance
	private MetadataService.MetadataPort createService(){ 
	    MetadataService.MetadataPort service1 = new MetadataService.MetadataPort();
	    service1.SessionHeader = new MetadataService.SessionHeader_element();
	    service1.SessionHeader.sessionId = UserInfo.getSessionId();
	    system.debug('--session Id: ' + UserInfo.getSessionId());
	    return service1;		
	}
	
}