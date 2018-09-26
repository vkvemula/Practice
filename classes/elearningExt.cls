public with sharing class elearningExt {

    public list<task__c> tasks {get; private set;}
    public list<Step__c> steps {get; private set;}

    public elearningExt(ApexPages.StandardController controller) {
        Id eId = controller.getId();
        tasks = [SELECT ID, Body__c, Sequence__c, Status__c, Exercise__c FROM task__c WHERE Exercise__c = :eId];
        steps = [SELECT ID, Body__c, Task__c, Sequence__c FROM Step__C WHERE task__c in: tasks ORDER BY Task__c, Sequence__c desc];
    }

}