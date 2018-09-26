/*
    author: Soe <soe@soe.im>
    
    this is a very basic test coverage - no functional testing as not needed
*/
@isTest  
private class ApexServiceTest 
{    

  private class WebServiceMockImpl implements WebServiceMock 
  {
    public void doInvoke(
      Object stub, Object request, Map<String, Object> response,
      String endpoint, String soapAction, String requestName,
      String responseNS, String responseName, String responseType) 
    {
      if(request instanceof ApexService.wsdlToApex_element)
        response.put('response_x', new ApexService.wsdlToApexResponse_element());
      else if(request instanceof ApexService.runTests_element)
        response.put('response_x', new ApexService.runTestsResponse_element());
      else if(request instanceof ApexService.compileClasses_element)
        response.put('response_x', new ApexService.compileClassesResponse_element());
      else if(request instanceof ApexService.compileAndTest_element)
        response.put('response_x', new ApexService.compileAndTestResponse_element());
      else if(request instanceof ApexService.executeAnonymous_element)
        response.put('response_x', new ApexService.executeAnonymousResponse_element());
      else if(request instanceof ApexService.compileTriggers_element)
        response.put('response_x', new ApexService.compileTriggersResponse_element());
      return;
    }
  }    
    
    @IsTest
    private static void coverGeneratedCodeMethods() { 
        Test.startTest(); 
        // Null Web Service mock implementation
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        
        ApexService apexService = new ApexService();        
        ApexService.Apex service = new ApexService.Apex();
        service.SessionHeader = new ApexService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        //service.wsdlToApex(null);
        //service.runTests(null);
        //service.compileClasses(null);
        //service.compileAndTest(null);
        service.executeAnonymous('// just a line of comment');
        //service.compileTriggers(null);
        
        Test.stopTest();    
    }
    
    @IsTest
    private static void coverGeneratedCodeTypes() {
        new ApexService();
        new ApexService.Apex();
        new ApexService.CallOptions_element();
        new ApexService.NamespacePackagePair();
        new ApexService.CodeLocation();
        new ApexService.CodeCoverageWarning();
        new ApexService.RunTestFailure();
        new ApexService.SessionHeader_element();
        new ApexService.runTests_element();
        new ApexService.CompileClassResult();
        new ApexService.compileClassesResponse_element();
        new ApexService.AllOrNoneHeader_element();
        new ApexService.compileClasses_element();
        new ApexService.wsdlToApexResponse_element();
        new ApexService.RunTestSuccess();
        
        new ApexService.CodeCoverageResult();
        new ApexService.executeAnonymous_element();
        new ApexService.RunTestsRequest();
        new ApexService.CompileAndTestRequest();
        new ApexService.DebuggingInfo_element();
        new ApexService.CompileAndTestResult();
        new ApexService.WsdlToApexResult();
        new ApexService.compileTriggersResponse_element();
        new ApexService.CompileTriggerResult();
        
        new ApexService.AllowFieldTruncationHeader_element();
        new ApexService.PackageVersion();
        new ApexService.DeleteApexResult();
        new ApexService.ExecuteAnonymousResult();
        new ApexService.compileAndTest_element();
        new ApexService.wsdlToApex_element();
        new ApexService.DisableFeedTrackingHeader_element();
        new ApexService.LogInfo();
        new ApexService.compileTriggers_element();
        
        new ApexService.DebuggingHeader_element();
        new ApexService.executeAnonymousResponse_element();
        new ApexService.RunTestsResult();
        new ApexService.PackageVersionHeader_element();
        new ApexService.runTestsResponse_element();
        new ApexService.compileAndTestResponse_element();
        new ApexService.WsdlToApexInfo();        
    
    }
 
}