global with sharing class z_BatchableMetadataDump3 implements Database.Batchable<SObject>,Database.AllowsCallouts, Database.Stateful {
    global Id exerciseId;
    global String snapshotType;
    global Boolean isDeleteData;
    
    global z_BatchableMetadataDump3(){
        this(null, null, false);
    }
    
    global z_BatchableMetadataDump3(Id exerciseId, String snapshotType, Boolean isDeleteData){
        this.exerciseId = exerciseId;
        this.snapshotType = snapshotType;
        this.isDeleteData = isDeleteData;
    }
    
    // z_BatchableMetadataDump2 should be executed before this call
    global database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([Select z_ChildSObjectDescription__c, childobjectname__c 
                From z_ChildRelationship__c where z_ParentSObjectDescription__r.Snapshot_Status__c =:snapshotType AND z_ParentSObjectDescription__r.Exercise__c = :exerciseId]);
    }

    global void execute(Database.BatchableContext BC, SObject[] scope){
        List<z_ChildRelationship__c> records = new List<z_ChildRelationship__c>();

        for(SObject record : scope) {
            z_ChildRelationship__c schema = (z_ChildRelationship__c) record;
            String objname = schema.childobjectname__c;
            
            List<z_SObjectDescription__c> tmps = [Select id From z_SObjectDescription__c Where name =: objname AND Exercise__c =:exerciseId AND Snapshot_Status__c = :snapshotType];
            if(tmps.size() == 0)
                continue;
            
            schema.z_ChildSObjectDescription__c = tmps[0].id;
            records.add(schema);
        }

        update records;
    }
    
    global void finish(Database.BatchableContext BC){
    	//ResetMetadata rm = new ResetMetadata(exerciseId);
    	//Check if isDeleteData is set to true. If true, then delete large data
    	if(isDeleteData != null && isDeleteData){
    		//Delete large data
    		List<z_MetaDumpSetting__c> lstSetting = [Select Id,Name__c from z_MetaDumpSetting__c where Exercise__c = :exerciseId];
    		if(lstSetting != null && lstSetting.size() > 0){
    			List<String> lstObjects = new List<String>();
    			for(z_MetaDumpSetting__c sett: lstSetting){
    				lstObjects.add(sett.Name__c);
    			}
    			Database.executeBatch(new DeleteLargeDataBatch('All', Userinfo.getUserId(), lstObjects));
    		}
    	}
    }      

}