/*
    Change Log:
    1. @sfdcdev11981 11 July, 2013  Replace the validate__c object with Reset__c object. Now reset object will hold reset details
	2. @soe July, 2013 				Added Apex code validation and reset
	3. @sfdcdev11981 19 July, 2013	Modified code by removing the Reset_Action__c child record to reset__c object. The reset action fields are now 
									available/added directly on reset__c object.
	4. @sfdcdev11981 20 July, 2013  Update both validate and reset method to support multiple validate and reset based on the new picl list field
									Validation_Logic__c and Reset_Logic__c respectiviely.
	5. @KnowledgeLover July 20, 2013 Added exception handling, code indentation and code commenting. replaced text with constants
*/
public with sharing class TaskAndStepValidator {
	
	// @sfdcdev11981  Added to support multiple validate and reset 
	// If First Serve is selected then as soon as the first one is validated successfully loop exist and shows validation message.
	// If Unanimous is selected then we expect all validation to pass. If one fails, exit loop and show failure message.
	private static String LOGIC_FIRST_SERVE = 'First Serve';
	private static String LOGIC_UNANIMOUS = 'Unanimous';
	private static final String TYPE_SOQL = 'SOQL';
	private static final String TYPE_METADATA = 'Metadata';
    private static final String TYPE_APEX = 'Inline Apex';
    private static final String TYPE_APEXCLASS = 'Lookup Class';
    private static final String MESSAGE_INFORMATION = 'Informational';
    private static final String MESSAGE_ERROR = 'Error';
    
    //~Usage: method to validate step or task
    public static ErrorsWrapper validateTaskorStep(String vId,boolean isTask){
        // @sfdcdev11981  Updated the query string to support only validate__c object.
        String query = 'Select Id, Name, Body__c, Class__c, Sequence__c, NonValidation__c, Validation__c, Type__c, Validation_Logic__c from Validate__c where ';
        
        if(isTask){
            query += 'Task__c = \''+String.escapeSingleQuotes(vId)+'\'';
        }else{
            query += 'Step__c = \''+String.escapeSingleQuotes(vId)+'\'';
        }               
		
		try{                        
        	List<Validate__c> validations = Database.query(query);
        
	        ErrorsWrapper msgWrapper = null;
	        for(Validate__c v : validations) {
	        	boolean validateResult ;
	            if(v.Type__c == TYPE_SOQL){
	                validateResult = SOQLValidator.validationSOQL(v.Validation__c);

	                if(v.NonValidation__c)
	                    validateResult = !validateResult;
	                    
	                msgWrapper = getValidateMessages(validateResult,v.Id);
	                
	            }else if(v.Type__c == TYPE_METADATA){
	                String asyncId  = MetadataValidator.validateMetadataREAD(v.Validation__c);
	                validateResult  = MetadataValidator.checkAsyncRequest(asyncId,'READ');
	                
	                while(validateResult == null){
	                    validateResult = MetadataValidator.checkAsyncRequest(asyncId,'READ');
	                }
	                
	                msgWrapper = getValidateMessages(validateResult,v.Id);
	                
	            }else if(v.Type__c == TYPE_APEX || v.Type__c == TYPE_APEXCLASS){
	                // execute anonymous via proxy heorku service	                
	                ApexService.ExecuteAnonymousResult result = ApexService.executeAnonymousProxy(v.Validation__c, UserInfo.getSessionId());
	                
                    /*
	                List<String> msges = new List<String>();
	                msges.add(result.exceptionMessage);
	                msges.add(result.compileProblem);
	                
	                validateResult = result.success;
	                msgWrapper = new ErrorsWrapper(result.success, msges);
					*/
                    
                    msgWrapper = getValidateMessages(result.success, v.Id);
	            }
	            
	            system.debug('------------- validate '+ v);
	            system.debug('------------- validateResult '+ validateResult);
	            
	            // If First Serve is selected then as soon as the first one is validated successfully exit from loop and shows validation message.
	            if(v.Validation_Logic__c == LOGIC_FIRST_SERVE && validateResult) {
	            	return msgWrapper;
	            }
				// If Unanimous is selected then we expect all validation to pass. If one fails, exit loop and show failure message.
	            else if(v.Validation_Logic__c == LOGIC_UNANIMOUS && !validateResult) {
	            	return msgWrapper;  
	        	}        
	        }
	        return msgWrapper;
	        
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, ex.getMessage()));
			return new ErrorsWrapper(false, new List<String>{ex.getMessage()});
		}           
        
        return null;
    }
    
    /*
    	@sfdcdev11981 Update the method return type to ErrorsWrapper. 
    */
    public static ErrorsWrapper resetTaskOrStep(String vId,boolean isTask) {
        
        // @sfdcdev11981  Updated the query string and below code to support Reset__c object.
    	// Removed the reset action child record to reset object. Related fields are added directly on reset object.
        String query = 'Select Id, Name, Body__c, Class__c, Sequence__c, Reset_Body__c, Reset_Type__c, Action__c,'+
        				' Metadata_Type__c, Reset_JSON__c, Reset_Logic__c from Reset__c where ';
        
        if(isTask){
            query += 'Task__c = \''+String.escapeSingleQuotes(vId)+'\'';
        }else{
            query += 'Step__c = \''+String.escapeSingleQuotes(vId)+'\'';
        }
        
        try{
	        //get reset details
	        List<Reset__c> resets = Database.query(query);
	        ErrorsWrapper msgWrapper;
	        
	        for(Reset__c r: resets){
	        	boolean resetSuccess;
	            if(r.Reset_Type__c == TYPE_SOQL) {
	            	
	                resetSuccess = SOQLValidator.validationSOQL(r.Reset_Body__c);
	                
	                msgWrapper = getResetMessages(resetSuccess, r.Id);
	                
	            } else if(r.Reset_Type__c == TYPE_METADATA && r.Action__c != null && r.Metadata_Type__c != null && r.Reset_JSON__c != null) {
	                String asyncId = MetadataValidator.validateMetadataDML(r.Action__c,r.Metadata_Type__c,r.Reset_JSON__c);
	                resetSuccess = MetadataValidator.checkAsyncRequest(asyncId,r.Action__c);
	                
	                while(resetSuccess == null){
	                    resetSuccess = MetadataValidator.checkAsyncRequest(asyncId,r.Action__c);
	                }
	                msgWrapper = getResetMessages(resetSuccess, r.Id);
	                
	            } else if(r.Reset_Type__c == TYPE_APEX || r.Reset_Type__c == TYPE_APEXCLASS){
	                String asyncId = String.valueOf(Datetime.now().getTime() + Math.random());
	                
	                ApexService.ExecuteAnonymousResult result = ApexService.executeAnonymousProxy(r.Reset_Body__c, UserInfo.getSessionId());

                    msgWrapper = getResetMessages(result.success, r.Id);
	            }
	            
	            // If First Serve is selected then as soon as the first one is reset successfully exit from loop and shows reset message.
	            if(r.Reset_Logic__c == LOGIC_FIRST_SERVE && resetSuccess) {
	            	 return msgWrapper;
	            }
				// If Unanimous is selected then we expect all reset to pass. If one fails, exit loop and show failure message.
	            else if(r.Reset_Logic__c == LOGIC_UNANIMOUS && !resetSuccess) { return msgWrapper; }  
	        }
	        
	        return msgWrapper;
	    }catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, ex.getMessage()));
			return new ErrorsWrapper(false, new List<String>{ex.getMessage()});
		}  
        return null;            
    }
    
    //~Usage: method to generate success or failure messages
    private static ErrorsWrapper getValidateMessages(boolean result, String vid){
            ErrorsWrapper errorOrSuccess;
            if(result){
                List<String> successes = new List<String>();
                errorOrSuccess = new ErrorsWrapper(true,null);
                for(Message__c m : [Select Id, Body__c from Message__c where Validate__c = :vid AND Type__c = :MESSAGE_INFORMATION]){
                    successes.add(m.Body__c);
                }
                //SPR - 6/28/13 - Changed to fix multi-step bug
                //errorOrSuccess = new ErrorsWrapper(false,successes);
                errorOrSuccess = new ErrorsWrapper(true,successes);
                
                return errorOrSuccess;
            }else{
                List<String> errors = new List<String>();
                for(Message__c m : [Select Id, Body__c from Message__c where Validate__c = :vid AND Type__c = :MESSAGE_ERROR]){
                    errors.add(m.Body__c);
                }
                errorOrSuccess = new ErrorsWrapper(false,errors);
                return errorOrSuccess;
            }
            
           return errorOrSuccess;   
    }
    
    //@sfdcdev11981  Method to generate success or failure messages for reset
    private static ErrorsWrapper getResetMessages(boolean result, String resetId){
            ErrorsWrapper errorOrSuccess;
            if(result){
                List<String> successes = new List<String>();
                errorOrSuccess = new ErrorsWrapper(true,null);
                for(Message__c m : [Select Id, Body__c from Message__c where Reset__c = :resetId AND Type__c = :MESSAGE_INFORMATION]){
                    successes.add(m.Body__c);
                }
                errorOrSuccess = new ErrorsWrapper(true,successes);
                return errorOrSuccess;
            }else{
                List<String> errors = new List<String>();
                for(Message__c m : [Select Id, Body__c from Message__c where Reset__c = :resetId AND Type__c = :MESSAGE_ERROR]){
                    errors.add(m.Body__c);
                }
                errorOrSuccess = new ErrorsWrapper(false,errors);
                return errorOrSuccess;
            }
            
           return errorOrSuccess;   
    }
    
    //Wrapper class for success or failure messages
    public class ErrorsWrapper {
        public boolean isSuccess {get;set;}
        public List<String> messages {get;set;}
        
        //constructor
        public  ErrorsWrapper(boolean success, List<String> msgs){
            isSuccess = success;
            
            if(msgs != null && msgs.size() > 0)
                messages = msgs;
            else
                messages = new List<String>();
        }
    }
}