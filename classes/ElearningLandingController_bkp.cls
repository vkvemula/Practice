/*
	Change log:
		KnowledgeLover: Added exception handling
*/

public with sharing class ElearningLandingController_bkp {
	//current task id
    public String currentTaskId {get; set;}
    
    //current task record
    public Task__c currentTask {get; set;}
    
    //current task sequence. used internally
    public Decimal currentTaskSequence {get; set;}{currentTaskSequence = 1;}
    
    //current step id
    public String currentStepId {get; set;}
    
    //current step record
    public Step__c currentStep {get; set;}
    
    //current step sequence. used internally
    private Decimal currentStepSequence = 1;
    
    public List<Attachment> listOfStepAttach {get; set;}
    
    //header for the page
    public String pageHeader { 
        get{
            return 'eLearning';
        } 
        set; 
    }
    
    //map of id and record for Task__c object
    public Map<String, Task__c> mapOfIdAndTask {get; set;}
    
    //map of task sequence and task id, this is needed to easily navigate from one task to another
    private Map<Decimal, String> mapOfTaskSequenceAndTaskId;
    
    //map of id and record for Step__c object
    public Map<String, Step__c> mapOfIdAndStep {get; set;}
    
    //map of step sequence and step id, this is needed to easily navigate from one step to another
    private Map<Decimal, String> mapOfStepSequenceAndStepId;
    
    
    /**
    @author Manish
    @purpose get the Exercise record for which the Id is passed in the url, and create a map of all the step records
    */
    public Exercise__c getExercise(){
        Exercise__c exc = new Exercise__c();
        String excID = ApexPages.currentPage().getParameters().get('id');
        if(excId != null){
	        String query = 'SELECT Name, Body__c, ';
	        query += ' (SELECT Name, Sequence__c, Body__c, Status__c, Status_Image__c FROM Tasks__r ORDER BY Sequence__c) ';
	        query += ' FROM Exercise__c WHERE id =\'' +excID+ '\' LIMIT 1';
	        
	        mapOfIdAndTask = new Map<String, Task__c>();
	        mapOfTaskSequenceAndTaskId= new Map<Decimal, String>();
	        if(excID != null && excID != ''){
	            try{
	            	exc = Database.query(query);
	            }catch(Exception ex){
	            	Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, ex.getMessage()));
	            }
	            if(exc != null){
	                for(Task__c tk : exc.Tasks__r){
	                    mapOfIdAndTask.put(tk.id, tk);
	                    mapOfTaskSequenceAndTaskId.put(tk.sequence__c, tk.id);
	                    if(currentTask == null){
	                        currentTask = fetchCurrentTask(tk.Id);
	                        currentTaskId = tk.id;
	                        currentTaskSequence = tk.Sequence__c;
	                    }
	                }
	            }
	        }
        }
        
        return exc; 
    }
    
    /**
    @author Manish
    @purpose get next task
    */
    public PageReference changeToNextTask(){
        if(mapOfTaskSequenceAndTaskId.containsKey(currentTaskSequence + 1)){
            currentStep = null;
            currentTaskSequence = currentTaskSequence + 1;
            currentTask = fetchCurrentTask(mapOfTaskSequenceAndTaskId.get(currentTaskSequence));
            currentTaskId = currentTask.id;
        }
        return null;
    }
    
    /**
    @author Manish
    @purpose get the list of steps for current task
    */
    private Task__c fetchCurrentTask(String tid){
        Task__c task = new Task__c();
        
        String query = 'SELECT Name, Sequence__c, Body__c, Status__c, Status_Image__c, ';
        query += ' (SELECT Name, Body__c, Sequence__c, Description__c, VideoID__c FROM Steps__r ORDER BY Sequence__c) ';
        query += ' FROM Task__c WHERE id = \''+tid+'\' LIMIT 1';
        
        try{
        	task = Database.query(query);
        }catch(Exception ex){
        	Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        
        mapOfIdAndStep = new Map<String, Step__c>();
        mapOfStepSequenceAndStepId= new Map<Decimal, String>();
        
        if(task != null){
            for(Step__c st : task.Steps__r){
                mapOfIdAndStep.put(st.Id, st);
                mapOfStepSequenceAndStepId.put(st.sequence__c, st.id);
                if(currentStep == null){
                    currentStep = st;
                    currentStepId = st.id;
                    currentStepSequence = st.Sequence__c;
                    listOfStepAttach = fetchListOfAttachments(currentStepId);
                }
            }
        }
        
        return task;
    } 
    
    /**
    @author Manish
    @purpose get next step
    */
    public PageReference changeToNextStep(){
        if(mapOfStepSequenceAndStepId.containsKey(currentStepSequence + 1)){
            currentStepSequence = currentStepSequence + 1;
            currentStepId = mapOfStepSequenceAndStepId.get(currentStepSequence);
            currentStep = mapOfIdAndStep.get(currentStepId);
            listOfStepAttach = fetchListOfAttachments(currentStepId);
        }else{
            changeToNextTask();
        }
        return null;
    }
    
    /**
    @author Manish
    @purpose get list of attachments, this is done seperately because of the governor limit that says, 'Binary Fields cannot be selected in join queries'
    */
    private List<Attachment> fetchListOfAttachments(String stepId){
        String query = 'SELECT Name, ParentID, ContentType ';
        query += ' FROM Attachment WHERE ParentID= \''+stepId+'\'';
        if(currentStep != null){
            return Database.query(query);
        }else{
            return null;
        }
    }
}