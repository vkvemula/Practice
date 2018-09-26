// author: soe@soe.im
public class ElearningExercisesController {

    // constructor
    public ElearningExercisesController() {}
    
    public String getPageHeader() {
        return 'ExerciseListings';
    }
    
    public List<Exercise__c> getExercises() {
        List<Exercise__c> exercises = [SELECT Id, Name, Body__c, Summary__c, Status__c, Sequence__c, ActiveTasks__c FROM Exercise__c ORDER BY Status__c ASC, Sequence__c ASC];
        
        return exercises;
    }
    
    @isTest
    public static void ElearningExercisesControllerTest() {
    
        test.startTest();
        
        ElearningExercisesController cont = new ElearningExercisesController();
        cont.getPageHeader();
        
        Exercise__c e1 = new Exercise__c(Body__c = 'body', Sequence__c = 1, Status__c = 'Active');
        Insert e1;
        Exercise__c e2 = new Exercise__c(Body__c = 'body', Sequence__c = 2, Status__c = 'Inactive');
        Insert e2;
        Exercise__c e3 = new Exercise__c(Body__c = 'body', Sequence__c = 3, Status__c = 'Active');
        Insert e3;

        
        List<Exercise__c> exercises = cont.getExercises();

        System.assertEquals(exercises[0].Id, e1.Id);
        System.assertEquals(exercises[1].Id, e3.Id);
        System.assertEquals(exercises[2].Id, e2.Id);
        test.stopTest();
    }
}