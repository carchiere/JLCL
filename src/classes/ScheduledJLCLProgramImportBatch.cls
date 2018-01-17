global class ScheduledJLCLProgramImportBatch implements Schedulable {
	
    global void execute(SchedulableContext ctx) {
    	
        List<JLCL_Program_Data_Import__c> impRecs = 
             [SELECT Id, Import_Status__c, Import_Description__c
              FROM JLCL_Program_Data_Import__c
              WHERE Import_Status__c = 'Error'];
        for (JLCL_Program_Data_Import__c rec:impRecs) {
            rec.Import_Status__c = 'Not Started';
            rec.Import_Description__c = '';
        }
        update impRecs;
        ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad();
        
    }
}