@isTest
public class TempLeadTrigger_Test {
    @IsTest
    public static void createNewLead(){
        //Create park
        Adventure_Park__c park = new Adventure_Park__c(Name = 'The Craggy Cliffs');
        park.Park_Number__c = '123456789012';
        insert park;
        //Create TempLead record
        Temp_Lead__c ld= new Temp_Lead__c();
        ld.Park_Number__c = '123456789012';
        ld.Estimated_Household_Income__c = '$ 50,000 - 74,999';
        ld.Lead_City__c = '';
        ld.Lead_Country_Code__c = 'US';
        ld.Lead_Email__c = 'holly.hopeful@test.com';
        ld.Lead_First_Name__c = 'Holly';
        ld.Lead_Last_Name__c = 'Hopeful';
        DateTime dt = System.today()+5;
        String dateStr = dt.format('dd/MM/yyyy');
        ld.Lead_Adventure_Date__c = dateStr;
        ld.Lead_Phone_Number__c = '6233322459';
        ld.Lead_Postal_Code__c= '85310';
        ld.Lead_Rating__c = 'Hot';
        ld.Lead_Source__c = 'DOG';
        ld.Lead_State__c = '';
        ld.Lead_Street_Address__c='';
        ld.Vendor_Segment_Id__c='111';
        ld.Is_Agent__c = true;
        insert ld;
        Map<Id, Temp_Lead__c> ls = new Map<Id, Temp_Lead__c>();
        ls.put(ld.Id, ld);

        Test.startTest();
        TempLeadTrigger_Handler.onAfterInsert(ls);
        //Assertion to check Lead updated value
        Lead l = [SELECT id, Household_Income__c  FROM Lead WHERE LastName =:ld.Lead_Last_Name__c AND email =:ld.Lead_Email__c];
        system.assertEquals('$65K-99K', l.Household_Income__c );
        Test.stopTest();
    }

    @isTest
    public static void updateContact(){
        //Create Account
        Account acc = new Account(Name = 'Account');
        insert acc;
        //Create Contact
        Contact con = new Contact(
            FirstName = 'Contact',
            AccountId = acc.Id
        );
        con.Email = 'holly.hopeful@test.com';
        con.LastName = 'Hopeful';
        insert con;
        //Create park
        Adventure_Park__c park = new Adventure_Park__c(Name = 'The Slippery Slopes');
        park.Park_Number__c = '123456789012';
        insert park;
        //Create Opportunity record
        //todo: create opportunity
        List<Opportunity> oppList = new List<Opportunity>();

        //Create TempLead record
        Temp_Lead__c ld= new Temp_Lead__c();
        ld.Park_Number__c = '123456789012';
        ld.Estimated_Household_Income__c = '$ 50,000 - 0';
        ld.Lead_City__c = '';
        ld.Lead_Country_Code__c = 'US';
        ld.Lead_Email__c = 'holly.hopeful@test.com';
        ld.Lead_First_Name__c = 'Holly';
        ld.Lead_Last_Name__c = 'Hopeful';
        DateTime dt = System.today()+120;
        String dateStr = dt.format('dd/MM/yyyy');
        ld.Lead_Adventure_Date__c = dateStr;
        ld.Lead_Phone_Number__c = '6233322459';
        ld.Lead_Postal_Code__c= '85310';
        ld.Lead_Rating__c = 'Hot';
        ld.Lead_Source__c = 'DOG';
        ld.Lead_State__c = '';
        ld.Lead_Street_Address__c='';
        ld.Vendor_Segment_Id__c='111';
        insert ld;

        Map<Id, Temp_Lead__c> ls = new Map<Id, Temp_Lead__c>();
        ls.put(ld.Id, ld);

        Test.startTest();
        TempLeadTrigger_Handler.onAfterInsert(ls);
        //Assertion to check Contact updated value
        Contact cc = [SELECT id, Vendor_Segment_Id__c FROM Contact WHERE Id =:con.Id];
        system.assertEquals(ld.Vendor_Segment_Id__c, cc.Vendor_Segment_Id__c);
        Test.stopTest();
    }

