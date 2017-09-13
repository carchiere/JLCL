@isTest
public class testProgramInterestBatchDataLoad {
/*******************************************
 * Create Date: 8/25/17
 * Author:  Cary Archiere
 * Purpose: Test Class for ProgramInterestBatchDataLoad class
 * Revisions: 
*/
    
    static List<Account> accts = new List<Account>();
    static List<Product2> products = new List<Product2>();
    
    static void testProgramInterestDataPrep(){
        accts = TestDataFactory.testCreateAccounts(1);
        products = TestDataFactory.createProductData();
    }  // data prep
    
    // test 1:  No records to process
    static void runTest1(){
       ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad();
       system.assertEquals(0,job.NumberInBatch, 'Test 1: Expecting zero records processed.');
    }  // end test 1
    
    
    //test 2: duplicate email addresses
    static void runTest2() {
        List<Contact> contacts = new List<Contact>();
        List<JLCL_Program_Data_Import__c> batchData = new List<JLCL_Program_Data_Import__c>();
        contacts.add(new Contact(FirstName = 'Test2-1', LastName = 'Test2-1',npe01__WorkEmail__c ='test2@test2.com', npe01__Preferred_Email__c = 'Work',AccountId=accts[0].Id));
		contacts.add(new Contact(FirstName = 'Test2-2', LastName = 'Test2-2',npe01__WorkEmail__c ='test2@test2.com', npe01__Preferred_Email__c = 'Work',AccountId=accts[0].Id));
		
        batchData.add(new JLCL_Program_Data_Import__c(Batch_Number__c = 2,Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = 'Pre K and K',Contact_Email__c = 'test2@test2.com') );
    	
        //add second batch data w/ no batch number to ensure it's not processed in this test
        batchData.add(new JLCL_Program_Data_Import__c(Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = 'Pre K and K',Contact_Email__c = 'doesntmatter@test2.com') );

        insert contacts;
        insert batchData;
        ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad(2);
        //assert only one record processed
        system.assertEquals(1,job.NumberInBatch, 'Test 2: Expecting 1 records processed.');
        batchData.clear();
        batchData = ([Select Import_Status__c, Import_Description__c FROM JLCL_Program_Data_Import__c WHERE Batch_Number__c = 2]);
        system.assertEquals(1,batchData.size(), 'Test 2: Expecting 1 returned record');
        system.assertEquals('Error', batchData[0].Import_Status__c, 'Test2: Expecting Status = Error');
        system.assertEquals('Error: Duplicate Email', batchData[0].Import_Description__c, 'Test 2: Expecting Error Message');
    	// remove unused batchData record
    	batchData.clear();
        batchData = ([Select Import_Status__c, Import_Description__c FROM JLCL_Program_Data_Import__c]);
        
        delete batchData;
    } // end test 2
    
    // test 3:  email in batch data is not in contact
    static void runTest3() {
    	List<JLCL_Program_Data_Import__c> batchData = new List<JLCL_Program_Data_Import__c>();
        batchData.add(new JLCL_Program_Data_Import__c(Batch_Number__c = 3,Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = 'Pre K and K',Contact_Email__c = 'NoContact@test3.com') );
        insert batchData;
        ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad(3);
        system.assertEquals(1,batchData.size(), 'Test 3: Expecting 1 returned record');
        batchData.clear();
        batchData = ([Select Import_Status__c, Import_Description__c FROM JLCL_Program_Data_Import__c WHERE Batch_Number__c = 3]);
        system.assertEquals('Error', batchData[0].Import_Status__c, 'Test3: Expecting Status = Error');
        system.assertEquals('Error: Email not found', batchData[0].Import_Description__c, 'Test 3: Expecting Error Message');
    
    } // end test 3
    
    // test 4: product not in the product list
    static void runTest4() {
	    List<Contact> contacts = new List<Contact>();
        List<JLCL_Program_Data_Import__c> batchData = new List<JLCL_Program_Data_Import__c>();
        contacts.add(new Contact(FirstName = 'Test4', LastName = 'Test4',npe01__WorkEmail__c ='test4@test4.com', npe01__Preferred_Email__c = 'Work',AccountId=accts[0].Id));
		batchData.add(new JLCL_Program_Data_Import__c(Batch_Number__c = 4, Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = 'Pre X and K',Contact_Email__c = 'test4@test4.com') );
        insert contacts;
        insert batchData;
        ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad(4);
        //assert only one record processed
        system.assertEquals(1,job.NumberInBatch, 'Test 4: Expecting 1 records processed.');
        batchData.clear();
        batchData = ([Select Import_Status__c, Import_Description__c FROM JLCL_Program_Data_Import__c WHERE Batch_Number__c = 4]);
        system.assertEquals(1,batchData.size(), 'Test 4: Expecting 1 returned record');
        system.assertEquals('Error', batchData[0].Import_Status__c, 'Test4: Expecting Status = Error');
        system.assertEquals('Error: No Such Product', batchData[0].Import_Description__c, 'Test 4: Expecting Error Message');
       
    }// end test 4
    
