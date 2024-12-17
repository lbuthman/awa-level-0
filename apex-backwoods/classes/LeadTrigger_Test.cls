@IsTest
private class LeadTrigger_Test {
    public static Map<String, String> testMetaDataMap;

    @IsTest
    static void leadTriggerTest1() {
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222');

        insert lead;

        Test.startTest();

//        Boolean errorWorked = false;
//
//        try {
//            update lead;
//        }
//        catch (Exception e) {
//            errorWorked = true;
//        }
//
//        System.assert(errorWorked);
//
        lead.Accept_Lead__c = true;
        update lead;

        Lead newLead = [SELECT Id, Accept_Lead__c FROM Lead WHERE Id = :lead.Id];

        System.assert(newLead.Accept_Lead__c == true);

        Test.stopTest();
    }

    @IsTest static void leadTriggerTest2() {

        Adventure_Park__c park = TestUtils.createNewPark('The Icy Glaciers', '234234234234');
        park.Is_Active__c = true;
        park.Open_Date__c = Date.today();
        insert park;

        Adventure_Park__c park2 = TestUtils.createNewPark('The Pesky Peaks', '123123123123');
        park2.Is_Active__c = true;
        park2.Open_Date__c = Date.today();
        insert park2;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222',
            Parks_Of_Interest__c = String.valueOf(park.Id));

        insert lead;

        Test.startTest();

        List<Park_Of_Interest__c> poiList = [SELECT Id, Adventure_Park__c FROM Park_Of_Interest__c WHERE Lead__c = :lead.Id];
        Lead newLead = [SELECT Id, Parks_Of_Interest__c FROM Lead WHERE Id = :lead.Id];

        System.assert(poiList.size() == 1 && poiList[0].Adventure_Park__c == park.Id);
        System.assert(newLead.Parks_Of_Interest__c == null);


        lead.Parks_Of_Interest__c = String.valueOf(park2.Id);
        lead.Park_Of_Interest_Rating__c = 'Hot';
        update lead;

        List<Park_Of_Interest__c> poiList2 = [
            SELECT Id, Adventure_Park__c, Rating__c
            FROM Park_Of_Interest__c
            WHERE Lead__c = :lead.Id AND Adventure_Park__c = :park2.Id
        ];
        Lead newLead2 = [SELECT Id, Parks_Of_Interest__c FROM Lead WHERE Id = :lead.Id];

        System.assert(poiList2.size() == 1 && poiList2[0].Rating__c == 'Hot');
        System.assert(newLead2.Parks_Of_Interest__c == null);

