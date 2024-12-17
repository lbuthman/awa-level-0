public without sharing class LeadTrigger_Helper {

    public static void captureStatusChangeDate(List<Lead> leads) {
        List<Lead_and_Contact_Dates__mdt> temp = [SELECT Id, MasterLabel, Date_Field__c FROM Lead_and_Contact_Dates__mdt WHERE Object_Type__c = 'Lead'];
        for (Lead eachLead : leads) {
            for (Lead_and_Contact_Dates__mdt each : temp) {
                if (each.MasterLabel == eachLead.Status) {
                    eachLead.put(each.Date_Field__c, System.today());
                }
            }
            //Update Lead Owner as "Marketing" when lead status is Reprocessed
            if (eachLead.Status == 'Reprocessed') {
                User fakeMarketingUser = [SELECT Id FROM User WHERE Profile.Name = :System.Label.Fake_Marketing_User LIMIT 1];
                eachLead.OwnerId = fakeMarketingUser.Id;
            }
        }
    }

    public static void processReprocessedAndDisinterestedLeads(Lead newLead, Lead oldLead) {
        List<Lead> leadsToAssignToPlanner = new List<Lead>();

        if (oldLead.Disinterested_Reason__c != newLead.Disinterested_Reason__c && newLead.Disinterested_Reason__c != null) {
            newLead.Status = 'Disinterested';
            if (newLead.Disinterested_Reason_Z__c == null) {
                newLead.Disinterested_Reason_Z__c = newLead.Disinterested_Reason__c;
            }
            else {
                if (newLead.Disinterested_Reason_Z__c.contains(';')) {
                    List<String> disquaReason = newLead.Disinterested_Reason_Z__c.split(';');
                    if (disquaReason[disquaReason.size() - 1] != newLead.Disinterested_Reason__c) {
                        newLead.Disinterested_Reason_Z__c += ';' + newLead.Disinterested_Reason__c;
                    }
                }
                else if (newLead.Disinterested_Reason_Z__c != newLead.Disinterested_Reason__c) {
                    newLead.Disinterested_Reason_Z__c += ';' + newLead.Disinterested_Reason__c;
                }
            }
        }

        //Change lead status to Reprocess if Reason is added
        if (newLead.Reprocessed_Reason__c != null && oldLead.Reprocessed_Reason__c != newLead.Reprocessed_Reason__c) {
            if (newLead.Reprocessed_Reason__c != 'Different park location' && newLead.Reprocessed_Reason__c != 'Different park price' && newLead.Reprocessed_Reason__c != 'Different park theme') {
                newLead.Status = 'Reprocessed';
                User fakeMarketingUser = [SELECT Id FROM User WHERE Profile.Name = :System.Label.Fake_Marketing_User LIMIT 1];
                newLead.OwnerId = fakeMarketingUser.Id;
            }
            else if (newLead.Reprocessed_Reason__c == 'Different park location' || newLead.Reprocessed_Reason__c == 'Different park price' || newLead.Reprocessed_Reason__c == 'Different park theme') {
                newLead.Status = 'Engaged';
                leadsToAssignToPlanner.add(newLead);
            }

            if (newLead.Reprocessed_Reason_Z__c == null) {
                newLead.Reprocessed_Reason_Z__c = newLead.Reprocessed_Reason__c;
            }
            else {
                if (newLead.Reprocessed_Reason_Z__c.contains(';')) {
                    List<String> revertReason = newLead.Reprocessed_Reason_Z__c.split(';');
                    if (revertReason[revertReason.size() - 1] != newLead.Reprocessed_Reason__c) {
                        newLead.Reprocessed_Reason_Z__c += ';' + newLead.Reprocessed_Reason__c;
                    }
                }
                else if (newLead.Reprocessed_Reason_Z__c != newLead.Reprocessed_Reason__c) {
                    newLead.Reprocessed_Reason_Z__c += ';' + newLead.Reprocessed_Reason__c;
                }
            }
        }
        //}
    }

    public static void reassignLead(List<Lead> leads) {
        for (Lead l : leads) {
            l.OwnerId = UserInfo.getUserId();
        }
    }

    public static void assignPlannerTasks(Set<Id> leadIds) {
        List<Lead> leads = [SELECT Id, (SELECT Id, Arrival_Time__c, Adventure_Park__r.Name, Adventure_Park__c FROM Park_Tour__r WHERE Arrival_Time__c != NULL ORDER BY Arrival_Time__c DESC) FROM Lead WHERE Id IN :leadIds];
        List<Task> tasksForInsert = new List<Task>();

        Map<String, Id> plannerRoleMap = getPlannerRoleMap();
        Map<Id, List<User>> plannerUserMap = new Map<Id, List<User>>();
        List<User> plannerUsers = [SELECT Id, UserRole.Id FROM User WHERE UserRole.Id IN :plannerRoleMap.values() AND IsActive = TRUE];

        for (Id plannerRoleId : plannerRoleMap.values()) {
            List<User> users = new List<User>();
            for (User u : plannerUsers) {
                if (u.UserRole.Id == plannerRoleId) {
                    users.add(u);
                }
            }
            plannerUserMap.put(plannerRoleId, users);
        }


        for (Lead l : leads) {
            String parkName;

            if (l.Park_Tour__r.size() > 0) {
                parkName = l.Park_Tour__r[0].Adventure_Park__r.Name;

                String taskId = l.Id + String.valueOf(Math.random() * 100000).left(5);
                Id plannerRoleId = getPlannerRoleId(plannerRoleMap, parkName);
                if (plannerRoleId != null) {

                    for (User u : plannerUserMap.get(plannerRoleId)) {
                        Task t = new Task(
                            OwnerId = u.Id,
                            Status = 'Not Started',
                            Subject = 'Attn: Reprocessed Lead',
                            WhoId = l.Id,
                            ActivityDate = System.today().addDays(1));

                        tasksForInsert.add(t);
                    }

                }
            }
        }

        if (tasksForInsert.size() > 0) {
            /*Database.DMLOptions dmlOptions = new Database.DMLOptions();
dmlOptions.EmailHeader.TriggerUserEmail = TRUE;
Database.Insert(tasksForInsert,dmlOptions);*/
            insert tasksForInsert;
        }


    }

    public static Map<String, Id> getPlannerRoleMap() {
        Map<String, Id> results = new Map<String, Id>();

        //Modification below code by adding check in SOQL query for getting minimal rows as per STDN-226 for code optimization - Sarah-19 May,2020
        //for(UserRole ur : [Select Id, Name from UserRole]){
        for (UserRole ur : [SELECT Id, Name FROM UserRole WHERE Name LIKE '%Planner%']) {
            //if(ur.Name.contains('Adventure Planner')){
            results.put(ur.Name, ur.Id);
            //}
        }

        return results;
    }

    public static Id getPlannerRoleId(Map<String, Id> roleMap, String parkNanme) {
        Id result;

        if (parkNanme == 'Boulder') {
            result = roleMap.get('Boulder Adventure Planner');
        }

        if (parkNanme == 'Bend') {
            result = roleMap.get('Bend Adventure Planner');
        }

        if (parkNanme == 'Moab') {
            result = roleMap.get('Moab Adventure Planner');
        }

        if (parkNanme == 'Gatlinburg') {
            result = roleMap.get('Gatlinburg Adventure Planner');
        }

        if (parkNanme == 'Asheville') {
            result = roleMap.get('Asheville Adventure Planner');
        }

        if (parkNanme == 'Jackson') {
            result = roleMap.get('Jackson Adventure Planner');
        }

        if (parkNanme == 'Lake Tahoe') {
            result = roleMap.get('Lake Tahoe Adventure Planner');
        }

        if (parkNanme == 'Austin') {
            result = roleMap.get('Austin Adventure Planner');
        }

        if (parkNanme == 'Sedona') {
            result = roleMap.get('Sedona Adventure Planner');
        }

        if (parkNanme == 'Bar Harbor') {
            result = roleMap.get('Bar Harbor Adventure Planner');
        }

        if (parkNanme == 'Stowe') {
            result = roleMap.get('Stowe Adventure Planner');
        }

        if (parkNanme == 'Helen') {
            result = roleMap.get('Helen Adventure Planner');
        }

        if (parkNanme == 'Brevard') {
            result = roleMap.get('Brevard Adventure Planner');
        }

        if (parkNanme == 'Harpers Ferry') {
            result = roleMap.get('Harpers Ferry Adventure Planner');
        }

        return result;
    }

    public static void parkIntrestCreate(Set<Id> leadIds, Boolean isNew) {
        List<Lead> leads = [SELECT Id, Parks_Of_Interest__c, Park_Of_Interest_Rating__c, Name, Email, (SELECT Id, Adventure_Park__c, Lead__c FROM Parks_Of_Interest__r WHERE Lead__c IN :leadIds) FROM Lead WHERE Id IN :leadIds];
        List<Park_Of_Interest__c> poiForInsert = new List<Park_Of_Interest__c>();
        Set<Id> parkIdsFromLeads = new Set<Id>();
        List<Lead> leadsGoodId = new List<Lead>();
        Map<Lead, String> leadIsBadMap = new Map<Lead, String>();
        List<Adventure_Park__c> parks = new List<Adventure_Park__c>();
        Set<Id> parkIds = new Set<Id>();

        if (leads != null && !leads.isEmpty()) {
            for (Lead lead : leads) {
                List<String> parkIdsList = new List<String>();

                if (lead.Parks_Of_Interest__c.contains(',')) {
                    for (String s : lead.Parks_Of_Interest__c.split(',', 0)) {
                        String parkId = s.replace(' ', '');
                        parkIdsList.add(parkId);
                    }
                }
                else {
                    if (lead.Parks_Of_Interest__c.contains(';')) {
                        for (String s : lead.Parks_Of_Interest__c.split(';', 0)) {
                            String parkId = s.replace(' ', '');
                            parkIdsList.add(parkId);
                        }
                    }
                    else {
                        parkIdsList.add(lead.Parks_Of_Interest__c);
                    }
                }

                Boolean goodLead = false;
                if (!parkIdsList.isEmpty()) {
                    for (String s : parkIdsList) {
                        if ((s.length() == 15 || s.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', s)) {
                            parkIdsFromLeads.add(Id.valueOf(s));
                            goodLead = true;
                        }
                        else {
                            goodLead = false;
                        }
                    }
                }


                if (goodLead == true) {
                    leadsGoodId.add(lead);
                }
                else {
                    leadIsBadMap.put(lead, 'Invalid Adventure Park Id');

                }
            }
        }

        if (parkIdsFromLeads != null && !parkIdsFromLeads.isEmpty()) {//Added as per STDN-226 ticket for code optimization - Sarah-19 May,2020
            for (Adventure_Park__c site : [SELECT Id, Is_Active__c FROM Adventure_Park__c WHERE Id IN :parkIdsFromLeads]) {
                parkIds.add(site.Id);
                parks.add(site);
            }
        }


        List<Lead> leadsForUpdate = new List<Lead>();
        Set<Id> leadIdsForUpdate = new Set<Id>();

        if (!leadsGoodId.isEmpty()) {
            for (Lead lead : leadsGoodId) {
                List<String> parkIdsList = new List<String>();

                if (lead.Parks_Of_Interest__c.contains(',')) {
                    for (String s : lead.Parks_Of_Interest__c.split(',', 0)) {
                        String parkId = s.replace(' ', '');
                        parkIdsList.add(parkId);
                    }
                }
                else {
                    if (lead.Parks_Of_Interest__c.contains(';')) {
                        for (String s : lead.Parks_Of_Interest__c.split(';', 0)) {
                            String parkId = s.replace(' ', '');
                            parkIdsList.add(parkId);
                        }
                    }
                    else {
                        parkIdsList.add(lead.Parks_Of_Interest__c);
                    }
                }

                Set<Id> existingParkIds = new Set<Id>();

                if (isNew == false) {
                    if (leads != null && !leads.isEmpty()) {
                        for (Lead each : leads) {
                            if (each.Parks_Of_Interest__r != null && !each.Parks_Of_Interest__r.isEmpty()) {
                                for (Park_Of_Interest__c poi : each.Parks_Of_Interest__r /*existingLists*/) {
                                    if (poi.Lead__c == lead.Id) {
                                        existingParkIds.add(poi.Adventure_Park__c);
                                    }
                                }
                            }
                        }
                    }
                }

                if (!parkIdsList.isEmpty()) {
                    for (String park : parkIdsList) {
                        Id parkId = Id.valueOf(park);
                        Boolean hasList = false;
                        Boolean validId = false;

                        if (existingParkIds.contains(parkId)) {
                            hasList = true;
                        }

                        if (parkIds.contains(parkId)) {
                            for (Adventure_Park__c s : parks) {
                                if (parkId == s.Id) {
                                    if (s.Is_Active__c == true) {
                                        validId = true;
                                    }
                                    else {
                                        validId = false;
                                        leadIsBadMap.put(lead, 'Inactive Park Id - ' + parkId);

                                    }
                                }
                            }
                        }

                        if (hasList == false && validId == true) {
                            Park_Of_Interest__c poi = new Park_Of_Interest__c(
                                Adventure_Park__c = parkId,
                                Lead__c = lead.Id);
                            if (!poiForInsert.contains(poi)) {
                                poiForInsert.add(poi);
                            }
                        }

                        if (validId == false && !leadIsBadMap.containsKey(lead)) {
                            leadIsBadMap.put(lead, 'Invalid Park Id');
                        }
                    }
                }


                if (!leadIdsForUpdate.contains(lead.Id)) {
                    Lead l = new Lead(
                        Id = lead.Id,
                        Parks_Of_Interest__c = null);

                    leadsForUpdate.add(l);
                    leadIdsForUpdate.add(lead.Id);
                }
            }
        }
        if (poiForInsert.size() > 0) {
            insert poiForInsert;
        }

        if (leadIsBadMap.size() > 0) {
            for (Lead lead : leadIsBadMap.keySet()) {
                Lead l = new Lead(
                    Id = lead.Id,
                    Parks_Of_Interest__c = null,
                    Park_Of_Interest_Rating__c = null);
                if (!leadIdsForUpdate.contains(lead.Id)) {
                    leadsForUpdate.add(l);
                }
            }
        }

        if (leadsForUpdate.size() > 0) {
            update leadsForUpdate;
        }
    }

    public static void parkIntrestCreateWithRatings(Set<Id> leadIds, Boolean isNew) {
        List<Lead> leads = [SELECT Id, Parks_Of_Interest__c, Park_Of_Interest_Rating__c, Name, Email, (SELECT Id, Adventure_Park__c, Lead__c FROM Parks_Of_Interest__r WHERE Lead__c IN :leadIds) FROM Lead WHERE Id IN :leadIds];

        List<Park_Of_Interest__c> poiRecsForInsert = new List<Park_Of_Interest__c>();
        Set<Id> parkIdsFromLeads = new Set<Id>();
        List<Lead> leadsGoodId = new List<Lead>();
        Map<Lead, String> leadIsBadMap = new Map<Lead, String>();
        List<Adventure_Park__c> parks = new List<Adventure_Park__c>();
        Set<Id> parkIds = new Set<Id>();

        if (leads != null && !leads.isEmpty()) {
            for (Lead lead : leads) {
                if ((lead.Parks_Of_Interest__c.length() == 15 || lead.Parks_Of_Interest__c.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', lead.Parks_Of_Interest__c)) {
                    parkIdsFromLeads.add(Id.valueOf(lead.Parks_Of_Interest__c));
                    leadsGoodId.add(lead);
                }
                else {
                    leadIsBadMap.put(lead, 'Invalid Park Id');
                }
            }
        }

        if (!parkIdsFromLeads.isEmpty()) {
            for (Adventure_Park__c site : [SELECT Id, Is_Active__c FROM Adventure_Park__c WHERE Id IN :parkIdsFromLeads]) {
                parkIds.add(site.Id);
                parks.add(site);
            }
        }

        List<Lead> leadsForUpdate = new List<Lead>();

        if (!leadsGoodId.isEmpty()) {
            for (Lead lead : leadsGoodId) {
                Id parkId = Id.valueOf(lead.Parks_Of_Interest__c);

                if (parkIds.contains(parkId)) {
                    Boolean validId = false;

                    if (!parks.isEmpty()) {
                        for (Adventure_Park__c s : parks) {
                            if (parkId == s.Id) {
                                if (s.Is_Active__c == true) {
                                    validId = true;
                                }
                                else {
                                    validId = false;
                                    leadIsBadMap.put(lead, 'Inactive Park Id - ' + parkId);
                                }
                                break;
                            }
                        }
                    }
                    if (validId == true) {

                        Boolean hasList = false;

                        Set<Id> existingParkIds = new Set<Id>();

                        if (isNew == false) {
                            if (leads != null && !leads.isEmpty()) {
                                for (Lead each : leads) {
                                    if (each.Parks_Of_Interest__r != null && !each.Parks_Of_Interest__r.isEmpty()) {
                                        for (Park_Of_Interest__c poi : each.Parks_Of_Interest__r /*existingLists*/) {
                                            if (poi.Lead__c == lead.Id) {
                                                existingParkIds.add(poi.Adventure_Park__c);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if (existingParkIds.contains(parkId)) {
                            hasList = true;
                        }

                        if (!hasList) {
                            Park_Of_Interest__c poi = new Park_Of_Interest__c(
                                Adventure_Park__c = parkId,
                                Lead__c = lead.Id,
                                Rating__c = lead.Park_Of_Interest_Rating__c);
                            if (!poiRecsForInsert.contains(poi)) {
                                poiRecsForInsert.add(poi);
                            }
                        }

                        Lead l = new Lead(
                            Id = lead.Id,
                            Parks_Of_Interest__c = null,
                            Park_Of_Interest_Rating__c = null);
                        if (!leadsForUpdate.contains(l)) {
                            leadsForUpdate.add(l);
                        }
                    }
                    else {
                        if (!leadIsBadMap.containsKey(lead)) {
                            leadIsBadMap.put(lead, 'Invalid Park Id');
                        }
                    }
                }
            }
        }
        if (poiRecsForInsert.size() > 0) {
            insert poiRecsForInsert;
        }

        if (leadIsBadMap.size() > 0) {
            for (Lead lead : leadIsBadMap.keySet()) {
                Lead l = new Lead(
                    Id = lead.Id,
                    Parks_Of_Interest__c = null,
                    Park_Of_Interest_Rating__c = null);

                leadsForUpdate.add(l);
            }
        }

        if (leadsForUpdate.size() > 0) {
            update leadsForUpdate;
        }
    }

    public static void startLeadConvertProcess(Set<Id> ids) {
        Set<Id> acctIds = new Set<Id>();
        Set<Id> conIds = new Set<Id>();
        Map<Id, Lead> leadIdToLeadMap = new Map<Id, Lead>();
        List<Lead> convertedLeads = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId, Vendor_Segment_Id__c,
                LastName, Phone, MobilePhone, Email, Adventure_Timeframe__c, Household_Income__c,
            (SELECT Id, Lead__c, Adventure_Park__c FROM Park_Tour__r WHERE Lead__c IN :ids ORDER BY Id),
            (SELECT Id, Lead__c FROM Parks_Of_Interest__r WHERE Lead__c IN :ids)
            FROM Lead
            WHERE Id IN :ids
        ];

        Set<Id> leadIdstoContiunue = new Set<Id>();
        if (!convertedLeads.isEmpty()) {
            for (Lead l : convertedLeads) {
                acctIds.add(l.ConvertedAccountId);
                conIds.add(l.ConvertedContactId);
            }
        }

        Map<Id, Integer> accountIdToBuyerMap = new Map<Id, Integer>();

        if (!acctIds.isEmpty()) {
            List<Account> accts = [
                SELECT Id, CreatedDate, (SELECT Id, AccountId, Name, CreatedDate FROM Contacts WHERE Id NOT IN :conIds)
                FROM Account
                WHERE Id IN :acctIds
            ];

            for (Id acctId : acctIds) {
                Id leadId;
                Lead lead;

                for (Lead lead2 : convertedLeads) {
                    if (acctId == lead2.ConvertedAccountId) {
                        leadId = lead2.Id;
                        lead = lead2;
                        break;
                    }
                }

                for (Account account : accts) {
                    leadIdstoContiunue.add(leadId);
                    leadIdToLeadMap.put(leadId, lead);

                    if (account.Contacts != null && !account.Contacts.isEmpty()) {
                        for (Contact con : account.Contacts) {
                            accountIdToBuyerMap.put(con.AccountId, 1);
                        }
                    }
                    break;
                }
            }
        }
        if (leadIdstoContiunue.size() > 0) {
            leadConvertProcess(leadIdToLeadMap, accountIdToBuyerMap);
        }

    }

    public static void leadConvertProcess(Map<Id, Lead> leadIdToLeadMap, Map<Id, Integer> accountIdToBuyerMap) {
        List<Lead> convertedLeads = leadIdToLeadMap.values();
        Set<Id> ids = leadIdToLeadMap.keySet();
        Set<Id> firstVisitSet = new Set<Id>();
        Set<Id> firstVisitParkSet = new Set<Id>();
        Map<Id, Set<String>> leadtoParkTourMap = new Map<Id, Set<String>>();
        for (Id leadId : leadIdToLeadMap.keySet()) {
            for (Park_Tour__c tour : leadIdToLeadMap.get(leadId).Park_Tour__r) {
                Set<String> parkIdSet = leadtoParkTourMap.containsKey(leadId) ? leadtoParkTourMap.get(leadId) : new Set<String>();
                parkIdSet.add(tour.Adventure_Park__c);
                leadtoParkTourMap.put(leadId, parkIdSet);
            }
        }

        List<Park_Tour__c> toursForUpdate = new List<Park_Tour__c>();
        List<Park_Of_Interest__c> poiForUpdate = new List<Park_Of_Interest__c>();
        List<Contact> contactsForInsert = new List<Contact>();
        List<Contact> contactsForUpdate = new List<Contact>();
        List<OpportunityContactRole> oppRollsForInsert = new List<OpportunityContactRole>();
        List<OpportunityContactRole> oppRollsForUpdate = new List<OpportunityContactRole>();
        Map<Id, Id> newOppMap = new Map<Id, Id>();
        Map<Id, Id> newContactMap = new Map<Id, Id>();
        List<Opportunity> newOppsForUpdate = new List<Opportunity>();
        List<Account> newAcctsForUpdate = new List<Account>();
        Set<Id> taskToLeadIds = new Set<Id>();
        List<Task> tasksList = new List<Task>();
        Set<Id> convertedContactIds = new Set<Id>();

        for (Lead l : convertedLeads) {
            convertedContactIds.add(l.ConvertedContactId);
        }

        Set<String> taskSubjects = new Set<String>();
        for (String eachString : System.Label.Appointment_Task_Subjects.split(',')) {
            taskSubjects.add(eachString);
        }

        List<Task> taskList = [SELECT Id, WhoId, Subject FROM Task WHERE WhoId IN :convertedContactIds AND Subject IN :taskSubjects AND Status = 'Completed' AND ActivityDate <= LAST_N_DAYS:365];

        for (Lead lead : convertedLeads) {
            for (Task eachTask : taskList) {
                if (lead.Parks_Of_Interest__c != null || (leadtoParkTourMap != null && !leadtoParkTourMap.isEmpty())) {
                    taskToLeadIds.add(eachTask.Id);
                    if (!tasksList.contains(eachTask)) {
                        tasksList.add(eachTask);
                    }
                }
            }
        }

        for (Id lId : ids) {
            Id newAcctId;
            Id newConId;
            Id newOppId;
            Lead lead;

            for (Lead lead2 : convertedLeads) {
                if (lead2.Id == lId) {
                    lead = lead2;
                    newAcctId = lead2.ConvertedAccountId;
                    Account a = new Account(
                        Id = newAcctId,
                        Phone = lead2.Phone,
                        Email__c = lead2.Email);
                    newAcctsForUpdate.add(a);
                    newConId = lead2.ConvertedContactId;
                    newContactMap.put(newConId, lead2.Id);
                    if (lead2.ConvertedOpportunityId != null) {
                        newOppId = lead2.ConvertedOpportunityId;
                        newOppMap.put(newOppId, newAcctId);

                        Opportunity o = new Opportunity(Id = lead2.ConvertedOpportunityId);
                        o.Adventure_Timeframe__c = lead2.Adventure_Timeframe__c;
                        o.Household_Income__c = lead2.Household_Income__c;
                        o.Vendor_Segment_Id__c = lead2.Vendor_Segment_Id__c;
                        o.Created_from_Lead__c = true;

                        if (!newOppsForUpdate.contains(o)) {
                            newOppsForUpdate.add(o);
                        }
                    }
                    break;
                }
            }

            for (Park_Tour__c tour : leadIdToLeadMap.get(lId).Park_Tour__r) {
                if (tour.Lead__c == lId) {
                    tour.Lead__c = null;
                    tour.Contact__c = newConId;
                    if (newOppId != null) {
                        tour.Opportunity__c = newOppId;
                    }
                    toursForUpdate.add(tour);
                }
            }

            for (Park_Of_Interest__c poi : leadIdToLeadMap.get(lId).Parks_Of_Interest__r) {
                if (poi.Lead__c == lId) {
                    poi.Lead__c = null;
                    poi.Contact__c = newConId;
                    poiForUpdate.add(poi);
                }
            }
        }

        if (toursForUpdate.size() > 0) {
            update toursForUpdate;
        }

        if (newAcctsForUpdate.size() > 0) {
            update newAcctsForUpdate;
        }

        if (contactsForInsert.size() > 0) {
            insert contactsForInsert;
        }

        if (contactsForUpdate.size() > 0) {
            update contactsForUpdate;
        }

        if (newOppsForUpdate != null && !newOppsForUpdate.isEmpty() && newOppsForUpdate.size() > 0) {
            update newOppsForUpdate;
        }

        if (poiForUpdate.size() > 0) {
            update poiForUpdate;
        }

        if (newOppMap.size() > 0) {
            List<Contact> newCons = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :newOppMap.values()];
            List<OpportunityContactRole> newRoles = [SELECT Id, OpportunityId FROM OpportunityContactRole WHERE OpportunityId IN :newOppMap.keySet()];
            Integer i = 0;
            for (Id oppId : newOppMap.keySet()) {
                Id acctId = newOppMap.get(oppId);

                for (OpportunityContactRole oppRole : newRoles) {
                    if (oppRole.OpportunityId == oppId) {
                        oppRole.Role = 'Buyer';
                        oppRole.IsPrimary = true;
                        oppRollsForUpdate.add(oppRole);
                    }
                }
            }

            if (oppRollsForInsert.size() > 0) {
                insert oppRollsForInsert;
            }

            if (oppRollsForUpdate.size() > 0) {
                update oppRollsForUpdate;
            }
        }
    }
}