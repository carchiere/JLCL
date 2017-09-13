@isTest
public class TestDataFactory {
    // create test accounts
    public static List<Account> testCreateAccounts(Integer numAccts) {
        List<Account> accts = new List<Account>();
        
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account(Name='TestAccount' + i);
            accts.add(a);
        }
        insert accts;
        return accts;
    }
    
    public static List<Contact> testCreateContacts(List<Account> accts, Integer numContactsPerAcct) {
        // create test contacts
        List<Contact> cons = new List<Contact>();
        for (Integer j=0;j<accts.size();j++) { 
            Account acct = accts[j]; 
            // For each account,  add contacts
            for (Integer k=numContactsPerAcct*j;k<numContactsPerAcct*(j+1);k++) {
               
                cons.add(new Contact(firstname='Test'+k,
                                     lastname='Test'+k,
                                     email = 'email'+ k + '@example' + k + '.com',
                                     AccountId=acct.Id));
            }
        }
        // Insert all contacts for all accounts
        insert cons;
        return cons;
        
        
    }
    public static List<Product2> createProductData() {
        List<Product2> prodList = new List<Product2>();
        prodList.add(new Product2(Name = 'Eight Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Fifth Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'First Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Fourth Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'High School JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Pre K and K', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Second Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Seventh Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Sixth Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        prodList.add(new Product2(Name = 'Third Grade JLCL Pilot', Family ='JLCL Program', IsActive = true));
        
        insert prodList;
        return prodList;
    }

}