    @isTest
    public static void sameLeadIssue(){
        //Create park
        Adventure_Park__c park = new Adventure_Park__c(Name = 'The Sinking Sands');
        park.Park_Number__c = '123456789012';
        insert park;
        //Create Lead
        Lead l = new Lead();
        l.Email = 'holly.hopeful@test.com';
        l.LastName = 'Hopeful';
        l.firstName = 'Holly';
        l.Company = 'Unaffiliated';
        insert l;
        Lead l1 = new Lead();
        l1.Email = 'holly.hopeful@test.com';
        l1.LastName = 'Hopeful';
        l1.firstName = 'Holly1';
        l1.Company = 'Unaffiliated';
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(l1, dml);

        //Create TempLead record
        Temp_Lead__c ld= new Temp_Lead__c();
        ld.Park_Number__c = '123456789012';
        ld.Estimated_Household_Income__c = '$ 50,000 - 0';
        ld.Lead_City__c = '';
        ld.Lead_Country_Code__c = 'US';
        ld.Lead_Email__c = 'holly.hopeful@test.com';
        ld.Lead_First_Name__c = 'Holly';
        ld.Lead_Last_Name__c = 'Hopeful';
        DateTime dt = System.today()+120;
        String dateStr = dt.format('dd/MM/yyyy');
        ld.Lead_Adventure_Date__c = dateStr;
        ld.Lead_Phone_Number__c = '6233322459';
        ld.Lead_Postal_Code__c= '85310';
        ld.Lead_Rating__c = 'Hot';
        ld.Lead_Source__c = 'DOG';
        ld.Lead_State__c = '';
        ld.Lead_Street_Address__c='';
        ld.Vendor_Segment_Id__c='111';
        insert ld;
        Map<Id, Temp_Lead__c> ls = new Map<Id, Temp_Lead__c>();
        ls.put(ld.Id, ld);

        Test.startTest();
        TempLeadTrigger_Handler.onAfterInsert(ls);
        //Assertion to check Contact updated value
        Lead cc = [SELECT id, Vendor_Segment_Id__c FROM lead WHERE Id =:l.Id];
        system.assertEquals(ld.Vendor_Segment_Id__c, cc.Vendor_Segment_Id__c);
        Lead cc1 = [SELECT id, firstname FROM lead WHERE Id =:l1.Id];
        system.assertEquals('Holly1', cc1.firstname);
        Test.stopTest();
    }
    @isTest
    public static void sameContactIssue(){
        //Create park
        Adventure_Park__c park = new Adventure_Park__c(Name = 'The Pesky Peaks');
        park.Park_Number__c = '123456789012';
        insert park;
        //Create Account
        Account acc = new Account(Name = 'Account 1');
        Account acc1 = new Account(Name = 'Account 2');
        insert new List<Account>{acc, acc1};
        //Create Contact
        Contact con = new Contact();
        con.Email = 'holly.hopeful@test.com';
        con.LastName = 'Hopeful';
        con.firstName = 'Holly';
        con.accountId = acc.Id;
        insert con;

        Contact con1 = new Contact();
        con1.Email = 'holly.hopeful@test.com';
        con1.LastName = 'Hopeful';
        con1.firstName = 'Holly1';
        con1.AccountId = acc1.Id;
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(con1, dml);

        //Create TempLead record
        Temp_Lead__c ld= new Temp_Lead__c();
        ld.Park_Number__c = '123456789012';
        ld.Estimated_Household_Income__c = '$ 50,000 - 0';
        ld.Lead_City__c = '';
        ld.Lead_Country_Code__c = 'US';
        ld.Lead_Email__c = 'holly.hopeful@test.com';
        ld.Lead_First_Name__c = 'Holly';
        ld.Lead_Last_Name__c = 'Hopeful';
        DateTime dt = System.today()+120;
        String dateStr = dt.format('dd/MM/yyyy');
        ld.Lead_Adventure_Date__c = dateStr;
        ld.Lead_Phone_Number__c = '6233322459';
        ld.Lead_Postal_Code__c= '85310';
        ld.Lead_Rating__c = 'Hot';
        ld.Lead_Source__c = 'DOG';
        ld.Lead_State__c = '';
        ld.Lead_Street_Address__c='';
        ld.Vendor_Segment_Id__c='111';
        insert ld;
        Map<Id, Temp_Lead__c> ls = new Map<Id, Temp_Lead__c>();
        ls.put(ld.Id, ld);

        Test.startTest();
        TempLeadTrigger_Handler.onAfterInsert(ls);
        //Assertion to check Contact updated value
        Contact cc = [SELECT id, Vendor_Segment_Id__c FROM Contact WHERE Id =:con.Id];
        system.assertEquals(ld.Vendor_Segment_Id__c, cc.Vendor_Segment_Id__c);
        Contact cc1 = [SELECT id, firstname FROM Contact WHERE Id =:con1.Id];
        system.assertEquals('Holly1', cc1.firstname);
        Test.stopTest();
    }
    @isTest
    public static void sameLeadandContactIssue(){
        //Create park
        Adventure_Park__c park = new Adventure_Park__c(Name = 'The Icy Glaciers');
        park.Park_Number__c = '123456789012';
        insert park;
        //Create Account
        Account acc = new Account(Name = 'Account');
        insert acc;
        //Create Contact
        Contact con = new Contact(AccountId = acc.Id);
        con.Email = 'holly.hopeful@test.com';
        con.LastName = 'Hopeful';
        con.firstName = 'Holly';
        insert con;

        Lead l1 = new Lead();
        l1.Email = 'holly.hopeful@test.com';
        l1.LastName = 'Hopeful';
        l1.firstName = 'Holly1';
        l1.Company = 'Unaffiliated';
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(l1, dml);

        //Create TempLead record
        Temp_Lead__c ld= new Temp_Lead__c();
        ld.Park_Number__c = '123456789012';
        ld.Estimated_Household_Income__c = '$ 50,000 - 0';
        ld.Lead_City__c = '';
        ld.Lead_Country_Code__c = 'US';
        ld.Lead_Email__c = 'holly.hopeful@test.com';
        ld.Lead_First_Name__c = 'Holly';
        ld.Lead_Last_Name__c = 'Hopeful';
        DateTime dt = System.today()+120;
        String dateStr = dt.format('dd/MM/yyyy');
        ld.Lead_Adventure_Date__c = dateStr;
        ld.Lead_Phone_Number__c = '6233322459';
        ld.Lead_Postal_Code__c= '85310';
        ld.Lead_Rating__c = 'Hot';
        ld.Lead_Source__c = 'DOG';
        ld.Lead_State__c = '';
        ld.Lead_Street_Address__c='';
        ld.Vendor_Segment_Id__c='111';
        insert ld;
        Map<Id, Temp_Lead__c> ls = new Map<Id, Temp_Lead__c>();
        ls.put(ld.Id, ld);

        Test.startTest();
        TempLeadTrigger_Handler.onAfterInsert(ls);
        //Assertion to check Contact updated value
        Contact cc = [SELECT id, Vendor_Segment_Id__c FROM Contact WHERE Id =:con.Id];
        system.assertEquals(ld.Vendor_Segment_Id__c, cc.Vendor_Segment_Id__c);
        Lead cc1 = [SELECT id, firstname FROM lead WHERE Id =:l1.Id];
        system.assertEquals('Holly1', cc1.firstname);
        Test.stopTest();
    }
}