    //test 5: mergeid exists and override is no
    //test 5: mergeid exists and override is no and when override is yes
    static void runTest5() {
		List<Contact> contacts = new List<Contact>();
        List<JLCL_Program_Data_Import__c> batchData = new List<JLCL_Program_Data_Import__c>();
        List<Product_Interest__c> productInterestList = new List<Product_Interest__c>();
        Product2 firstProduct = products[0];
        Product2 secondProduct = products[1];
        
        contacts.add(new Contact(FirstName = 'Test5', LastName = 'Test5',npe01__WorkEmail__c ='test5@test5.com', npe01__Preferred_Email__c = 'Work',AccountId=accts[0].Id));
		insert contacts;
		String mergeId1 = String.valueOf(firstProduct.Id) + String.valueOf(contacts[0].Id);
		String mergeId2 = String.valueOf(secondProduct.Id) + String.valueOf(contacts[0].Id);
		productInterestList.add(new Product_Interest__c(MergeId__c = mergeId1, Product__c = firstProduct.Id, Contact__c =contacts[0].Id, Download_Date__c = Date.newInstance(2017, 1, 1)));
        productInterestList.add(new Product_Interest__c(MergeId__c = mergeId2, Product__c = secondProduct.Id, Contact__c = contacts[0].Id, Download_Date__c = Date.newInstance(2017, 1, 1)));
        insert productInterestList;
           
        
		batchData.add(new JLCL_Program_Data_Import__c(Batch_Number__c = 5, Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = firstProduct.Name,Contact_Email__c = 'test5@test5.com') );
        batchData.add(new JLCL_Program_Data_Import__c(Batch_Number__c = 5, Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = secondProduct.Name,Contact_Email__c = 'test5@test5.com',Override__c = true) );
        insert batchData;
       	ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad(5);
        //assert only one record processed
        system.assertEquals(2,job.NumberInBatch, 'Test 5: Expecting 2 records processed.');
        batchData.clear();
        batchData = ([Select Program_Name__c, Import_Status__c, Import_Description__c FROM JLCL_Program_Data_Import__c WHERE Batch_Number__c = 5]);
        system.assertEquals(2,batchData.size(), 'Test 5: Expecting 1 returned record');
        for (JLCL_Program_Data_Import__c rec:batchData) {
            if(rec.Program_Name__c == firstProduct.Name) {
		        system.assertEquals('Error', rec.Import_Status__c, 'Test5: Expecting Status = Error');
		        system.assertEquals('Error: Duplicate Product Interest', rec.Import_Description__c, 'Test 5: Expecting Error Message');
			}
            if (rec.Program_Name__c == secondProduct.Name) {
			     system.assertEquals('Success', rec.Import_Status__c, 'Test5: Expecting Status = Success');
            }
        }

    } // end test5
    
    // test 6 no batch 
    static void runTest6() {
		List<Contact> contacts = new List<Contact>();
        List<JLCL_Program_Data_Import__c> batchData = new List<JLCL_Program_Data_Import__c>();
        contacts.add(new Contact(FirstName = 'Test6', LastName = 'Test6',npe01__WorkEmail__c ='test6@test6.com', npe01__Preferred_Email__c = 'Work',AccountId=accts[0].Id));
		batchData.add(new JLCL_Program_Data_Import__c(Import_Status__c = 'Not Started',Download_Date__c = date.today(),Program_Name__c = 'Pre K and K',Contact_Email__c = 'test6@test6.com') );
        insert contacts;
        insert batchData;
        
       	ProgramInterestBatchDataLoad job = new ProgramInterestBatchDataLoad();
        system.assertEquals(1,job.NumberInBatch, 'Test 6: Expecting 1 records processed.');
        batchData.clear();
        batchData = ([Select Program_Name__c, Import_Status__c, Import_Description__c FROM JLCL_Program_Data_Import__c WHERE Contact_Email__c = 'test6@test6.com']);
        system.assertEquals(1,batchData.size(), 'Test 6: Expecting 1 returned record');
        system.assertEquals('Success', batchData[0].Import_Status__c, 'Test6: Expecting Status = Success');
        
    }// end test 6
    
    
    
    static testmethod void testProgramControlFuncton() {
        testProgramInterestDataPrep();
        runTest1();
        runTest2();
        runTest3();
        runTest4();
        runTest5();
        runTest6();
    }
    
}