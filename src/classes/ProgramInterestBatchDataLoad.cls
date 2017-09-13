public class ProgramInterestBatchDataLoad {
/*******************************************
 * Create Date: 8/25/17
 * Author:  Cary Archiere
 * Purpose: Job is called from JLCL Program Interest Import - creates Product Interest records.
 * Revisions: 
*/ 

    //constants
    private static final String IMPORT_QUERY = 'SELECT Contact_Email__c,Download_Date__c, Id,Import_Description__c, Import_Status__c,Override__c,Program_Name__c, Batch_Number__c FROM JLCL_Program_Data_Import__c';
    private static final String IMPORT_STATUS_BAD = 'Error';
    private static final String IMPORT_STATUS_GOOD = 'Success';
    private static final String IMPORT_DESC_DUP_EMAIL = 'Error: Duplicate Email';
	private static final String IMPORT_DESC_EMAIL_NOT_FOUND = 'Error: Email not found';
    private static final String IMPORT_DESC_NO_PRODUCT = 'Error: No Such Product';
    private static final String IMPORT_DESC_DUP_PI = 'Error: Duplicate Product Interest';
        
    
    //class vars
    private List<JLCL_Program_Data_Import__c> importData = new List<JLCL_Program_Data_Import__c>();
    private List<Contact> contacts = new List<Contact>();
    private List<Product2> productList = new List<Product2>();
    private Map<String,Product2> productMap = new Map<String,Product2>();
    private List<Product_Interest__c> productInterestList = new List<Product_Interest__c>();
    private Map<String,Product_Interest__c> productInterestMap = new Map<String,Product_Interest__c>();
	private Map<String,String> duplicateMap = new Map<String,String>();
	private Map<String,Contact> ContactEmailMap = new Map<String,Contact>();
    private Map<String,Product_Interest__c> productInterestInsertMap = new Map<String,Product_Interest__c>();        
    
    public integer NumberInBatch;
    
    
    //constructor - no batch number
    public ProgramInterestBatchDataLoad() {
        String queryString = IMPORT_QUERY + ' WHERE Import_Status__c =' + '\''+'Not Started' + '\'';
       	//1. Get the Import Data records
       	importData = database.query(queryString);
		if (init()) {
            processBatch(); 
        }
    }
    
    //constructor - with batch number
    public ProgramInterestBatchDataLoad(Integer batchNum) {
       String queryString = IMPORT_QUERY + ' WHERE Batch_Number__c = ' + batchNum + ' AND Import_Status__c =' + '\''+'Not Started' + '\'';
       
        //1. Get the Import Data records
       importData = database.query(queryString);  
        if (init()) {
            processBatch();
        }
    }
    
   	//init method to initialize data maps and lists
    private Boolean init() {
    	// vars
        List<String> listEMail = new List<String>();
        
		//Only continue if there are records
        this.NumberInBatch = importData.size();
        if (this.NumberInBatch == 0) {
           return false; 
        } 
		
        //2. Get all contacts by email addresses in the import data
        // Build a list of all of the email addresses from the importData query
        for (JLCL_Program_Data_Import__c rec:importData) {
            listEmail.add(rec.Contact_Email__c);
        }
        
        contacts = ([SELECT ID, LastName, Email FROM Contact WHERE Email in :listEmail]);
        system.debug ('Number of Contacts:' + contacts.size());
        //3. Build a map of all existing product interest records for the contacts
        productInterestList = ([Select MergeId__c from Product_Interest__c Where Contact__c in :contacts]);
        for (Product_Interest__c prodInt:productInterestList) {
            productInterestMap.put(prodInt.MergeId__c,prodInt);
        }
		productInterestList.clear();
        // 4. Build a product map by name
        productList = ([Select Id, Name FROM Product2 WHERE Family = 'JLCL Program' AND IsActive = true]);
        for (Product2 prod:productList) {
            productMap.put(prod.Name,prod);
        } 
        
        // 5. Build a duplicate map and contact map using contact list
        for (Contact con:contacts) {
            // check if the contact email address is in the duplicate map.
            String dupEMail = duplicateMap.get(con.Email);
            Contact dupContact = contactEmailMap.get(con.Email);
            if (dupEmail == null && dupContact == null) {
            	contactEmailMap.put(con.Email,con);    
            } else {
                duplicateMap.put(con.Email,con.Email);
                contactEmailMap.remove(con.Email);
            }
            
        } // end for loop of contacts
        
        
        
        // init completed - return true
        return true;

    } // End Init
    
    private void processBatch() {
        // process the records in the batchData list
        for (JLCL_Program_Data_Import__c rec:importData) {
            system.debug('Inside Loop: ' + rec);
            Boolean importError = false;
            String importErrorMsg;
            
            // if the email is in the dup record, update the error else add to batchupsert
            if (duplicateMap.get(rec.Contact_Email__c) != null) {
                system.debug('Duplicate found:' + rec.Contact_Email__c);
                importError = true;
                importErrorMsg = IMPORT_DESC_DUP_EMAIL;
            } 
            // if the email address is not found on a contact, update error
            if (!importError && contactEmailMap.get(rec.Contact_Email__c) == null) {
                system.debug('Email Not Found:' + rec.Contact_Email__c);
                importError = true;
                importErrorMsg = IMPORT_DESC_EMAIL_NOT_FOUND;                
            }
            // if the product is not found
            if (!importError && productMap.get(rec.Program_Name__c) == null) {
                system.debug('Product Not Found:' + rec.Contact_Email__c);
                importError = true;
                importErrorMsg = IMPORT_DESC_NO_PRODUCT;                 
            }
            // if the product interest record already exists and the batch record has no override
            if (!importError ) {
                // create the to-be merge id
            	String mergeId = String.ValueOf(productMap.get(rec.Program_Name__c).Id) + String.ValueOf(contactEmailMap.get(rec.Contact_Email__c).Id);

                if (productInterestMap.get(mergeId) != null && rec.Override__c != true) {
                    importError = true;
                    importErrorMsg = IMPORT_DESC_DUP_PI;
                }
            }
            
            if (importError) {
            	rec.Import_Status__c = IMPORT_STATUS_BAD;
                rec.Import_Description__c = importErrorMsg;
            } else {
                // create the to-be merge id
            	String mergeId = String.ValueOf(productMap.get(rec.Program_Name__c).Id) + String.ValueOf(contactEmailMap.get(rec.Contact_Email__c).Id);

                rec.Import_Status__c = IMPORT_STATUS_GOOD;
                // look at the existing records to be inserted in this batch.  If this record is already in the map, do not add it
                Product_Interest__c piInList = productInterestInsertMap.get(mergeId);
                if (piInList == null) {
                	Date dt = rec.Download_Date__c;
                	Date insertDate = date.newInstance(dt.year(), dt.month(), dt.day());
            		Product_Interest__c pi = new Product_Interest__c();
                	pi.Contact__c = contactEmailMap.get(rec.Contact_Email__c).Id;
                	pi.Product__c = productMap.get(rec.Program_Name__c).Id;
                	pi.Download_Date__c= insertDate;
                	pi.MergeId__c = mergeId;
                	productInterestList.add(pi); 
                    productInterestInsertMap.put(mergeId,pi);
                }

            }	
                
            system.debug ('Record at end of loop' + rec);
            
        } // end for each importData record
        try {
            for (Product_Interest__c p:productInterestList) {
                system.debug('Product Interest: ' + p);
            }
           upsert productInterestList MergeId__c; 
           update importData;
        } catch (DmlException e) {
            system.debug('ERROR ' + e.getMessage());
            for (JLCL_Program_Data_Import__c rec:importData) {
                rec.Import_Status__c = IMPORT_STATUS_BAD;
                rec.Import_Description__c = e.getMessage().left(255);
            }
            update importData;
        }        
       
        
    }  // end proceessBatch
    
    
 
}