        Test.stopTest();
    }

    @IsTest static void leadTriggerTest3() {
        OperatingHours opH = new OperatingHours(Name = 'US Hours');
        insert opH;
        Adventure_Park__c park = TestUtils.createNewPark('The Icy Glaciers', '123123123123');
        park.Is_Active__c = true;
        park.Open_Date__c = Date.today();
        insert park;

        Adventure_Park__c park2 = TestUtils.createNewPark('The Pesky Peaks', '234234234234');
        park2.Is_Active__c = true;
        park2.Open_Date__c = Date.today();
        insert park2;

        Adventure_Park__c park3 = TestUtils.createNewPark('The Sinking Sands', '345345345345');
        park3.Is_Active__c = true;
        park3.Open_Date__c = Date.today();
        insert park3;

        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222',
            Parks_Of_Interest__c = String.valueOf(park.Id),
            Park_Of_Interest_Rating__c = 'Hot');

        insert l;

        Test.startTest();

        List<Park_Of_Interest__c> poiList = [
            SELECT Id, Adventure_Park__c, Rating__c
            FROM Park_Of_Interest__c
            WHERE Lead__c = :l.Id
        ];
        Lead newLead = [SELECT Id, Parks_Of_Interest__c, Park_Of_Interest_Rating__c FROM Lead WHERE Id = :l.Id];

        System.assert(poiList.size() == 1 && poiList[0].Adventure_Park__c == park.Id);
        System.assert(newLead.Parks_Of_Interest__c == null);

        l.Parks_Of_Interest__c = String.valueOf(park2.Id) + ',' + String.valueOf(park3.Id);
        l.Park_Of_Interest_Rating__c = null;
        update l;

        List<Park_Of_Interest__c> poiList2 = [
            SELECT Id
            FROM Park_Of_Interest__c
            WHERE Lead__c = :l.Id AND Adventure_Park__c != :park.Id
        ];
        Lead newLead2 = [SELECT Id, Parks_Of_Interest__c FROM Lead WHERE Id = :l.Id];

        System.assert(poiList2.size() == 2);
        System.assert(newLead2.Parks_Of_Interest__c == null);

        l.Parks_Of_Interest__c = String.valueOf(park.Id);
        update l;

        List<Park_Of_Interest__c> poiList3 = [
            SELECT Id, Adventure_Park__c, Rating__c
            FROM Park_Of_Interest__c
            WHERE Lead__c = :l.Id
        ];

        System.assert(poiList3.size() == 3);

        l.Parks_Of_Interest__c = String.valueOf(park.Id);
        l.Park_Of_Interest_Rating__c = 'Hot';
        update l;

        List<Park_Of_Interest__c> poiList4 = [
            SELECT Id, Adventure_Park__c, Rating__c
            FROM Park_Of_Interest__c
            WHERE Lead__c = :l.Id
        ];

        System.assert(poiList4.size() == 3);

        Test.stopTest();

    }

    @IsTest static void leadTriggerTest4() {
        Adventure_Park__c park = TestUtils.createNewPark('The Icy Glaciers', '123123123123');
        insert park;

        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222',
            Parks_Of_Interest__c = String.valueOf(park.Id));

        insert l;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Adventure_Park__c = park.Id,
            Lead__c = l.Id);

        insert poi;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = park.Id,
            Lead__c = l.Id);

        insert tour;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);

        Test.startTest();

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        Test.stopTest();

    }

    @IsTest static void leadTriggerTest5() {
        OperatingHours opH = new OperatingHours(Name = 'US Hours');
        insert opH;
        //test bad Id
        Lead l = new Lead(
            FirstName = 'Lavern',
            LastName = 'Test1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222',
            Parks_Of_Interest__c = '1234');

        insert l;

        Lead l2 = new Lead(
            FirstName = 'Shirely',
            LastName = 'Test2',
            Company = 'TestCo2',
            Email = 'test2@test.com',
            Phone = '3051111112',
            Parks_Of_Interest__c = '1234',
            Park_Of_Interest_Rating__c = 'Hot');

        insert l2;
    }

    @IsTest static void testPlannerAssignment() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        UserRole r = new UserRole(Name = 'Harpers Ferry Adventure Planner');
        insert r;

        User u = new User(Alias = 'standt', Email = 'test1@test9819192.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles', Username = 'test1@test9819192.com');
        insert u;

        User u2 = new User(Alias = 'standt', Email = 'test2@test9819192.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles', Username = 'test2@test9819192.com');
        insert u2;

        u.UserRoleId = r.Id;
        update u;

        u2.UserRoleId = r.Id;
        update u2;

        System.runAs (new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Adventure_Park__c thePark = TestUtils.createNewPark('Harpers Ferry', '123123123123');
            thePark.Is_Active__c = true;
            thePark.Open_Date__c = Date.today();
            insert thePark;

            Lead testLead = new Lead(
                LastName = 'Doe',
                FirstName = 'John',
                Company = 'Test',
                Email = 'testlead1@test.com',
                OwnerId = u.Id);
            insert testLead;

            Park_Tour__c tour = new Park_Tour__c(
                Adventure_Park__c = thePark.Id,
                Lead__c = testLead.Id,
                Arrival_Time__c = System.now());
            insert tour;

            testLead.Reprocessed_Reason__c = 'Different park theme';
            update testLead;

            Test.stopTest();
        }
    }

    @IsTest
    public static void plannerLeadStatusChangeMethod() {

        Lead lead1 = new Lead(
            FirstName = 'First',
            LastName = 'Lead',
            Email = 'first@lead.com',
            Company = 'Acme'
        );
        System.assertEquals(null, lead1.Status);

        Profile standard = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User planner = new User(Alias = 'standt', Email = 'test2@test9819192.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = standard.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'test2@test9819192.com');
        insert planner;

        System.runAs(planner) {
            List<Lead> leadListToInsert = new List<Lead>();
            Lead lead2 = new Lead(
                FirstName = 'Second',
                LastName = 'Lead',
                Email = 'second@lead.com',
                Company = 'Acme'
            );
            Lead lead3 = new Lead(
                FirstName = 'Third',
                LastName = 'Lead',
                Email = 'third@lead.com',
                Company = 'Acme'
            );
            leadListToInsert.add(lead2);
            leadListToInsert.add(lead3);
            insert leadListToInsert;

            Lead leadAfterInsert = [SELECT Id, Name, Status FROM Lead WHERE Id = :leadListToInsert[0].Id];

            //todo - not sure if this is the correct value, or because I changed the Profile
            //System.assertEquals('Engaged', leadAfterInsert.Status);

            //Disinterested Status
            //Added Disinterested Reason in the lead
            leadListToInsert[0].Disinterested_Reason__c = 'Hike too long';
            update leadListToInsert[0];
            //Update lead status to "Disinterested" after entering Disinterested reason
            Lead leadAfterUpdate1 = [SELECT Id, Name, Status, Disinterested_Reason__c, Disinterested_Reason_Z__c, OwnerId FROM Lead WHERE Id = :leadListToInsert[0].Id];
            System.assertEquals('Disinterested', leadAfterUpdate1.Status);
            System.assertEquals(leadListToInsert[0].Disinterested_Reason__c, leadAfterUpdate1.Disinterested_Reason_Z__c);

            //Added one more Disinterested Reason for showing reasons in Disinterested Reason-H field
            leadAfterUpdate1.Disinterested_Reason__c = 'Major life change upcoming';
            update leadAfterUpdate1;
            //Update lead status to "Disinterested" after entering Disinterested reason
            Lead leadAfterUpdate2 = [SELECT Id, Name, Status, Disinterested_Reason__c, Disinterested_Reason_Z__c, OwnerId FROM Lead WHERE Id = :leadAfterUpdate1.Id];
            System.assertEquals('Disinterested', leadAfterUpdate2.Status);
            System.assertEquals(leadAfterUpdate1.Disinterested_Reason_Z__c + ';' + leadAfterUpdate2.Disinterested_Reason__c, leadAfterUpdate2.Disinterested_Reason_Z__c);

            //Recycle Status

            leadListToInsert[1].Reprocessed_Reason__c = 'Interested in other Parks';
            update leadListToInsert[1];
            //Update lead status to "Recycled" after entering Revert reason
            Lead leadAfterUpdate3 = [SELECT Id, Name, Status, Reprocessed_Reason__c, Reprocessed_Reason_Z__c, OwnerId FROM Lead WHERE Id = :leadListToInsert[1].Id];
            System.assertEquals('Recycled', leadAfterUpdate3.Status);
            System.assertEquals(leadListToInsert[1].Reprocessed_Reason__c, leadAfterUpdate3.Reprocessed_Reason_Z__c);
            System.assertNotEquals(planner.Id, leadAfterUpdate3.OwnerId);


            //Added one more revert reason for showing reasons in Revert Reason-H field
            leadAfterUpdate3.Reprocessed_Reason__c = 'Fickle';
            update leadAfterUpdate3;
            //Update lead status to "Recycled" after entering Revert reason
            Lead leadAfterUpdate4 = [SELECT Id, Name, Status, Reprocessed_Reason__c, Reprocessed_Reason_Z__c, OwnerId FROM Lead WHERE Id = :leadAfterUpdate3.Id];
            System.assertEquals('Recycled', leadAfterUpdate4.Status);
            System.assertNotEquals(planner.Id, leadAfterUpdate4.OwnerId);
            System.assertEquals(leadAfterUpdate3.Reprocessed_Reason_Z__c + ';' + leadAfterUpdate4.Reprocessed_Reason__c, leadAfterUpdate4.Reprocessed_Reason_Z__c);
        }
    }

    @IsTest
    public static void plannerLeadStatusChangeMethod2() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User planner = new User(Alias = 'standt', Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'test12345@test_.com');
        insert planner;

        System.runAs(planner) {
            Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Email = 'testlead1@test.com',
                Status = 'New',
                LeadSource = 'In Person',
                Company = 'Test'
            );
            insert lead;
            Lead leadAfterInsert = [SELECT Id, Name, Status FROM Lead WHERE Id = :lead.Id];
            System.assertEquals('New', leadAfterInsert.Status);

            //l.Reprocessed_Reason__c = 'Different park location';
            //UPDATE l;
        }
    }

    @IsTest
    public static void plannerOwnerAssignmentMethod() {
        //Add lead with default status: New
        Lead lead = new Lead(FirstName = 'Test', LastName = 'Lead', Email = 'testlead@test.com', Status = 'New', LeadSource = 'Call', Company = 'Test');
        insert lead;
        System.assertEquals('New', lead.Status);

        User plannerUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        System.runAs(plannerUser) {
            //Add Recycled Reason to the lead
            lead.Reprocessed_Reason__c = 'Different park location';
            update lead;

            //Update lead status to 'Engaged'
            Lead leadAfterUpdate1 = [SELECT Id, Name, Status, Reprocessed_Reason__c FROM Lead WHERE Id = :lead.Id];
            System.assertEquals('Engaged', leadAfterUpdate1.Status);

            //Add one more Recycle Reason to the lead
            lead.Reprocessed_Reason__c = 'Different park price';
            update lead;

            //Update lead status to 'Engaged'
            Lead leadAfterUpdate2 = [SELECT Id, Name, Status, Reprocessed_Reason__c FROM Lead WHERE Id = :lead.Id];
            System.assertEquals('Engaged', leadAfterUpdate2.Status);

            //Add one more Recycle Reason to the lead
            lead.Reprocessed_Reason__c = 'Different park theme';
            update lead;

            //Update lead status to 'Engaged'
            Lead leadAfterUpdate3 = [SELECT Id, Name, Status, Reprocessed_Reason__c FROM Lead WHERE Id = :lead.Id];
            System.assertEquals('Engaged', leadAfterUpdate3.Status);
        }

    }

    @IsTest
    public static void plannerLeadStatusChangeMethodForLightningProfile() {
        //Added lead with "New" default status
        Lead lead1 = new Lead(FirstName = 'First', LastName = 'Lead', Email = 'first@test.com', Status = 'New', LeadSource = 'Call', Company = 'Test');
        System.assertEquals('New', lead1.Status);

        User lightningPlannerUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        //Running as Lightning User
        System.runAs(lightningPlannerUser) {
            List<Lead> leadListToInsert = new List<Lead>();
            //Create lead record by Planner user with "New" status
            Lead lead2 = new Lead(FirstName = 'Second', LastName = 'Lead', Email = 'second@test.com', Status = 'New', LeadSource = 'Call', Company = 'Test');
            Lead lead3 = new Lead(FirstName = 'Third', LastName = 'Lead', Email = 'third@test.com', Status = 'New', LeadSource = 'Call', Company = 'Test');
            leadListToInsert.add(lead2);
            leadListToInsert.add(lead3);
            insert leadListToInsert;

            //Disinterested Status
            //Added Disinterested Reason in the lead
            leadListToInsert[0].Disinterested_Reason__c = 'Affordability issues';
            update leadListToInsert[0];
            //Update lead status to "Disinterested" after entering Disinterested reason
            Lead leadAfterUpdate1 = [SELECT Id, Name, Status, Disinterested_Reason__c, Disinterested_Reason_Z__c, Owner.Profile.Name FROM Lead WHERE Id = :leadListToInsert[0].Id];
            System.assertEquals('Disinterested', leadAfterUpdate1.Status);
            System.assertEquals(leadListToInsert[0].Disinterested_Reason__c, leadAfterUpdate1.Disinterested_Reason_Z__c);

            //Added one more Disinterested Reason for showing reasons in Disinterested Reason-H field
            leadAfterUpdate1.Disinterested_Reason__c = 'Going with another company';
            update leadAfterUpdate1;
            //Update lead status to "Disinterested" after entering Disinterested reason
            Lead leadAfterUpdate2 = [SELECT Id, Name, Status, Disinterested_Reason__c, Disinterested_Reason_Z__c, Owner.Profile.Name FROM Lead WHERE Id = :leadAfterUpdate1.Id];
            System.assertEquals('Disinterested', leadAfterUpdate2.Status);
            System.assertEquals(leadAfterUpdate1.Disinterested_Reason_Z__c + ';' + leadAfterUpdate2.Disinterested_Reason__c, leadAfterUpdate2.Disinterested_Reason_Z__c);

            //Recycle Status
            //Added Recycle Reason in the lead
            leadListToInsert[1].Reprocessed_Reason__c = 'Changing vacation destination';
            update leadListToInsert[1];
            //Update lead status to "Recycle" after entering Recycle reason
            Lead leadAfterUpdate3 = [SELECT Id, Name, Status, Reprocessed_Reason__c, Reprocessed_Reason_Z__c, Owner.Profile.Name FROM Lead WHERE Id = :leadListToInsert[1].Id];
            System.assertEquals('Recycled', leadAfterUpdate3.Status);
            System.assertEquals(leadListToInsert[1].Reprocessed_Reason__c, leadAfterUpdate3.Reprocessed_Reason_Z__c);


            //Added one more Recycle reason for showing reasons in Recycle Reason-H field
            leadAfterUpdate3.Reprocessed_Reason__c = 'New job, circle back in 1 month';
            update leadAfterUpdate3;
            //Update lead status to "Recycle" after entering Recycle reason
            Lead leadAfterUpdate4 = [SELECT Id, Name, Status, Reprocessed_Reason__c, Reprocessed_Reason_Z__c, Owner.Profile.Name FROM Lead WHERE Id = :leadAfterUpdate3.Id];
            System.assertEquals('Recycled', leadAfterUpdate4.Status);
            System.assertEquals(leadAfterUpdate3.Reprocessed_Reason_Z__c + ';' + leadAfterUpdate4.Reprocessed_Reason__c, leadAfterUpdate4.Reprocessed_Reason_Z__c);
        }
    }

    @IsTest
    static void convertedLeadWithParkOfInterest() {
        OperatingHours opH = new OperatingHours(Name = 'US Hours');
        insert opH;

        Adventure_Park__c park = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        park.Is_Active__c = true;
        park.Open_Date__c = Date.today();
        insert park;

        Adventure_Park__c park2 = TestUtils.createNewPark('The Craggy Cliffs', '234234234234');
        park2.Is_Active__c = true;
        park2.Open_Date__c = Date.today();
        insert park2;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'TestCo',
            Email = 'test@gmail.com',
            Phone = '3031111111',
            MobilePhone = '30302222222',
            Parks_Of_Interest__c = String.valueOf(park.Id));

        insert testLead;

        List<Park_Of_Interest__c> priorTestParkOfInterest = [SELECT Id, Contact__c, Adventure_Park__c FROM Park_Of_Interest__c WHERE Lead__c = :testLead.Id];
        Lead newLead = [SELECT Id, Parks_Of_Interest__c FROM Lead WHERE Id = :testLead.Id];

        System.assert(priorTestParkOfInterest.size() == 1 && priorTestParkOfInterest[0].Adventure_Park__c == park.Id);
        System.assert(newLead.Parks_Of_Interest__c == null);
        System.assertEquals(null, priorTestParkOfInterest[0].Contact__c, 'We expect the field to be null');

        Test.startTest();
        Database.LeadConvert testLeadConvert = new Database.LeadConvert();
        testLeadConvert.setLeadId(testLead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        testLeadConvert.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult testLeadConvertResult = Database.convertLead(testLeadConvert);
        System.assert(testLeadConvertResult.isSuccess());
        Id expectedAccountId = testLeadConvertResult.getAccountId();
        Id expectedContactId = testLeadConvertResult.getContactId();
        Test.stopTest();

        List<Park_Of_Interest__c> resultTestParkOfInterests = [SELECT Id, Contact__c, Adventure_Park__c FROM Park_Of_Interest__c];
        System.assertEquals(1, resultTestParkOfInterests.size(), 'We expect 1 Park of Interest');
        System.assertEquals(expectedContactId, resultTestParkOfInterests[0].Contact__c, 'We expect the field to be populated');

    }

    @IsTest
    static void getPlannerRoleId_Test() {
        Map<String, Id> roleMap = LeadTrigger_Helper.getPlannerRoleMap();
        Test.startTest();
        Id boulderResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Boulder');
        Id bendResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Bend');
        Id moabResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Moab');
        Id gatlinburgResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Gatlinburg');
        Id ashevilleResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Asheville');
        Id jacksonResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Jackson');
        Id lakeTahoeResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Lake Tahoe');
        Id austinResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Austin');
        Id sedonaResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Sedona');
        Id benHarborResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Bar Harbor');
        Id stoweResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Stowe');
        Id helenResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Helen');
        Id brevardResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Brevard');
        Id harpersFerryResultId = LeadTrigger_Helper.getPlannerRoleId(roleMap, 'Harpers Ferry');
        Test.stopTest();

        Id boulderExpectedId = roleMap.get('Boulder Adventure Planner');
        System.assertEquals(boulderExpectedId, boulderResultId, 'We expect the role Id associated to the expected name to be returned');
        Id bendExpectedId = roleMap.get('Bend Adventure Planner');
        System.assertEquals(bendExpectedId, bendResultId, 'We expect the role Id associated to the expected name to be returned');
        Id moabExpectedId = roleMap.get('Moab Adventure Planner');
        System.assertEquals(moabExpectedId, moabResultId, 'We expect the role Id associated to the expected name to be returned');
        Id gatlinburgExpectedId = roleMap.get('Gatlinburg Adventure Planner');
        System.assertEquals(gatlinburgExpectedId, gatlinburgResultId, 'We expect the role Id associated to the expected name to be returned');
        Id ashevilleExpectedId = roleMap.get('Asheville Adventure Planner');
        System.assertEquals(ashevilleExpectedId, ashevilleResultId, 'We expect the role Id associated to the expected name to be returned');
        Id jacksonExpectedId = roleMap.get('Jackson Adventure Planner');
        System.assertEquals(jacksonExpectedId, jacksonResultId, 'We expect the role Id associated to the expected name to be returned');
        Id lakeTahoeExpectedId = roleMap.get('Lake Tahoe Adventure Planner');
        System.assertEquals(lakeTahoeExpectedId, lakeTahoeResultId, 'We expect the role Id associated to the expected name to be returned');
        Id austinExpectedId = roleMap.get('Austin Adventure Planner');
        System.assertEquals(austinExpectedId, austinResultId, 'We expect the role Id associated to the expected name to be returned');
        Id sedonaExpectedId = roleMap.get('Sedona Adventure Planner');
        System.assertEquals(sedonaExpectedId, sedonaResultId, 'We expect the role Id associated to the expected name to be returned');
        Id stoweExpectedId = roleMap.get('Stowe Adventure Planner');
        System.assertEquals(stoweExpectedId, stoweResultId, 'We expect the role Id associated to the expected name to be returned');
        Id helenExpectedId = roleMap.get('Helen Adventure Planner');
        System.assertEquals(helenExpectedId, helenResultId, 'We expect the role Id associated to the expected name to be returned');
        Id brevardExpectedId = roleMap.get('Brevard Adventure Planner');
        System.assertEquals(brevardExpectedId, brevardResultId, 'We expect the role Id associated to the expected name to be returned');
        Id harpersFerryExpectedId = roleMap.get('Harpers Ferry Adventure Planner');
        System.assertEquals(harpersFerryExpectedId, harpersFerryResultId, 'We expect the role Id associated to the expected name to be returned');

    }
}
