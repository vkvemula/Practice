global with sharing class z_BatchableMetadataDump1 implements Database.Batchable<SObject>, Database.Stateful {

    global Boolean executeBatch2;
    global Id exerciseId;
    global String snapshotType;
    global Boolean isDeleteData;
    
    global z_BatchableMetadataDump1() {
        // flag if z_BatchableMetadataDump2 is executed after this class is completed
        this(false, null, null, false);
    }
    
    global z_BatchableMetadataDump1(Boolean executeBatch2) {
        // flag if z_BatchableMetadataDump2 is executed after this class is completed
        this(executeBatch2, null, null, false);
    }
    
    global z_BatchableMetadataDump1(Boolean executeBatch2, Id exerciseId, String snapshotType, Boolean isDeleteData) {
        this.executeBatch2 = executeBatch2;
        this.exerciseId = exerciseId;
        this.snapshotType = snapshotType;
        this.isDeleteData = isDeleteData;
    }   
    
    global database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([Select objname__c from z_SchemaTemp__c 
                where Exercise__c =:exerciseId AND Snapshot_Status__c = :snapshotType]);
    }

    global void execute(Database.BatchableContext BC, SObject[] scope){
        // Array size should be 1 because of governer limit
        z_SchemaTemp__c obj = (z_SchemaTemp__c) scope[0];
        Id recordid = z_DescribeHelper.insertSObjectDescriptionRecord(obj.objname__c, exerciseId, snapshotType);
        
        List<z_SchemaTemp__c> records = new List<z_SchemaTemp__c>();
        for(String field : z_DescribeHelper.getFieldNames(obj.objname__c)) {
            records.add(new z_SchemaTemp__c(objid__c = recordid, objname__c = obj.objname__c, 
                    fieldname__c = field, exercise__c = exerciseId, Snapshot_Status__c = snapshotType));
        }
        // add multiple field descriptions to temporary table named z_SchemaTemp__c
        insert records;
        delete obj;
    }    

    global void finish(Database.BatchableContext BC){
        /*if(!executeBatch2)
            return;
        
        // after 2mins, z_BatchableMetadataDump2 class will be executed
        Datetime dt = System.now();
        String coreExpression = z_Util.convertToStringForScheduler(dt.addMinutes(2));
        System.schedule('z_BatchableMetadataDump2', coreExpression, new z_SchedulableBatchableMetadataDump2());*/
        
        Database.executeBatch(new z_BatchableMetadataDump2(false, exerciseId, snapshotType, isDeleteData));
    }      
}