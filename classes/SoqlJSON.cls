/***************************************************************************
 Name 	    : SoqlJSON
 Created By : Kartik Viswanadha

****************************************************************************/
/*
	
JSON Structure for SOQL type Structure when building question records
*/

public with sharing class SoqlJSON {
	
	public String objectName 		 		 {get;set;}
	public String action					 {get;set;}  // READ, CREATE, UPDATE, DELETE, UNREAD
	public SOQLQuery query				     {get;set;}  // Query Builder
	public List<Fields> fieldValues		 	 {get;set;}  // If update set this with the new values
	
	
	public class SOQLQuery {
		
		public List<String> returnFields 		 {get;set;}
		public List<WhereConditions> whereFields {get;set;}
		public List<String> orderFields			 {get;set;}
		public String orderDir			    	 {get;set;}
		public String limitQuery				 {get;set;} 
		 
	}
	
	public class WhereConditions {
		public String whrField	      {get;set;}
		public String whrOperator     {get;set;}
		public String whrValue 	      {get;set;}
		public String whrType	  	  {get;set;} // String or No String 
		public String nextwhrANDOR	  {get;set;}
	}
	
	public class Fields 	{
		public String fieldName  {get;set;}
		public String value	 	 {get;set;}
	}
	
}