/*
 * @Author: KnowledgeLover
 * @Description: Batch to delete large data created by any user.
 */
public with sharing class DeleteLargeDataBatch implements Database.Batchable<SObject>, Database.Stateful{
	/*	sObject to delete	*/
	private String sObjectName{get;set;}
	
	/*	userId whose records are to be deleted	*/
	private String userId {get;set;}
	
	/*	List of sObjects to process after this batch completes	*/
	private List<String> lstObjectName{get;set;}
	
	//Constructor
	public DeleteLargeDataBatch(String sObjectNameToDelete, String createdBy, List<String> lstObjName){
		this.sObjectName = sObjectNameToDelete;
		this.userId = createdBy;
		this.lstObjectName = lstObjName;
	}
	
	 /* Called at the beginning of the APEX Job */
    public Database.QueryLocator start(Database.BatchableContext BC) {
    	String query;
    	//If sObjectName is All, then extracts first sObject name from the list and process
    	if(sObjectName != null && sObjectName.equalsIgnoreCase('All') && lstObjectName != null && lstObjectName.size() > 0){
    		sObjectName = lstObjectName[0];
    	}
		query = 'Select Id from ' + sObjectName + ' where createdById = \'' + userId + '\'';
		return Database.getQueryLocator(query);
    } 
    
    /* The execute method is called for each batch of records passed to the method. 
       This method deletes records for each chunk of data. 
    */
    public void execute(Database.BatchableContext BC, List<SObject> sobjectList) {
    	try{
    		//Delete all records. Even if some records fail to delte, try deleting other records
    		Database.delete(sObjectList, false);
    	}catch(Exception ex){
    		system.debug('--Exception: ' + ex.getMessage());
    	}
    }
    
    /* The finish method is called after all batches are processed. Perform post processing here */
    public void finish(Database.BatchableContext BC) {
        //Remove current sObject (That was processed in this batch) and start batch to delete records of sObject present in list
        if(lstObjectName != null && lstObjectName.size() > 1){
        	lstObjectName.remove(0);
    		Database.executeBatch(new DeleteLargeDataBatch(lstObjectName[0], userInfo.getUserId(), lstObjectName));
    	}
    }
    
    /*************************************************
        Test Methods
    *************************************************/
    //Setup data for test method
    public static void createAccountData(){
    	List<Account> lstAccount = new list<Account>();
    	for(Integer i=0; i<50; i++){
    		Account a = new Account(name = 'Account ' + i);
    		lstAccount.add(a);
    	}
    	
    	insert lstAccount;
    }
    
    //~test method to test batch
    public static testmethod void testProbabilityCalculation(){
        createAccountData();
        
        Test.startTest();
            String jobId = Database.executeBatch(new DeleteLargeDataBatch('Account', Userinfo.getUserId(), null));
            system.assertNotEquals(jobId, null);
        Test.stopTest();
    }
    
    //~test method to test batch
    public static testmethod void testProbabilityCalculation1(){
        createAccountData();
        List<String> objList = new List<String>();
        objList.add('Account');
        objList.add('Contact');
        
        Test.startTest();
            String jobId = Database.executeBatch(new DeleteLargeDataBatch('All', Userinfo.getUserId(), objList));
            system.assertNotEquals(jobId, null);
        Test.stopTest();
    }
}