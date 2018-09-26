/***************************************************************************
 Name 	    : SOQLValidator
 Created By : Kartik Viswanadha

----------------------------------------------------------------------------
Change Log
----------------------------------------------------------------------------
1. KnowledgeLover:  1) added final strings for comparisions
					2) added exception handling while deserializing jsonString 
						to SoqlJSON object

****************************************************************************/

/*
 *@Description: Record CRUD, This class is the main class to perform READ, 
 				CREATE, UPDATE, DELETE on the Salesforce Records. 
 */
public with sharing class SOQLValidator {
	private static final String ACTION_READ = 'READ';
	private static final String ACTION_CREATE = 'CREATE';
	private static final String ACTION_UPDATE = 'UPDATE';
	private static final String ACTION_DELETE = 'DELETE';
	
	private static final String WHERE_TYPE_STRING = 'String';
	private static final String WHERE_TYPE_SUBQUERY = 'Subquery';

	public static boolean validationSOQL(String jsonString){
		SoqlJSON soqljs;
		
		try{
			soqljs = (SoqlJSON)JSON.deserialize(jsonString,SoqlJSON.class);
		}catch(Exception ex){
			return false;
		}
		
		if(soqljs.action == ACTION_READ){
			String soqlQuery = buildQuery(soqljs);
			List<SObject> recs = new List<Sobject>();
			try{
				recs = Database.query(soqlQuery);
			}catch(Exception ex){
				return false;
			}
			
			if(recs.size() == 0 )
				return false;

			if(recs.size() != Integer.valueof(soqljs.query.limitQuery))
				return false;
		}else if(soqljs.action == ACTION_CREATE){
			SObject newObject = Schema.getGlobalDescribe().get(soqljs.objectName).newSObject();
			
			for(SoqlJSON.Fields fs : soqljs.fieldValues){
				newObject.put(fs.fieldname,fs.value);
			}
			
			try {
				insert newObject;
			}catch(DMLException e){
				return false;
			}
		}else if(soqljs.action == ACTION_UPDATE){
			String soqlQuery = buildQuery(soqljs);
			List<SObject> recs = new List<Sobject>();
			
			try{
				recs = Database.query(soqlQuery);
			}catch(Exception ex){
				return false;
			}
			
			if(recs.size() == 0)
				return false;
			
			for(SObject s : recs){
				for(SoqlJSON.Fields fs : soqljs.fieldValues){
					s.put(fs.fieldname,fs.value);
				}
			}
			
			try {
				update recs;	
			}catch(DMLException e){
				return false;
			}
			
		}else if(soqljs.action == ACTION_DELETE){
			String soqlQuery   = buildQuery(soqljs);
			List<SObject> recs = new List<Sobject>();
			
			try{
				recs = Database.query(soqlQuery);
			}catch(Exception ex){
				return false;
			}
			
			if(recs.size() == 0)
				return false;
			try {
				delete recs;	
			}catch(DMLException e){
				return false;
			}
				
		}
		return true;
	}
	
	//~Usage: function to build query for READ, UPDTE and DELETE actions
	public static String buildQuery(SoqlJSON soqljs){
		String soql = 'SELECT ';
		
		for(String s : soqljs.query.returnFields){
			soql += s + ',';
		}
		
		soql = soql.removeEnd(',');
		soql += ' FROM ' + soqljs.objectName;
		String whrCondition = '';

		for(SoqlJSON.WhereConditions wc : soqljs.query.whereFields){
			if(wc.whrType == WHERE_TYPE_STRING)
				whrCondition += wc.whrField + ' ' + wc.whrOperator + ' \'' + wc.whrValue + '\' ' + wc.nextwhrANDOR + ' ';
			else if(wc.whrType == WHERE_TYPE_SUBQUERY){
				whrCondition += wc.whrField + ' ' + 'IN '  + wc.whrValue  + ' ' + wc.nextwhrANDOR + ' ';
			}
			else
				whrCondition += wc.whrField + ' ' + wc.whrOperator + ' \'' + wc.whrValue + '\' ' + wc.nextwhrANDOR + ' ';
		}
		
		if(whrCondition != ''){
			whrCondition = whrCondition.removeEnd('AND ');
			whrCondition = whrCondition.removeEnd('OR ');
		}
		
		String orderCondition = '';
		
		for(String s : soqljs.query.orderFields){
			orderCondition += s + ',';
		}
		
		if(orderCondition != ''){
			orderCondition = orderCondition.removeEnd(','); 
		
			if(soqljs.query.orderDir != null && soqljs.query.orderDir != '' && (soqljs.query.orderDir == 'Descending' || soqljs.query.orderDir == 'Desc')){
				orderCondition += ' DESC';
			}else{
				orderCondition += ' ASC';
			}
		}
		
		if(whrCondition != '')
			soql = soql + ' WHERE ' + whrCondition;
			
		if(orderCondition != '')
			soql = soql + ' ORDER BY ' + orderCondition;	
		
		
		if(soqljs.query.limitQuery != null && soqljs.query.limitQuery != '')
			soql = soql + ' LIMIT ' + soqljs.query.limitQuery;
		
		return soql.replace('null','');
	}
}