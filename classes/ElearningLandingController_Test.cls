/**
 * @author Manish
 * @purpose Test class for ElearningLandingController
 */
@isTest
private class ElearningLandingController_Test{
    
    static testMethod void myUnitTest() {
        
        //list of task to insert
        List<Task__c> listOfTask= new List<Task__c>();
        
        //list of step to insert
        List<Step__c> listOfStep = new List<Step__c>();
        
        //lets create a test exercise
        Exercise__c testExc = new Exercise__c(Status__c = 'Active', Sequence__c = 1, Body__c = 'Test Some Data');
        Database.insert(testExc);
        
        // some test tasks
        Task__c testTask1 = new Task__c(Exercise__c = testExc.id, Sequence__c = 1, Body__c = 'Test Task 1', Status__c = 'Active');
        Task__c testTask2 = new Task__c(Exercise__c = testExc.id, Sequence__c = 2, Body__c = 'Test Task 2', Status__c = 'Active');
        listOfTask.add(testTask1);
        listOfTask.add(testTask2);
        Database.insert(listOfTask);
        
        //some test steps 
        Step__c testStep1 = new Step__c( Task__c = testTask1.id, Body__c = 'test step 1', Sequence__c = 1, VideoID__c = 'testId', Description__c = 'some test description');
        Step__c testStep2 = new Step__c( Task__c = testTask1.id, Body__c = 'test step 2', Sequence__c = 2, VideoID__c = 'testId2', Description__c = 'some test description2');
        listOfStep.add(testStep1);
        listOfStep.add(testStep2);
        Database.insert(listOfStep);
        
        test.startTest();
            //set the current page
            PageReference landingPage = new PageReference('/apex/eLearningLandingPage?id='+testExc.id);
            test.setCurrentPage(landingPage);
            
            //initializing the controller
            ElearningLandingController ctrl = new ElearningLandingController();
            
            //calling the method to retrieve all the exercise
            //ctrl.getExercise();
            
            //this will set the current task to be the one with sequence 1
            System.assert(ctrl.currentTask.id ==  testTask1.id);
            
            //lets change the step
            ctrl.changeToNextStep();
            
            //this will change the current step to one with sequence 2
            System.assert(ctrl.currentStep.id == testStep2.id);
            
            //lets change the task
            ctrl.changeToNextTask();
            
            //this will change the current task to one with sequence 2
            System.assert(ctrl.currentTask.id == testTask2.id);
            
        test.stopTest();
        
        
    }
    
    
}