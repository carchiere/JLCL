@isTest
private class TestScheduledJLCLProgramImportBatch {
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    static testmethod void testScheduledJob() {
        List<JLCL_Program_Data_Import__c> recList = 
            new List<JLCL_Program_Data_Import__c>();
        JLCL_Program_Data_Import__c rec = 
            new JLCL_Program_Data_Import__c(Import_Status__c = 'Error',Contact_Email__c ='test@test.com',Download_Date__c = Date.today(),Program_Name__c = 'Test');
        	insert rec;
        
   
    test.startTest();
     String jobId = System.schedule('ScheduledApexTest',
            CRON_EXP, 
     new ScheduledJLCLProgramImportBatch());
        System.assertEquals(rec.Import_Status__c, 'Error');
     test.stopTest();
     
     JLCL_Program_Data_Import__c newRec = [Select Id, Import_Status__c, Import_Description__c
                                           FROM JLCL_Program_Data_Import__c where Id = :rec.Id];
     System.assertEquals(newRec.Import_Status__c, 'Error');
     System.assertEquals(newRec.Import_Description__c, 'Error: Email not found');
        
        
                                    
 }
}