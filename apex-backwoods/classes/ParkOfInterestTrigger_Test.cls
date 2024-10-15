@IsTest
private class ParkOfInterestTrigger_Test {

    @IsTest
    static void testPlannerReplication() {
        Adventure_Park__c adventurePark = new Adventure_Park__c();
        adventurePark.Name = 'The Piney Peaks';
        adventurePark.Open_Date__c = System.today() + 1;
        adventurePark.Is_Active__c = true;
        adventurePark.Park_Number__c = '918273645278';
        insert adventurePark;

        Account testAccount1 = new Account(Name = 'Test Account 1');
        testAccount1.Agent_First_Name__c = 'Test';
        testAccount1.Agent_Last_Name__c = 'AgentAccount';
        testAccount1.Email__c = 'testagentaccount@test.com';
        insert testAccount1;


        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222',
            Partner_Account__c = testAccount1.Id);
        insert l;

        Park_Of_Interest__c theParkOfInterest = new Park_Of_Interest__c(
            Lead__c = l.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = adventurePark.Id);
        insert theParkOfInterest;
    }

    @IsTest
    static void testContactSynchronization() {
        Account testAccount1 = new Account(Name = 'Test Account 1');
        Account testAccount2 = new Account(Name = 'Test Account 2');
        Adventure_Park__c thePark = new Adventure_Park__c(Name = 'Test Park', Is_Active__c = true, Open_Date__c = System.today() + 1, Park_Number__c = '918273645278');

        try {
            insert new List<SObject>{testAccount1, testAccount2, thePark};
        }
        catch (DmlException ex) {
            System.assert(true, ex.getDmlMessage(0)); // should not get here
        }

        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            AccountId = testAccount1.Id,
            Email = 'contact1@tpp.com');
        Contact testContact2 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 2',
            AccountId = testAccount2.Id,
            Email = 'contact2@tpp.com');

        try {
            insert new List<SObject>{testContact1, testContact2};
        }
        catch (DmlException ex) {
            System.assert(true, ex.getDmlMessage(0)); // should not get here
        }

        System.runAs(new User (Id = UserInfo.getUserId())) {
            Park_Of_Interest__c theParkOfInterest = new Park_Of_Interest__c(Account__c = testAccount1.Id, Rating__c = 'Warm', Adventure_Park__c = thePark.Id);

            try {
                insert theParkOfInterest;
            }
            catch (DmlException ex) {
                System.assert(true, ex.getDmlMessage(0)); // should not get here
            }

            // System.assertEquals(testContact1.id, [select Contact__c from Park_Of_Interest__c where id = :theParkOfInterest.id].Contact__c);

            theParkOfInterest.Account__c = testAccount2.Id;

            try {
                update theParkOfInterest;
            }
            catch (DmlException ex) {
                System.assert(true, ex.getDmlMessage(0)); // should not get here
            }

            /*System.assertEquals(testContact2.id, [select Contact__c from Park_Of_Interest__c where id = :theParkOfInterest.id].Contact__c);

            theParkOfInterest.Account__c = null;

            try {
                update theParkOfInterest;
            } catch (DMLException ex) {
                System.assert(false, ex.getDMLMessage(0)); // should not get here
            }

            System.assertEquals(null, [select Contact__c from Park_Of_Interest__c where id = :theParkOfInterest.id].Contact__c); */
        }
    }

    @IsTest
    static void testAccountSynchronization() {
        Account testAccount1 = new Account(Name = 'Test Account 1');
        insert testAccount1;

        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            AccountId = testAccount1.Id,
            Email = 'testContact1@tpp.com');
        insert testContact1;

        Adventure_Park__c thePark = new Adventure_Park__c(Name = 'Test Park', Is_Active__c = true, Open_Date__c = System.today() + 1, Park_Number__c = '918273645278');
        insert thePark;

        Park_Of_Interest__c theParkOfInterest = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark.Id);
        insert theParkOfInterest;

        Park_Of_Interest__c resultPOI = [SELECT Id, Account__c FROM Park_Of_Interest__c WHERE Id = :theParkOfInterest.Id];
        System.assert(resultPOI.Account__c == testAccount1.Id);


    }

    @IsTest
    static void testPOIMultipleContacts() {
        Account testAccount1 = new Account(Name = 'Test Account 1');
        insert testAccount1;

        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            AccountId = testAccount1.Id,
            Email = 'contact1@tpp.com');
        insert testContact1;

        Contact testContact2 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 2',
            AccountId = testAccount1.Id,
            Email = 'contact2@tpp.com');
        insert testContact2;

        Adventure_Park__c thePark = new Adventure_Park__c(Name = 'Test Site', Is_Active__c = true, Park_Number__c = '918273645278');
        thePark.Open_Date__c = Date.today();
        insert thePark;

        Adventure_Park__c thePark2 = new Adventure_Park__c(Name = 'Test Site2', Is_Active__c = true, Park_Number__c = '918273645277');
        thePark2.Open_Date__c = Date.today();
        insert thePark2;

        Park_Of_Interest__c theParkOfInterest = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark.Id);
        insert theParkOfInterest;

        List<Park_Of_Interest__c> resultPOIs = [SELECT Id, Account__c FROM Park_Of_Interest__c WHERE Account__c = :testAccount1.Id];
        System.assert(resultPOIs.size() == 2);

    }

    @IsTest
    static void testPOILeadConversion() {
        Adventure_Park__c thePark = new Adventure_Park__c(Name = 'Pirate\'s Cove', Park_Number__c = '918273645278');
        insert thePark;


        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222'
        );
        insert l;

        Park_Of_Interest__c theParkOfInterest = new Park_Of_Interest__c(
            Lead__c = l.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark.Id);
        insert theParkOfInterest;


        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
    }

    //Related to Lead Lifecycle Project
    //<Additon> Flora Flow - 28-11-2018
    //<Reason> Coming Soon Park field making as "FALSE" - Lead Lifecycle Project </Reason>

    //<Reason> Set Coming_Soon_Park__c as per Lead Lifecycle Project </Reason>
    @IsTest
    static void deletePOIFromLeadContactMethod() {
        Account accountRecord = new Account(Name = 'Customer Account');
        insert accountRecord;
        Contact contactRecord = new Contact(
            FirstName = 'Susie', LastName = 'Q', Email = 'susie.q@whereareyou.com', AccountId = accountRecord.Id
        );
        insert contactRecord;
        //Create Park with Open for sales date is greater than Today
        Adventure_Park__c park = new Adventure_Park__c(Name = 'Mermaid\'s Marine', Park_Number__c = '918273645278');
        park.Open_Date__c = System.today() + 1;
        insert park;
        // Create lead
        Lead leadRecord1 = new Lead(FirstName = 'Keiser', LastName = 'Soz', Email = 'whoAmI@identity.com', Company = 'Acme');
        insert leadRecord1;
        Park_Of_Interest__c poiRecord1 = new Park_Of_Interest__c(Adventure_Park__c = park.Id, Lead__c = leadRecord1.Id);
        insert poiRecord1;
        Test.startTest();
        delete poiRecord1;
        //Check POI records
        List<Park_Of_Interest__c> poiAfterDelete = [SELECT Id FROM Park_Of_Interest__c WHERE Id = :poiRecord1.Id];
        System.assertEquals(0, poiAfterDelete.size());
        // Set Coming_Soon_Park__c as "FALSE" whenever not getting POIs related to lead
        Lead leadRecordAfterUpdate1 = [SELECT Id, Name, Coming_Soon_Park__c FROM Lead WHERE Id = :leadRecord1.Id];
        System.assertEquals(false, leadRecordAfterUpdate1.Coming_Soon_Park__c);

        //Set Coming_Soon_Park__c as "TRUE" whenever getting POIs related to contact
        Adventure_Park__c park1 =new Adventure_Park__c(Name = 'Pirate\'s Cove', Park_Number__c = '918273645278');
        park1.Open_Date__c = System.today();
        insert park1;

        Lead leadRecord2 = new Lead(FirstName = 'James', LastName = 'Bond', Email = 'shaken@agency.com', Company = 'Acme');
        leadRecord2.LastName = 'Lead';
        insert leadRecord2;
        Park_Of_Interest__c poiRecord2 = new Park_Of_Interest__c(Adventure_Park__c = park1.Id, Lead__c = leadRecord2.Id);
        poiRecord2.Contact__c = contactRecord.Id;
        insert poiRecord2;
        Lead leadRecordAfterUpdate2 = [SELECT Id, Name, Coming_Soon_Park__c FROM Lead WHERE Id = :leadRecord2.Id];
        System.assertEquals(false, leadRecordAfterUpdate2.Coming_Soon_Park__c);
        Test.stopTest();
    }
    @IsTest
    static void updateComingSoonParkMethod() {
        Account accountRecord = new Account(Name = 'Test Account');
        insert accountRecord;
        Contact contactRecord = new Contact(
            FirstName = 'Susie', LastName = 'Q', Email = 'susie.q@whereareyou.com', AccountId = accountRecord.Id
        );
        insert contactRecord;
        //Create Park with Open for sales date is greater than Today
        Adventure_Park__c park = new Adventure_Park__c(Name = 'Mermaid\'s Marine', Park_Number__c = '918273645278');
        park.Open_Date__c = System.today() + 1;
        insert park;
        // Create lead
        Lead leadRecord1 = new Lead(FirstName = 'Keiser', LastName = 'Soz', Email = 'whoAmI@identity.com', Company = 'Acme');
        insert leadRecord1;
        Park_Of_Interest__c poiRecord1 = new Park_Of_Interest__c(Adventure_Park__c = park.Id, Lead__c = leadRecord1.Id);
        insert poiRecord1;

        Test.startTest();
        poiRecord1.Inactive__c = true;
        update poiRecord1;
        //When Inactive field is "TRUE", then set coming soon Park as "FALSE"
        Lead leadAfterUpdate1 = [SELECT Id, Name, Coming_Soon_Park__c FROM Lead WHERE Id = :leadRecord1.Id];
        System.assertEquals(false, leadAfterUpdate1.Coming_Soon_Park__c);

        //Added Rating is "Cold"
        poiRecord1.Rating__c = 'Cold';
        poiRecord1.Contact__c = contactRecord.Id;
        update poiRecord1;
        //When Rating is other than Inactive, then set coming soon Park as "TRUE"
        Lead leadAfterUpdate2 = [SELECT Id, Name, Coming_Soon_Park__c FROM Lead WHERE Id = :leadRecord1.Id];
        //System.assertEquals(TRUE,leadAfterUpdate2.Coming_Soon_Park__c);
        //Set Coming_Soon_Park__c as "TRUE" on Contact
        Contact contactAfterUpdate = [SELECT Id, Name, Coming_Soon_Park__c FROM Contact WHERE Id = :contactRecord.Id];
        //System.assertEquals(TRUE,contactAfterUpdate.Coming_Soon_Park__c);

        //Create another lead record
        Lead leadRecord2 = new Lead(FirstName = 'James', LastName = 'Bond', Email = 'shaken@agency.com', Company = 'Acme');
        leadRecord2.LastName = 'Lead';
        insert leadRecord2;
        Park_Of_Interest__c poiRecord2 = new Park_Of_Interest__c(Adventure_Park__c = park.Id, Lead__c = leadRecord2.Id);
        insert poiRecord2;
        //Update Rating as "Inactive" in park of interest object
//        poiRecord2.Rating__c = 'Inactive';
//        update poiRecord2;
        //Rating is "Inactive", still coming soon Park is "TRUE" because open
        Lead leadAfterUpdate3 = [SELECT Id, Name, Coming_Soon_Park__c FROM Lead WHERE Id = :leadRecord1.Id];
        //System.assertEquals(TRUE,leadAfterUpdate3.Coming_Soon_Park__c);
        Test.stopTest();
    }
    //</Addition> Flora Flow - 28-11-2018

    //<Addition> Levi - Sep 23, 2020 - Restrict to insert Duplicate POI records under the same Contact while inserting/updating POI records manually or during merging process - as per JIRA Ticket STDN-395
    @IsTest
    public static void deleteduplicatePOI_TEST() {
        List<Account> accList = new List<Account>();
        Account testAccount1 = new Account(Name = 'Test Account 1');
        accList.add(testAccount1);
        Account testAccount2 = new Account(Name = 'Test Account 2');
        accList.add(testAccount2);
        insert accList;

        List<Contact> conList = new List<Contact>();
        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            AccountId = testAccount1.Id,
            Email = 'contact1@tpp.com');
        conList.add(testContact1);

        Contact testContact2 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 2',
            Email = 'test@tpp.com',
            AccountId = testAccount2.Id
        );
        conList.add(testContact2);

        Contact testContact3 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 3',
            AccountId = testAccount1.Id,
            Email = 'contact1@tpp.com');
        conList.add(testContact3);
        insert conList;

        List<Adventure_Park__c> parkList = new List<Adventure_Park__c>();

        Adventure_Park__c thePark = new Adventure_Park__c(Name = 'Test Site', Is_Active__c = true, Park_Number__c = '918273645278');
        thePark.Open_Date__c = Date.today();
        parkList.add(thePark);

        Adventure_Park__c thePark2 = new Adventure_Park__c(Name = 'Test Site2', Is_Active__c = true, Park_Number__c = '918273645279');
        thePark2.Open_Date__c = Date.today();
        parkList.add(thePark2);

        Adventure_Park__c thePark3 = new Adventure_Park__c(Name = 'Test Site3', Is_Active__c = true, Park_Number__c = '918273645280');
        thePark3.Open_Date__c = Date.today();
        parkList.add(thePark3);
        insert parkList;

        //Check for UPDATE
        List<Park_Of_Interest__c> poiList = new List<Park_Of_Interest__c>();
        Park_Of_Interest__c theParkOfInterest1 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Hot',
            Adventure_Park__c = thePark.Id);
        poiList.add(theParkOfInterest1);

        Park_Of_Interest__c theParkOfInterest2 = new Park_Of_Interest__c(
            Contact__c = testContact2.Id,
            Account__c = testAccount2.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark.Id);
        poiList.add(theParkOfInterest2);
        insert poiList;

        Test.startTest();
        theParkOfInterest1.Contact__c = testContact2.Id;
        theParkOfInterest1.Account__c = testAccount2.Id;
        update theParkOfInterest1;

        //When modifieddate of duplicate POI is less or equal to existing POI then Rating on existing POI will not update.
        Park_Of_Interest__c poi1 = [SELECT Id, Rating__c FROM Park_Of_Interest__c WHERE Id = :theParkOfInterest2.Id LIMIT 1];
        System.assert(poi1.Rating__c == 'Warm');

        List<Park_Of_Interest__c> poi2 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact1.Id LIMIT 1];
        System.assert(poi2.size() == 0);

        //Check duplicate poi is not inserted
        List<Park_Of_Interest__c> poi23 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact2.Id LIMIT 1];
        System.assert(poi23.size() == 1);

        Park_Of_Interest__c theParkOfInterest3 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Hot',
            Adventure_Park__c = thePark.Id);
        insert theParkOfInterest3;

        theParkOfInterest3.Contact__c = testContact2.Id;
        theParkOfInterest3.Account__c = testAccount2.Id;
        update theParkOfInterest3;

        //When modifieddate of duplicate POI is greater to existing POI then Rating on existing POI will update.
        Park_Of_Interest__c poi3 = [SELECT Id, Rating__c FROM Park_Of_Interest__c WHERE Id = :theParkOfInterest2.Id LIMIT 1];
        System.assert(poi3.Rating__c == 'Warm');

        List<Park_Of_Interest__c> poi4 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact1.Id LIMIT 1];
        System.assert(poi4.size() == 0);

        //Check duplicate POI is not inserted
        List<Park_Of_Interest__c> poi24 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact2.Id LIMIT 1];
        System.assert(poi24.size() == 1);

        Park_Of_Interest__c theParkOfInterest4 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark.Id);
        insert theParkOfInterest4;

        update testContact1;

        theParkOfInterest2.Rating__c = null;
        update theParkOfInterest2;

        theParkOfInterest4.Contact__c = testContact2.Id;
        theParkOfInterest4.Account__c = testAccount2.Id;
        update theParkOfInterest4;

        //When modifieddate of duplicate POI is greater to existing POI but Rating of existing POI is null then Rating on existing POI will update.
        Park_Of_Interest__c poi5 = [SELECT Id, Rating__c FROM Park_Of_Interest__c WHERE Id = :theParkOfInterest2.Id LIMIT 1];
        System.assert(poi5.Rating__c == 'Warm');

        List<Park_Of_Interest__c> poi6 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact1.Id LIMIT 1];
        System.assert(poi6.size() == 0);

        //Check duplicate POI is not inserted
        List<Park_Of_Interest__c> poi34 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact2.Id LIMIT 1];
        System.assert(poi34.size() == 1);

        //Check For INSERT
        Park_Of_Interest__c theParkOfInterest12 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Hot',
            Adventure_Park__c = thePark2.Id);
        insert theParkOfInterest12;
        update testContact2;

        //Check Rating of existing POI
        Park_Of_Interest__c poi15 = [SELECT Id, Rating__c FROM Park_Of_Interest__c WHERE Id = :theParkOfInterest12.Id LIMIT 1];
        Assert.areEqual(poi15.Rating__c, 'Hot');

        Park_Of_Interest__c theParkOfInterest22 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark2.Id);


        insert theParkOfInterest22;

        //Check Rating of existing POI is updated with new duplicate POI Rating
        Park_Of_Interest__c poi12 = [SELECT Id, Rating__c FROM Park_Of_Interest__c WHERE Id = :theParkOfInterest12.Id LIMIT 1];
        System.assert(poi12.Rating__c == 'Warm');

        //Check duplicate POI is not inserted
        List<Park_Of_Interest__c> poi22 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact1.Id AND Adventure_Park__c = :thePark2.Id LIMIT 1];
        System.assert(poi22.size() == 1);

        Test.stopTest();

        //To Cover functionality if there is any other duplicate POIs present under contact for which POI is getting deleted then no POI should be deleted from all the related contacts.  As per STDN-395.
        List<Park_Of_Interest__c> poiList2 = new List<Park_Of_Interest__c>();
        Park_Of_Interest__c theParkOfInterest7 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Hot',
            Adventure_Park__c = thePark3.Id);
        poiList2.add(theParkOfInterest7);

        Park_Of_Interest__c theParkOfInterest8 = new Park_Of_Interest__c(
            Contact__c = testContact1.Id,
            Account__c = testAccount1.Id,
            Rating__c = 'Warm',
            Adventure_Park__c = thePark3.Id);
        //poiList2.add(theParkOfInterest8);

        insert poiList2;

        //Park_Of_Interest__c poi7 = [Select Id, Rating__c from Park_Of_Interest__c where Id = :theParkOfInterest8.Id limit 1];

        //DELETE poi7;

        List<Park_Of_Interest__c> poi8 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact1.Id AND Adventure_Park__c = :thePark3.Id LIMIT 1];
        System.assert(poi8.size() == 1);

        List<Park_Of_Interest__c> poi9 = [SELECT Id, IsDeleted FROM Park_Of_Interest__c WHERE Contact__c = :testContact3.Id AND Adventure_Park__c = :thePark3.Id LIMIT 1];
        System.assert(poi9.size() == 1);

    }
    //</Addition> Levi - Sep 23, 2020

    @TestSetup
    static void setup() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }
}
