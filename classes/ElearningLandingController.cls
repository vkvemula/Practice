/*
        Change log:
                KnowledgeLover: Added exception handling
*/

public class ElearningLandingController {
    private String excID{get;set;}
    
    public List<MessageWrapper> tasks               {get;set;}
    public Map<String,MessageWrapper> tasksMap      {get;set;}
    public List<MessageWrapper> steps               {get;set;}
    public Map<String,MessageWrapper> stepsMap      {get;set;}
    
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
    public Decimal currentStepSequence {get; set;} {currentStepSequence = 1;}
    
    public List<Attachment> listOfStepAttach {get; set;}
    
    //hint count variable for score calculation
    public Integer hintCount {get; set;}
    
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
    
    
    //
    public Exercise__c exercise                 {get;set;}
    
    //map of step sequence and step id, this is needed to easily navigate from one step to another
    private Map<Decimal, String> mapOfStepSequenceAndStepId;
    
    //flag for enabling poller
    public Boolean isPollerEnabled{get;set;}
    
    //flag for checking processing status
    public Boolean isProcessingComplete{get;set;}
    
    // Batch Id for getting new snapshot
    private set<String> setBatchId{get;set;}
    
    //points to be substracted from total points if user clicked on Hint.
    public String points_to_deduct{get;set;}
    public String deduction_points='0';
        
    //constructor
    public ElearningLandingController() {
        init();
    }
    
