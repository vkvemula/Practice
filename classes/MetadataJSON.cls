/***************************************************************************
 Name 	    : MetadataJSON
 Created By : Kartik Viswanadha

****************************************************************************/

/*
	
	JSON Structure to be used in Question object records for Validation of any Metadata Type

*/
public with sharing class MetadataJSON {

	
	public class MetadataSubTypes {
		public String metadataType					{get;set;}
		public String metadataName					{get;set;}
	}

	public String metadataType						{get;set;}
	public String metadataName						{get;set;}
	public List<MetadataSubTypes> metadataSubTypes  {get;set;}
	public String   action						    {get;set;}
	public String	mDataString					    {get;set;}		
	
	
}