public class validationClass_SampleC implements validationClass{

    public static List<String> params() {
        return new List<String>{
            'param1: this is ...',
            'param2: this is ...',
            'param3: this is ...',
            'param4: this is ...'
    	};
	}
    
    public static Boolean validate(List<String> params) {
    	 
    	return false;
    }
    
}