    private void init(){
        setBatchId = new set<String>();
        isPollerEnabled = false;
        isProcessingComplete = true;
        hintCount = 1000;
        points_to_deduct='0';
        tasksMap  = new Map<String,MessageWrapper>();
        tasks     = new List<MessageWrapper>();
        stepsMap  = new Map<String,MessageWrapper>();
        steps     = new List<MessageWrapper>();
        
        excID = ApexPages.currentPage().getParameters().get('id');
        String query = 'SELECT Name, Body__c, Summary__c, VideoID__c, ';
        query += ' (SELECT Id, Name, Sequence__c, Body__c, Status__c, Video_ID__c, Description__c, Status_Image__c FROM Tasks__r ORDER BY Sequence__c), ';
        query += ' (SELECT Name, ParentID, ContentType FROM Attachments) ';
        query += ' FROM Exercise__c WHERE id =\'' +excID+ '\' LIMIT 1';
        
        exercise = new Exercise__c();
        mapOfIdAndTask = new Map<String, Task__c>();
        mapOfTaskSequenceAndTaskId= new Map<Decimal, String>();
       
        if(excID != null && excID != ''){
            try{
                exercise = Database.query(query);
            }catch(Exception ex){
                Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, ex.getMessage()));
            }
            if(exercise != null){
                for(Task__c tk : exercise.Tasks__r){
                    tasks.add(new MessageWrapper(tk, null, null, true));
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
        
        for(MessageWrapper mw : tasks){
            tasksMap.put(mw.task.Id,mw);
        }
    }
    
    /*
     *@author: KnowledgeLover
     *@purpose: function to check snapshot status and create snapshot if it's not present.
    */
    public void checkSnapshot(){
        System.debug('--exercise : ' + excId);
        List<z_SObjectDescription__c> lstObjectDescription = [Select Id from z_SObjectDescription__c 
                where Exercise__c = :excId AND Snapshot_Status__c = 'Old'];
        
        //If list size is 0 then user is launching exercise for the first time
        if(lstObjectDescription != null && lstObjectDescription.size() == 0){
            system.debug('--Taking snapshot!');
            z_DumpFrontPageCont.executeDump(excId, 'Old', false);
        }
    }
    
    //@Author: KnowledgeLover
    //~Usage: function to invoke metadata reset.
    public void invokeReset(){
        ResetMetadata resetMeta = new ResetMetadata(excId);
    }
    
    //@Author: KnowledgeLover
    //~Usage: function to get status of batch jobs
    public void getBatchStatus(){
        set<string> setName = new set<String>();
        setName.add('z_BatchableMetadataDump1');
        setName.add('z_BatchableMetadataDump2');
        setName.add('z_BatchableMetadataDump3');
        List<ApexClass> lstApexClasses = [Select Id from ApexClass where Name IN :setName];
        List<AsyncApexJob> apexJobs = [Select TotalJobItems, Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed, Id, 
                JobType, ApexClassId, CreatedDate From AsyncApexJob Where ApexClassId IN :lstApexClasses Order by CreatedDate DESC];
        system.debug('--apexJobs: ' + JSON.serialize(apexJobs));
        
        if(apexJobs.size() == 0) {
            isPollerEnabled = false;
            isProcessingComplete = true;
        }else{
                isProcessingComplete = false;
            Integer completeCount = 0;
            for(AsyncApexJob job : apexJobs) {
                setBatchId.add(job.Id);
                if(job.status == 'Completed' || job.status == 'Aborted' || job.status == 'Failed')
                    completeCount ++;
                system.debug('--size: ' + apexJobs.size() + ' :: ' + completeCount);
            }
            if(completeCount == apexJobs.size()){
                 isProcessingComplete = true;
                 isPollerEnabled = false;
                 ResetMetadata rm = new ResetMetadata(excId);
            }else{
                 isProcessingComplete = false;
                 isPollerEnabled = true;
            }
        }

    }
    
    /**
    @author Manish
    @purpose get the Exercise record for which the Id is passed in the url, and create a map of all the step records
    
    public Exercise__c getExercise(){
        
        String excID = ApexPages.currentPage().getParameters().get('id');
        String query = 'SELECT Name, Body__c, ';
        query += ' (SELECT Name, Sequence__c, Body__c, Description__c, Status__c, Status_Image__c FROM Tasks__r ORDER BY Sequence__c) ';
        query += ' FROM Exercise__c WHERE id =\'' +excID+ '\' LIMIT 1';
        
        Exercise__c exc = new Exercise__c();
        mapOfIdAndTask = new Map<String, Task__c>();
        mapOfTaskSequenceAndTaskId= new Map<Decimal, String>();
        if(excID != null && excID != ''){
            exc = Database.query(query);
            if(exc != null){
                for(Task__c tk : exc.Tasks__r){
                    taskValid.put(tk.Id,null);
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
        
        
        return exc; 
    }*/
    
    /**
    @author Manish
    @purpose get next task
    */
    public PageReference changeToNextTask(){
        // Validate the current task before changing to next task.
        TaskAndStepValidator.ErrorsWrapper validate = TaskAndStepValidator.validateTaskorStep(currentTask.Id, true); 
        system.debug('validate ' + validate);
        
        tasksMap.get(currentTask.id).isReset = null;
        
        if(validate != null && !validate.isSuccess){
            tasksMap.get(currentTask.id).isValid = false;   
            tasksMap.get(currentTask.id).messages = validate.messages;
        }else {
            if(mapOfTaskSequenceAndTaskId.containsKey(currentTaskSequence + 1)){
                tasksMap.get(currentTask.id).isValid = true;
                currentTaskSequence = currentTaskSequence + 1;
                currentStep   = null;
                currentTask   = fetchCurrentTask(mapOfTaskSequenceAndTaskId.get(currentTaskSequence));
                currentTaskId = currentTask.id;
            }
            else
            recordExamScore(Exercise.id);
        }
        return null;
    }
    
    /**
    @author Manish
    @purpose get the list of steps for current task
    */
    private Task__c fetchCurrentTask(String tid){
        Task__c task = new Task__c();
        
        String query = 'SELECT Name, Sequence__c, Body__c, Status__c, Status_Image__c, Description__c, Video_ID__c, ';
        query += ' (SELECT Name, Body__c, Sequence__c, Description__c, VideoID__c,Total_points__c FROM Steps__r ORDER BY Sequence__c), ';
        query += ' (SELECT Name, ParentID, ContentType FROM Attachments) ';
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
                steps.add(new MessageWrapper(task, st, null, false));
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
        
        for(MessageWrapper mw : steps){
            if(!stepsMap.containsKey(mw.step.id))
                stepsMap.put(mw.step.Id,mw);
        }
        
         system.debug('stepsMap' + stepsMap);
        
        return task;
    } 
    
    /**
    @author Manish
    @purpose get next step
    */
    public PageReference changeToNextStep(){
        //function called to calculate and record the step score
        String currStepId_beforeMod = currentStepId;
        String idprevioustask=currentTask.id; 
            
        if(!String.isBlank(currentStepId)) {
            TaskAndStepValidator.ErrorsWrapper validate = TaskAndStepValidator.validateTaskorStep(currentStepId, false); // Validate the currentStep before moving to next step.
            
            // @sfdcdev11981 getting null pointer error. So added check to avolid calling method on a null object.
            if(currentStep == null || stepsMap.get(currentStep.id) == null) return null;
            
            stepsMap.get(currentStep.id).isReset = null;
            if(validate != null && !validate.isSuccess){
                //Step is not successful
                stepsMap.get(currentStep.id).isValid = false;
                stepsMap.get(currentStep.id).messages = validate.messages;
            }else {
                //Validation successful
                system.debug('--in else');
                if(mapOfStepSequenceAndStepId.containsKey(currentStepSequence + 1)){
                    //Go to next step 
                    deduction_points=points_to_deduct;
                    stepsMap.get(currentStep.id).isValid = true;
                    currentStepSequence = currentStepSequence + 1;
                    currentStepId = mapOfStepSequenceAndStepId.get(currentStepSequence);
                    currentStep = mapOfIdAndStep.get(currentStepId);
                    listOfStepAttach = fetchListOfAttachments(currentStepId);
                    recordStepScore(currStepId_beforeMod);
                    recordTaskScore(idprevioustask);
                    recordExamScore(Exercise.id);
        
                         
                }else{
                    if(currentStep != null && stepsMap.get(currentStep.id) != null){
                        deduction_points=points_to_deduct;
                        stepsMap.get(currentStep.id).isValid = true;
                        recordStepScore(currStepId_beforeMod);
                        recordTaskScore(idprevioustask);
                        recordExamScore(Exercise.id);
                    }
                    recordTaskScore(idprevioustask);
                    recordExamScore(Exercise.id);
                    changeToNextTask();
                }
            }
                
            //SPR - 6/25/13 - Added to fix next step issue with validations
            if(validate != null){
                if(currentStep != null){
                    MessageWrapper msgWrapper = stepsMap.get(currentStep.id);
                    if(msgWrapper != null)
                        stepsMap.get(currentStep.id).messages = validate.messages;
                }
            }
            //SPR - End Change
            
        }else{
            changeToNextTask();
        }
        return null;
    }
    
   
    /**
    @author  : Sugan
    @purpose : To calculate and record the score at the end of each step, note that this function would be called from the NextStep function
    **/
     private void recordStepScore(String currentStepId_temp)
    {
    System.debug('######points to deduct is#######'+points_to_deduct);
        system.debug('step -- '+currentStepId_temp+' hintCnt -- '+hintCount );
        Integer tempScoreVar = 0;
        Step__c currStep = [Select Id,Total_points__c from Step__c where Id = :currentStepId_temp];
        Integer scoreforstep=Integer.valueOf(currStep.Total_points__c)-Integer.valueOf(deduction_points);
        if(hintCount == 1000)
            tempScoreVar = Integer.valueOf(currStep.Total_points__c);
        else
            tempScoreVar = hintCount;

        //before creating a score record we check if the score has already been recorded and update this score if present
        List<Score__c> prevScores = [Select Id,Final_Score__c from Score__c where User__c = :UserInfo.getUserId() AND Step__c = :currentStepId_temp];
        
        Score__c prevScore;
        if(prevScores != null && prevScores.size() > 0)
        {
         /*   prevScore = prevScores.get(0);
            prevScore.Final_Score__c = 12;
            update prevScore;
            hintCount = 1000; */
        }
        else //otherwise we create a new score record
        {
            Score__c scoreRecordForThisStep = new Score__c(Name=UserInfo.getName()+'--'+DateTime.now(),User__c = UserInfo.getUserId(), Step__c =currentStepId_temp, Final_Score__c = scoreforstep,Task__c=currentTaskId,maxPossibleScore__c=currStep.Total_points__c);
            insert scoreRecordForThisStep;
            hintCount = 1000;
        }
    } 
        //By Sachin Kadian to record score of at the end of each task. Task Score will be sum of scores of every Step of that task.
    public void recordTaskScore(String task_ended)
    {
        //if the task score for current task exists already,update it
        List<Task_Score__c> prevScores = [Select Id,score__c from Task_Score__c where User__c = :UserInfo.getUserId() AND Task__c = :task_ended];
        Task_Score__c prevScore;
        if(prevScores != null && prevScores.size() > 0)
        {
            prevScore = prevScores.get(0);
            rollUpStepScoreToTask(task_ended,prevScore.id);
        }
        else //otherwise we create a new Task_Score record
        {
            Task_Score__c taskScoreRecordForThisTask = new Task_Score__c(Task__c =task_ended,Exercise__c=exercise.id,User__c = UserInfo.getUserId());
            insert taskScoreRecordForThisTask;
            rollUpStepScoreToTask(task_ended,taskScoreRecordForThisTask.id);
        }
        
    }
    
    // Sum all the steps scores related to the task and update into Task_Score
    public void rollUpStepScoreToTask(String id_of_task,String taskScoreRecordForThisTask)
    {
        Integer Score=0;
        Integer maxPossibleScore=0;
        for(Score__c scores:[select Final_Score__c,maxPossibleScore__c from Score__c where User__c = :UserInfo.getUserId() AND Task__c=: id_of_task])
        {
        
            Score+=Integer.valueOf(scores.Final_Score__c);
            maxPossibleScore+=Integer.valueOf(scores.maxPossibleScore__c);
        }
        Task_Score__c tasktoupdate=new Task_Score__c(id=taskScoreRecordForThisTask);
        tasktoupdate.score__c=Score;
        tasktoupdate.maxPossibleScore__c=maxPossibleScore;
        update tasktoupdate;
    }
    
    
        //By Sachin Kadian to record score of at the end of each exam. Exam Score will be sum of scores of every task of that Exercise.
    public void recordExamScore(String exercise_ended)
    {
        //if the task score for current task exists already,update it
        List<Exam_Score__c> prevScores = [Select Id,Total_Points__c,maxPossibleScore__c from Exam_Score__c where User__c = :UserInfo.getUserId() AND Exercise__c = :exercise_ended];
        Exam_Score__c prevScore;
        if(prevScores != null && prevScores.size() > 0)
        {
            prevScore = prevScores.get(0);
            rollUpTaskScoreToExam(exercise_ended,prevScore.id);
        }
        else //otherwise we create a new Task_Score record
        {
            Exam_Score__c taskScoreRecordForThisexam = new Exam_Score__c(Exercise__c =exercise_ended,User__c = UserInfo.getUserId());
            insert taskScoreRecordForThisexam;
            rollUpTaskScoreToExam(exercise_ended,taskScoreRecordForThisexam.id);
        }
        
    }
    
    // Sum all the steps scores related to the task and update into Task_Score
    public void rollUpTaskScoreToExam(String id_of_exam,String taskScoreRecordForThisexam)
    {
        Integer Score=0;
        Integer maxPossibleScore=0;
        for(Task_Score__c scores:[select score__c,maxPossibleScore__c from Task_Score__c where User__c = :UserInfo.getUserId() AND Exercise__c=: id_of_exam])
        {
            Score+=Integer.valueOf(scores.score__c);
            maxPossibleScore+=Integer.valueOf(scores.maxPossibleScore__c);
        }
        Exam_Score__c Examtoupdate=new Exam_Score__c(id=taskScoreRecordForThisexam);
        Examtoupdate.Total_Points__c=Score;
        Examtoupdate.maxPossibleScore__c=maxPossibleScore;
        update Examtoupdate;
    }
    /**
    @author Manish
    @purpose get list of attachments, this is done seperately because of the governor limit that says, 'Binary Fields cannot be selected in join queries'
    */
    private List<Attachment> fetchListOfAttachments(String stepId){
        String query = 'SELECT Name, ParentID, ContentType ';
        query += ' FROM Attachment WHERE ParentID= \''+stepId+'\'';
        if(currentStep != null){
            try{
                return Database.query(query);
            }catch(Exception ex){
                return null;                    
            }
        }else{
            return null;
        }
    }
    
    public void rollBacktoFirst(){
        system.debug('--setBatchId: ' + setBatchId);
        Id batchId = z_DumpFrontPageCont.executeDump(excId, 'New', true);
        setBatchId.add(batchId);
        getBatchStatus();
        isPollerEnabled = true;
        //return new Pagereference('/apex/eLearningLandingPage?id='+exercise.id);
    }
    
    public Pagereference changeToPrevTask() {
        // @sfdcdev11981   Update the code to support return type 
        TaskAndStepValidator.ErrorsWrapper resetSuccessful = TaskAndStepValidator.resetTaskOrStep(currentTask.Id, true); // reset the current task 
        if(resetSuccessful == null || resetSuccessful.isSuccess){
                        // @sfdcdev11981 added null check to avoid null pointer exception.
                        if(currentTask != null){
                        tasksMap.get(currentTask.id).isReset = true;
                        tasksMap.get(currentTask.id).isValid = null;
                        }
                if(currentTaskSequence > 0 && mapOfTaskSequenceAndTaskId.containsKey(currentTaskSequence - 1)){
                    currentTaskSequence = currentTaskSequence - 1;
                    currentStep   = null;
                    currentTask   = fetchCurrentTask(mapOfTaskSequenceAndTaskId.get(currentTaskSequence));
                    currentTaskId = currentTask.id;
                }
        }else {
                // @sfdcdev11981 added null check to avoid null pointer exception.
                if(currentTask != null){
                    tasksMap.get(currentTask.id).isReset = false;
                    tasksMap.get(currentTask.id).isValid = false;
                    tasksMap.get(currentTask.id).messages = resetSuccessful.messages; 
                }  
        }
        return null;
    }
    
    public Pagereference changeToPrevStep(){
        if(currentStepId != null){
                // @sfdcdev11981   Update the code to support return type 
            TaskAndStepValidator.ErrorsWrapper resetSuccessful =  TaskAndStepValidator.resetTaskOrStep(currentStepId, false); // Validate the currentStep before moving to next step.
            system.debug(resetSuccessful);
            if(resetSuccessful != null && !resetSuccessful.isSuccess){
                // @sfdcdev11981 getting null pointer error. So added check to avolid calling method on a null object.
                if(currentStep != null) {
                        stepsMap.get(currentStep.id).isReset = false;
                        stepsMap.get(currentStep.id).messages = resetSuccessful.messages;   
                }
            } else {
                // @sfdcdev11981 getting null pointer error. So added check to avolid calling method on a null object.
                if(currentStep != null) {
                        stepsMap.get(currentStep.id).isReset = true;
                        stepsMap.get(currentStep.id).isValid = null;
                }
                
                if(currentStepSequence > 0 && mapOfStepSequenceAndStepId.containsKey(currentStepSequence - 1)){
                    currentStepSequence = currentStepSequence - 1;
                    currentStepId = mapOfStepSequenceAndStepId.get(currentStepSequence);
                    currentStep = mapOfIdAndStep.get(currentStepId);
                    listOfStepAttach = fetchListOfAttachments(currentStepId);
                }else{
                    changeToPrevTask();
                }
            }
            
            // @sfdcdev11981 To show success message also.
            if(resetSuccessful != null){
                if(currentStep != null){
                    MessageWrapper msgWrapper = stepsMap.get(currentStep.id);
                    if(msgWrapper != null)
                        stepsMap.get(currentStep.id).messages = resetSuccessful.messages;
                }
            }
        }else{
            changeToPrevTask();
        }
        return null;
    }
    
    public class MessageWrapper {
        public Step__c step          {get;set;}
        public Task__c task          {get;set;}
        public boolean isValid       {get;set;}
        public boolean isReset       {get;set;}
        public List<String> messages {get;set;}
        
        public MessageWrapper(Task__c t, Step__c s, boolean isValid, boolean isTask){
            if(isTask){
                task = t;
            }else{
                step = s;
                task = t;
            }
            this.isValid = isValid;
            messages = new List<String>();  
        }
    }
}