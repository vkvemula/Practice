/*
	Change Log:
	1. @sfdcdev11981  11 July, 2013  Updated the test code to support Reset__c object changes added to the JSONBuilderCon class
*/
@isTest
private class TestJSONBuilderCon {

	static testmethod void jsonBuilderTest(){
		
		List<Validate__c> validateQuestions = new List<Validate__c>();
		List<Reset__c> resetQuestions = new List<Reset__c>();
		
		String validationJSON =  '{ '+
			'\"query\" : { '+
			'\"whereFields\" : [ { '+
			'\"whrValue\" : \"John Smith\", '+
			'\"whrType\" : \"String\", '+
			'\"whrOperator\" : \"=\", '+
			'\"whrField\" : \"Name\", '+
			'\"nextwhrANDOR\" : \"AND\" '+
			'}, { '+
			'\"whrValue\" : \"Google\", '+
			'\"whrType\" : \"String\", '+
			'\"whrOperator\" : \"=\", '+
			'\"whrField\" : \"Company\", '+
			'\"nextwhrANDOR\" : null '+
			'} ], '+
			'\"returnFields\" : [ \"Id\", \"Name\" ], '+
			'\"orderFields\" : [ \"CreatedDate\" ], '+
			'\"orderDir\" : \"ASC\", '+
			'\"limitQuery\" : \"10\" '+
			'}, '+
			'\"objectName\" : \"Lead\", '+
			'\"fieldValues\" : null, '+
			'\"action\" : \"READ\" '+
			'}';
		
		String resetjson = '{ '+
			'\"query\" : { '+
			'\"whereFields\" : [ { '+
			'\"whrValue\" : \"John Smith\", '+
			'\"whrType\" : \"String\", '+
			'\"whrOperator\" : \"=\", '+
			'\"whrField\" : \"Name\", '+
			'\"nextwhrANDOR\" : \"AND\" '+
			'}, { '+
			'\"whrValue\" : \"Google\", '+
			'\"whrType\" : \"String\", '+
			'\"whrOperator\" : \"=\", '+
			'\"whrField\" : \"Company\", '+
			'\"nextwhrANDOR\" : null '+
			'} ], '+
			'\"returnFields\" : [ \"Id\", \"Name\" ], '+
			'\"orderFields\" : [ \"CreatedDate\" ], '+
			'\"orderDir\" : \"ASC\", '+
			'\"limitQuery\" : \"10\" '+
			'}, '+
			'\"objectName\" : \"Lead\", '+
			'\"fieldValues\" : null, '+
			'\"action\" : \"DELETE\" '+
			'}';
		
		String metajson = '{ '+
			'\"metadataType\" : \"CustomField\", '+
			'\"metadataName\" : \"Verify__c.Verified__c\", '+
			'\"action\" : \"READ\" '+
			'}';
		
		resetQuestions.add(new Reset__c(Body__c='What is a test SOQL?',Reset_Type__c='SOQL', Reset_Body__c =resetjson));
		resetQuestions.add(new Reset__c(Body__c='What is a test Meta?',Reset_Type__c='Metadata', Reset_Body__c=metajson));
		validateQuestions.add(new Validate__c(Body__c='What is a test Meta 2?',Type__c='Metadata',Validation__c=metajson));
		validateQuestions.add(new Validate__c(Body__c='What is a test Meta 3?',Type__c='Metadata',Validation__c=metajson));
		
		insert validateQuestions;
		insert resetQuestions;
		
		Test.startTest();
			Pagereference testPage = Page.JSONBuilder;
			Test.setCurrentPageReference(testPage);
			Apexpages.currentPage().getParameters().put('id',resetQuestions[1].Id);
			
			JSONBuilderCon testCon = new JSONBuilderCon();		
			testCon.getallActions();
			testCon.getallTypes();
			testCon.selectedType = 'CustomField';
			testCon.buildJSONasInput();
			testCon.generateJSONforRESET();
			testCon.action = 'DELETE';
			testCon.saveReset();
		Test.stopTest();
	}

}