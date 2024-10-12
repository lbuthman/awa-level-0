public without sharing class ParkTourTrigger_Handler {
    @TestVisible private static final String    PROFILE_WALK_IN_FORM_SITE = 'Walk-In Form Site Profile',
        APPOINTMENT_TYPE_WALK_IN = 'User';

    public void onBeforeInsert(List<Park_Tour__c> newSiteVisits) {
        List<Park_Tour__c> siteVisitsForCommunityOfInterestRatingUpdate = new List<Park_Tour__c>();
        List<Park_Tour__c> siteVisitsToUpdateReturnVisitorAndMaybeAccountId = new List<Park_Tour__c>();
        for (Park_Tour__c newSiteVisit : newSiteVisits) {
            //When Community_of_Interest_Rating__c is not populated. Comes from Walk In Form
            if (newSiteVisit.Community_of_Interest_Rating__c == null) {
                siteVisitsForCommunityOfInterestRatingUpdate.add(newSiteVisit);
            }
            siteVisitsToUpdateReturnVisitorAndMaybeAccountId.add(newSiteVisit);
        }

        if (siteVisitsForCommunityOfInterestRatingUpdate.size() > 0) {
            Methods_SiteVisit.getCOIrating(siteVisitsForCommunityOfInterestRatingUpdate);
        }

        if (siteVisitsToUpdateReturnVisitorAndMaybeAccountId.size() > 0) {
            Methods_SiteVisit.checkNewVisitor(siteVisitsToUpdateReturnVisitorAndMaybeAccountId);
        }
    }

    public void onAfterInsert(List<Park_Tour__c> newList, Map<Id, Park_Tour__c> newVisitsMap) {
        List<Park_Tour__c> updateCOIList = new List<Park_Tour__c>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> communitySiteIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        //todo: I question the need for the Map<Id, SiteVisit__c>
        //      - validate in dependencies
        //      - refactor in Trigger
        for (Park_Tour__c newSiteVisit : newVisitsMap.values()) {
            if (newSiteVisit.Community_of_Interest_Rating__c != null && newSiteVisit.COI_Synced_on_Insert__c == false) {

                if (!updateCOIList.contains(newSiteVisit)) {
                    updateCOIList.add(newSiteVisit);
                }
            }
            if (newSiteVisit.Lead__c != null) {
                leadIds.add(newSiteVisit.Lead__c);
            }
            if (newSiteVisit.Community_Site__c != null) {
                communitySiteIds.add(newSiteVisit.Community_Site__c);
            }
            if (newSiteVisit.Contact__c != null) {
                contactIds.add(newSiteVisit.Contact__c);
            }
        }

        Set<Id> accountIds = new Set<Id>();
        Set<String> masterPlannedCommunitySiteNameSet = new Set<String>();
        Set<Id> masterPlannedCommunitySitesIdSet = new Set<Id>();
        collectMasterPlannedCommunities(communitySiteIds, masterPlannedCommunitySitesIdSet, masterPlannedCommunitySiteNameSet);
        collectAccountIdsBasedOnContacts(contactIds, accountIds);

        Map<Id, List<Contact>> accountIdToContacts = new Map<Id, List<Contact>>();
        //todo: interestingly first we use Contact Ids to collect Account Ids, then turn right around and
        //  use the Account Ids to collect Contacts ...
        collectAccountIdToContactsMap(accountIds, accountIdToContacts);

        List<Interest_List__c> communitiesOfInterestForUpdate = new List<Interest_List__c>();
        if (updateCOIList != null && !updateCOIList.isEmpty()) {
            communitiesOfInterestForUpdate = Methods_SiteVisit.updatCOIRating(updateCOIList);
        }

        if (!TaskTriggerHandler.isRunningOnceForLead && !newVisitsMap.isEmpty() && leadIds.size() > 0) {
            enqueueLeadOwnerNHAQueueable(leadIds, communitySiteIds);
        }

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        if (!TaskTriggerHandler.isRunningOnceForContact &&
            newVisitsMap != null &&
            !newVisitsMap.isEmpty() &&
            (newVisitsMap != null || (masterPlannedCommunitySiteNameSet != null && !masterPlannedCommunitySiteNameSet.isEmpty()))
        ) {
            opportunitiesToInsert = Methods_SiteVisit.createOpportunityUnderContact(Trigger.new, masterPlannedCommunitySiteNameSet);
        }

        Set<Opportunity> opportunities = new Set<Opportunity>();
        for (Opportunity opportunity : opportunitiesToInsert) {
            opportunities.add(opportunity);
        }

        if (opportunitiesToInsert != null && !opportunitiesToInsert.isEmpty()) {
            insert new List<Opportunity>(opportunities);
        }

        if (communitiesOfInterestForUpdate != null && !communitiesOfInterestForUpdate.isEmpty()) {
            update communitiesOfInterestForUpdate;
        }

        if (checkRecursive.isViceVersaCreation) {
            createServiceAppointmentFromWalkInForm(newList, newVisitsMap);
        }
        else if (!checkRecursive.isViceVersaCreation) {
            createServiceAppointment(newList, newVisitsMap);
        }
        updateServiceAppointmentLookupAfterInsertSiteVisit(newList, newVisitsMap);
    }

    private static void enqueueLeadOwnerNHAQueueable(Set<Id> leadIdSet, Set<Id> communitySiteIdSet) {
        String jsonString = JSON.serialize(Trigger.new);
        if (!Methods_SiteVisit.leadOwnerNHAFutureCalled) {
            leadOwnerNHAQueueable queueableLeadOwnerNha = new leadOwnerNHAQueueable(jsonString, leadIdSet, communitySiteIdSet);
            System.enqueueJob(queueableLeadOwnerNha);
            Methods_SiteVisit.leadOwnerNHAFutureCalled = true;
        }
    }

    private static void collectMasterPlannedCommunities(Set<Id> comSites, Set<Id> masterPlannedCommunities, Set<String> masterPlanCommSite) {
        if (comSites != null && !comSites.isEmpty()) {
            for (Community_Site__c commumitySite : [
                SELECT Id, Name, Master_Plan_Community__c, Master_Planned_Community__c
                FROM Community_Site__c
                WHERE Id IN :comSites
            ]) {
                if (commumitySite.Master_Planned_Community__c != null) {
                    masterPlannedCommunities.add(commumitySite.Master_Planned_Community__c);
                }
            }
            //todo: ignoring intra-class duplicate code fragments for now
            if (masterPlannedCommunities != null && !masterPlannedCommunities.isEmpty()) {
                for (Master_Planned_Community__c masterPlanComm : [
                    SELECT Id, Name, (SELECT Id, Name FROM Community_Sites__r)
                    FROM Master_Planned_Community__c
                    WHERE Id IN :masterPlannedCommunities
                ]) {
                    if (masterPlanComm.Community_Sites__r != null && !masterPlanComm.Community_Sites__r.isEmpty()) {
                        for (Community_Site__c sitesUnderMasterPlan : masterPlanComm.Community_Sites__r) {
                            masterPlanCommSite.add(sitesUnderMasterPlan.Name.toLowerCase());
                        }
                    }
                }
            }
        }
    }

    private static void collectAccountIdsBasedOnContacts(Set<Id> contactIds, Set<Id> accountIds) {
        if (contactIds != null && !contactIds.isEmpty()) {
            for (Contact contact : [SELECT Id, Name, AccountId FROM Contact WHERE Id IN :contactIds]) {
                accountIds.add(contact.AccountId);
            }
        }
    }

    private static void collectAccountIdToContactsMap(Set<Id> accountIds, Map<Id, List<Contact>> accountToContactsMap) {
        if (accountIds != null && !accountIds.isEmpty()) {
            for (Contact contact : [SELECT Id, Name, AccountId FROM Contact WHERE AccountId IN :accountIds]) {

                //todo: ignoring intra-class duplicate code fragments for now
                if (accountToContactsMap != null &&
                    accountToContactsMap.containsKey(contact.AccountId) &&
                    accountToContactsMap.get(contact.AccountId) != null
                ) {
                    List<Contact> tempCon = accountToContactsMap.get(contact.AccountId);
                    tempCon.add(contact);
                    accountToContactsMap.put(contact.AccountId, tempCon);
                }
                else {
                    accountToContactsMap.put(contact.AccountId, new List<Contact>{
                        contact
                    });
                }
            }
        }
    }

    //CM Sales Scheduler - Creating a ServiceAppointment through the WalkIn form
    private static void createServiceAppointmentFromWalkInForm(
        List<Park_Tour__c> newSiteVisits, Map<Id, Park_Tour__c> siteVisitIdToNewSiteVisits
    ) {

        if (checkRecursive.isViceVersaCreation) {
            List<Park_Tour__c> siteVisitsFromWalkInForm = [
                SELECT Id, CreatedBy.FirstName, CreatedBy.LastName, Agent_Account__c
                FROM Park_Tour__c
                WHERE Id IN :siteVisitIdToNewSiteVisits.keySet()
                AND CreatedBy.FirstName = 'Walk-In Form'
                AND CreatedBy.LastName = 'Guest User'
            ];
            List<Park_Tour__c> siteVisitsByIds = new List<Park_Tour__c>();
            for (Park_Tour__c siteVisit : newSiteVisits) {
                for (Park_Tour__c walkInSiteVisit : siteVisitsFromWalkInForm) {
                    if (siteVisit.Id == walkInSiteVisit.Id) {
                        siteVisitsByIds.add(siteVisit);
                    }
                }
            }

            if (!siteVisitsByIds.isEmpty() && checkRecursive.isViceVersaCreation) {
                checkRecursive.isViceVersaCreation = false;
                createServiceAppointment(siteVisitsByIds, siteVisitIdToNewSiteVisits);
            }
        }
    }

    public void onAfterUpdate(Map<Id, Park_Tour__c> newMap, Map<Id, Park_Tour__c> oldMap) {
        List<Park_Tour__c> updateCOIList = new List<Park_Tour__c>();
        List<Interest_List__c> coisForUpdate = new List<Interest_List__c>();
        for (Park_Tour__c sv : newMap.values()) {
            Park_Tour__c oldSV = oldMap.get(sv.Id);
            if (sv.Community_of_Interest_Rating__c != oldSV.Community_of_Interest_Rating__c ||
                sv.Community_of_Interest_Inactive_Reason__c != oldSV.Community_of_Interest_Inactive_Reason__c) {
                if (!updateCOIList.contains(sv)) {
                    updateCOIList.add(sv);
                }
            }
        }

        if (updateCOIList != null && !updateCOIList.isEmpty()) {
            coisForUpdate = Methods_SiteVisit.updatCOIRating(updateCOIList);
        }

        if (coisForUpdate != null && !coisForUpdate.isEmpty()) {
            update coisForUpdate;
        }

        Set<Id> leadIds = new Set<Id>();
        Set<Id> comSites = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Contact>> accountToContactsMap = new Map<Id, List<Contact>>();
        List<Opportunity> oppToInsert = new List<Opportunity>();
        Set<String> masterPlanCommSite = new Set<String>();
        Set<Id> masterPlannedCommunities = new Set<Id>();
        Boolean doNotUpdate = false;

        for (Park_Tour__c sv : newMap.values()) {
            if (sv.Lead__c != null) {
                leadIds.add(sv.Lead__c);
            }
            if (sv.Community_Site__c != null) {
                comSites.add(sv.Community_Site__c);
            }
            if (sv.Contact__c != null) {
                contactIds.add(sv.Contact__c);
            }
            if (sv.CreatedDate.date() != sv.LastModifiedDate.date()) {
                doNotUpdate = true;
            }
        }

        if (!doNotUpdate) {
            collectMasterPlannedCommunities(comSites, masterPlannedCommunities, masterPlanCommSite);
            collectAccountIdsBasedOnContacts(contactIds, accountIds);
            //todo: see note on previous code
            collectAccountIdToContactsMap(accountIds, accountToContactsMap);

            //Convert Lead automatically when site visit recorded
            if (!TaskTriggerHandler.isRunningOnceForLead && !newMap.isEmpty() && leadIds.size() > 0) {
                enqueueLeadOwnerNHAQueueable(leadIds, comSites);
            }

            if (!TaskTriggerHandler.isRunningOnceForContact &&
                newMap != null &&
                !newMap.isEmpty() &&
                (newMap != null || (masterPlanCommSite != null && !masterPlanCommSite.isEmpty()))
            ) {
                oppToInsert = Methods_SiteVisit.createOpportunityUnderContact(Trigger.new, masterPlanCommSite);
            }

            if (oppToInsert != null && !oppToInsert.isEmpty() && !checkRecursive.isViceVersaCreation) {
                insert oppToInsert;
            }
        }
        checkRecursive.isViceVersaCreation = false;
        updateServiceAppointment(newMap, oldMap);
    }

    public void onBeforeDelete(Map<Id, Park_Tour__c> oldMap) {
        deleteExistingServiceAppointments(oldMap);
    }

    //CM Sales Scheduler - Updating the SiteVisit lookup field on a ServiceAppointment object
    // when inserting a SiteVisit that has the ServiceAppointment lookup field filled in
    private static void updateServiceAppointmentLookupAfterInsertSiteVisit(
        List<Park_Tour__c> newList, Map<Id, Park_Tour__c> newMap) {

        if (checkRecursive.isViceVersaCreation) {
            Set<Id> serviceAppointmentIds = new Set<Id>();
            for (Park_Tour__c siteVisit : newList) {
                if (siteVisit.Service_Appointment__c != null) {
                    serviceAppointmentIds.add(siteVisit.Service_Appointment__c);
                }
            }

            List<ServiceAppointment> serviceAppointments = [
                SELECT Id, Park_Tour__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds
            ];

            if (!serviceAppointments.isEmpty()) {
                for (Park_Tour__c siteVisit : newList) {
                    for (ServiceAppointment serviceAppointment : serviceAppointments) {
                        if (siteVisit.Service_Appointment__c == serviceAppointment.Id) {
                            serviceAppointment.Park_Tour__c = siteVisit.Id;
                        }
                    }
                }
            }

            if (!serviceAppointments.isEmpty()) update serviceAppointments;
        }

    }

    //todo: Todd, can the Task related code be removed here?
    //CM Sales Scheduler - Creating a ServiceAppointment.
    // If the inserted SiteVisit has a populated lookup field ServiceAppointment, the method updates related ServiceAppointment object
    public static void createServiceAppointment(List<Park_Tour__c> newList, Map<Id, Park_Tour__c> newMap) {
        if (!checkRecursive.isViceVersaCreation) {
            checkRecursive.isViceVersaCreation = true;

            List<Task> existingTasksWithServiceAppointment = getExistingTaskOnSiteVisit(newMap);
            List<ServiceAppointment> existingServiceAppointmentsOnTask =
                getExistingServiceAppOnTask(existingTasksWithServiceAppointment);
            Map<Id, ServiceAppointment> existingServiceAppointmentsForLeadOrContact =
                getExistingServiceAppointmentsForLeadOrContact(newList);

            List<ServiceAppointment> existingAppointmentsOnSiteVisit = getExistingServiceAppointmentOnSiteVisit(newMap);
            List<Task> existingTaskWithSerApp = getExistingTaskOnAppointment(existingAppointmentsOnSiteVisit);
            Map<Id, User> mapUserById = getCreatedByUsers(newList);
            Map<Id, ServiceTerritory> mapServiceTerritoryByCommuniteSiteId = getServiceTerritoryByCommunitySiteId(newList);

            List<ServiceAppointment> sAppsToCreate = new List<ServiceAppointment>();
            List<ServiceAppointment> sAppsToUpdate = new List<ServiceAppointment>();
            List<Task> tasksToUpdate = new List<Task>();
            for (Park_Tour__c siteVisit : newList) {
                if (!existingTaskWithSerApp.isEmpty() &&
                    !existingAppointmentsOnSiteVisit.isEmpty() &&
                    siteVisit.Service_Appointment__c != null
                ) {
                    for (ServiceAppointment serviceAppointment : existingAppointmentsOnSiteVisit) {
                        if (siteVisit.Service_Appointment__c == serviceAppointment.Id) {
                            serviceAppointment = populateExistingServiceAppointment(siteVisit, serviceAppointment);
                            sAppsToUpdate.add(serviceAppointment);
                        }
                    }
                    for (Task task : existingTaskWithSerApp) {
                        if (siteVisit.Service_Appointment__c == task.Service_Appointment__c) {
                            task.Site_Visit_Id__c = siteVisit.Id;
                            tasksToUpdate.add(task);
                        }
                    }
                }
                else if (siteVisit.Task_Id__c != null &&
                    !existingTasksWithServiceAppointment.isEmpty() &&
                    !existingServiceAppointmentsOnTask.isEmpty()
                ) {
                    for (ServiceAppointment serviceAppointment : existingServiceAppointmentsOnTask) {
                        if (siteVisit.Task_Id__c == serviceAppointment.Task_Id__c) {
                            serviceAppointment = populateExistingServiceAppointment(siteVisit, serviceAppointment);
                            sAppsToUpdate.add(serviceAppointment);
                        }
                    }
                }
                else {
                    if (existingServiceAppointmentsForLeadOrContact.containsKey(siteVisit.Id)) {
                        ServiceAppointment serviceAppointment = new ServiceAppointment();
                        serviceAppointment = existingServiceAppointmentsForLeadOrContact.get(siteVisit.Id);
                        String appointmentType = serviceAppointment.AppointmentType;
                        serviceAppointment = populateExistingServiceAppointment(siteVisit, serviceAppointment);
                        serviceAppointment.Bypass_Date_Time__c = Datetime.now().addMinutes(1);
                        serviceAppointment.AppointmentType = appointmentType;
                        sAppsToUpdate.add(serviceAppointment);
                        checkRecursive.isViceVersaCreation = false;
                    }
                    else {
                        User thisUser = mapUserById.get(siteVisit.CreatedById);
                        ServiceTerritory thisServiceTerritory =
                            mapServiceTerritoryByCommuniteSiteId.get(siteVisit.Community_Site__c);
                        sAppsToCreate.add(populateServiceAppOnCreation(siteVisit, thisUser, thisServiceTerritory));
                    }
                }
            }

            if (!sAppsToCreate.isEmpty()) {
                insert sAppsToCreate;
            }
            if (!sAppsToUpdate.isEmpty()) {
                update sAppsToUpdate;
            }
            if (!tasksToUpdate.isEmpty()) {
                update tasksToUpdate;
            }
        }

    }

    //CM Sales Scheduler - Getting an existing ServiceAppointment for Lead or Contact
    private static Map<Id, ServiceAppointment> getExistingServiceAppointmentsForLeadOrContact(List<Park_Tour__c> siteVisits) {
        Set<Id> parentRecordIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Park_Tour__c siteVisit : siteVisits) {
            if (siteVisit.Account__c != null) {
                parentRecordIds.add(siteVisit.Account__c);
            }
            else {
                parentRecordIds.add(siteVisit.Lead__c);
            }
            if (siteVisit.Contact__c != null) {
                contactIds.add(siteVisit.Contact__c);
            }
        }

        List<ServiceAppointment> existingAppointments = [
            SELECT Id, Park_Tour__c, SchedStartTime, ActualStartTime, COI_Synced_on_Insert__c, Agent_at_First_Visit__c,
                AccountId, Community_of_Interest_Inactive_Reason__c, Community_of_Interest_Rating__c, Agent_Account__c,
                ParentRecordId, NHA__c, NHS__c, Community_Site__c, ServiceNote, Return_Visitor__c, Status, Task_Id__c,
                AppointmentType, Virtual_Tour__c, ContactId, Appointment_Category__c
            FROM ServiceAppointment
            WHERE (ParentRecordId IN :parentRecordIds OR ContactId IN :contactIds)
            AND (AppointmentType = 'In Person' OR AppointmentType = 'Virtual' OR AppointmentType = '')
        ];


        Map<Id, ServiceAppointment> siteVisitToServiceAppointmentMap = new Map<Id, ServiceAppointment>();
        for (ServiceAppointment serviceAppointment : existingAppointments) {
            for (Park_Tour__c siteVisit : siteVisits) {
                if ((siteVisit.Lead__c == serviceAppointment.ParentRecordId ||
                    siteVisit.Account__c == serviceAppointment.ParentRecordId ||
                    siteVisit.Contact__c == serviceAppointment.ContactId) &&
                    siteVisit.Community_Site__c == serviceAppointment.Community_Site__c &&
                    siteVisit.Arrival_Time__c.date() == serviceAppointment.SchedStartTime.date()) {
                    siteVisitToServiceAppointmentMap.put(siteVisit.Id, serviceAppointment);
                }
            }
        }

        return siteVisitToServiceAppointmentMap;
    }

    //CM Sales Scheduler - Updating related ServiceAppointment to the SiteVisit object
    public static void updateServiceAppointment(Map<Id, Park_Tour__c> newMap, Map<Id, Park_Tour__c> oldMap) {

        if (!checkRecursive.isViceVersaCreation) {
            checkRecursive.isViceVersaCreation = true;

            Map<Id, List<ServiceAppointment>> serviceAppToRelatedSVisits = getSiteVisitToServiceAppointmentsMap(newMap);

            List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();

            for (Park_Tour__c currSiteVisit : newMap.values()) {
                Park_Tour__c oldSiteVisit = oldMap.get(currSiteVisit.Id);
                if (serviceAppToRelatedSVisits.containsKey(currSiteVisit.Id)) {
                    for (ServiceAppointment serviceAppointment : serviceAppToRelatedSVisits.get(currSiteVisit.Id)) {
                        serviceAppointment =
                            populateExistingServiceAppointment(currSiteVisit, serviceAppointment, oldSiteVisit);
                        serviceAppointmentsToUpdate.add(serviceAppointment);
                    }
                }
            }

            if (!serviceAppointmentsToUpdate.isEmpty()) update serviceAppointmentsToUpdate;

        }

    }

    //CM Sales Scheduler - Deleting related ServiceAppointment to the SiteVisit object
    public static void deleteExistingServiceAppointments(Map<Id, Park_Tour__c> oldMap) {
        if (!checkRecursive.isViceVersaCreation) {
            checkRecursive.isViceVersaCreation = true;

            List<ServiceAppointment> existingServiceAppointments = getExistingServiceAppointment(oldMap);
            Set<ServiceAppointment> serviceAppointmentsForDelete = new Set<ServiceAppointment>();
            List<Task> existingRelatedTasks = getExistingRelatedTasksToServiceAppointments(existingServiceAppointments);

            for (ServiceAppointment serviceAppointment : existingServiceAppointments) {
                if (!existingRelatedTasks.isEmpty()) {
                    for (Task relatedTask : existingRelatedTasks) {
                        if (serviceAppointment.Id != relatedTask.Service_Appointment__c) {
                            serviceAppointmentsForDelete.add(serviceAppointment);
                        }
                    }
                }
                else {
                    serviceAppointmentsForDelete.add(serviceAppointment);
                }
            }

            if (!serviceAppointmentsForDelete.isEmpty()) {
                delete new List<ServiceAppointment>(serviceAppointmentsForDelete);
            }
        }

    }

    //CM Sales Scheduler - Populating new ServiceAppointment based on SiteVisit object
    private static ServiceAppointment populateServiceAppOnCreation(
        Park_Tour__c siteVisit, User thisUser, ServiceTerritory thisServiceTerritory
    ) {
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            SchedStartTime = siteVisit.Appointment_Date_Time__c,
            ActualStartTime = siteVisit.Arrival_Time__c,
            COI_Synced_on_Insert__c = siteVisit.COI_Synced_on_Insert__c,
            Community_of_Interest_Inactive_Reason__c = siteVisit.Community_of_Interest_Inactive_Reason__c,
            Community_of_Interest_Rating__c = siteVisit.Community_of_Interest_Rating__c,
            Community_Site__c = siteVisit.Community_Site__c,
            ServiceNote = siteVisit.Notes__c,
            Return_Visitor__c = siteVisit.Return_Visitor__c,
            Park_Tour__c = siteVisit.Id,
            CreatedById = siteVisit.CreatedById,
            ParentRecordId = siteVisit.Lead__c,
            AppointmentType = 'User',
            Agent_Account__c = siteVisit.Agent_Account__c,
            Agent_at_First_Visit__c = siteVisit.First_Visit_With_Agent__c,
            NHA__c = siteVisit.New_Home_Advisor__c
        );

        if (siteVisit.Account__c != null) {
            serviceAppointment.ParentRecordId = siteVisit.Account__c;
        }

        if (siteVisit.Contact__c != null) {
            serviceAppointment.ContactId = siteVisit.Contact__c;
        }

        if (siteVisit.Lead__c != null &&
            siteVisit.Contact__c == null) {

            serviceAppointment.Lead__c = siteVisit.Lead__c;
        }

        if (siteVisit.Virtual_Tour__c == true) serviceAppointment.AppointmentType = 'Virtual';

        checkIfSiteVisitFromIpadRegistration(siteVisit, serviceAppointment, thisUser, thisServiceTerritory);

        return serviceAppointment;
    }

    //CM Sales Scheduler - Checking if SiteVisit is inserted through WalkIn form
    @TestVisible
    private static void checkIfSiteVisitFromIpadRegistration(
        Park_Tour__c siteVisit, ServiceAppointment serviceAppointment, User thisUser, ServiceTerritory thisServiceTerritory
    ) {
        if (thisUser?.Profile?.Name == PROFILE_WALK_IN_FORM_SITE) {
            serviceAppointment.Status = 'Completed';
            serviceAppointment.NHA__c = siteVisit.New_Home_Advisor__c;
            serviceAppointment.Appointment_Category__c = 'Home Tour';
            serviceAppointment.OwnerId = siteVisit.New_Home_Advisor__c;

            if (thisServiceTerritory != null) {
                serviceAppointment.ServiceTerritoryId = thisServiceTerritory.Id;
                serviceAppointment.Street = thisServiceTerritory.Street;
                serviceAppointment.City = thisServiceTerritory.City;
                serviceAppointment.State = thisServiceTerritory.State;
                serviceAppointment.StateCode = thisServiceTerritory.StateCode;
                serviceAppointment.PostalCode = thisServiceTerritory.PostalCode;
                serviceAppointment.Country = thisServiceTerritory.Country;
                serviceAppointment.CountryCode = thisServiceTerritory.CountryCode;
            }

        }
        else {
            serviceAppointment.Status = 'Completed';
        }
    }

    //CM Sales Scheduler - Populating existing related ServiceAppointment on SiteVisit updating
    @TestVisible
    private static ServiceAppointment populateExistingServiceAppointment(
        Park_Tour__c currSiteVisit, ServiceAppointment serviceAppointment
    ) {
        return populateExistingServiceAppointment(currSiteVisit, serviceAppointment, null);
    }

    @TestVisible
    private static ServiceAppointment populateExistingServiceAppointment(
        Park_Tour__c currSiteVisit, ServiceAppointment serviceAppointment, Park_Tour__c oldSiteVisit
    ) {

        if (serviceAppointment.SchedStartTime != currSiteVisit.Appointment_Date_Time__c &&
            currSiteVisit.Appointment_Date_Time__c != null
        ) {
            serviceAppointment.SchedStartTime = currSiteVisit.Appointment_Date_Time__c;
        }
        if (serviceAppointment.ActualStartTime != currSiteVisit.Arrival_Time__c) {
            serviceAppointment.ActualStartTime = currSiteVisit.Arrival_Time__c;
        }
        if (serviceAppointment.COI_Synced_on_Insert__c != currSiteVisit.COI_Synced_on_Insert__c) {
            serviceAppointment.COI_Synced_on_Insert__c = currSiteVisit.COI_Synced_on_Insert__c;
        }
        if (serviceAppointment.Community_of_Interest_Inactive_Reason__c != currSiteVisit.Community_of_Interest_Inactive_Reason__c
        ) {
            serviceAppointment.Community_of_Interest_Inactive_Reason__c = currSiteVisit.Community_of_Interest_Inactive_Reason__c;
        }
        if (serviceAppointment.Community_of_Interest_Rating__c != currSiteVisit.Community_of_Interest_Rating__c) {
            serviceAppointment.Community_of_Interest_Rating__c = currSiteVisit.Community_of_Interest_Rating__c;
        }
        if (serviceAppointment.Community_Site__c != currSiteVisit.Community_Site__c) {
            serviceAppointment.Community_Site__c = currSiteVisit.Community_Site__c;
        }
        if (serviceAppointment.ServiceNote != currSiteVisit.Notes__c) {
            serviceAppointment.ServiceNote = currSiteVisit.Notes__c;
        }
        if (serviceAppointment.Return_Visitor__c != currSiteVisit.Return_Visitor__c) {
            serviceAppointment.Return_Visitor__c = currSiteVisit.Return_Visitor__c;
        }
        if (serviceAppointment.Status != currSiteVisit.Status__c) {
            serviceAppointment.Status = currSiteVisit.Status__c;
        }

        if (serviceAppointment.Agent_Account__c != currSiteVisit.Agent_Account__c) {
            serviceAppointment.Agent_Account__c = currSiteVisit.Agent_Account__c;
        }

        if (serviceAppointment.Agent_at_First_Visit__c != currSiteVisit.First_Visit_With_Agent__c) {
            serviceAppointment.Agent_at_First_Visit__c = currSiteVisit.First_Visit_With_Agent__c;
        }

        if (serviceAppointment.Park_Tour__c != currSiteVisit.Id) {
            serviceAppointment.Park_Tour__c = currSiteVisit.Id;
        }

        if (serviceAppointment.NHA__c != currSiteVisit.New_Home_Advisor__c) {
            serviceAppointment.NHA__c = currSiteVisit.New_Home_Advisor__c;
        }

        if (serviceAppointment.ContactId != currSiteVisit.Contact__c) {
            serviceAppointment.ContactId = currSiteVisit.Contact__c;
        }

        if (serviceAppointment.ContactId != null &&
            serviceAppointment.Lead__c != null) {
            serviceAppointment.Lead__c = null;
        }

        if (currSiteVisit.Opportunity__c != null &&
            currSiteVisit.Opportunity__c != oldSiteVisit?.Opportunity__c &&
            serviceAppointment.AppointmentType != APPOINTMENT_TYPE_WALK_IN
        ) {

            serviceAppointment.Opportunity__c = currSiteVisit.Opportunity__c;
        }

        return serviceAppointment;
    }

    //CM Sales Scheduler - Getting SiteVisit Id to related ServiceAppointment map
    private static Map<Id, List<ServiceAppointment>> getSiteVisitToServiceAppointmentsMap(Map<Id, Park_Tour__c> newMap) {
        List<ServiceAppointment> existingServiceAppointments = getExistingServiceAppointment(newMap);
        Map<Id, List<ServiceAppointment>> siteVisitToServiceAppointmentsMap = new Map<Id, List<ServiceAppointment>>();
        for (ServiceAppointment serviceAppointment : existingServiceAppointments) {
            if (siteVisitToServiceAppointmentsMap.containsKey(serviceAppointment.Park_Tour__c)) {
                siteVisitToServiceAppointmentsMap.get(serviceAppointment.Park_Tour__c).add(serviceAppointment);
            }
            else {
                siteVisitToServiceAppointmentsMap.put(serviceAppointment.Park_Tour__c, new List<ServiceAppointment>{
                    serviceAppointment
                });
            }
        }
        return siteVisitToServiceAppointmentsMap;
    }

    //CM Sales Scheduler - Getting existing related Tasks to ServiceAppointment
    //todo: Todd, check to see if removable
    private static List<Task> getExistingRelatedTasksToServiceAppointments(List<ServiceAppointment> serviceAppointments) {

        Set<Id> serviceAppointmentsIds = new Set<Id>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointmentsIds.add(serviceAppointment.Id);
        }

        List<Task> existingTasks = [
            SELECT Id, Service_Appointment__c
            FROM Task
            WHERE Service_Appointment__c IN :serviceAppointmentsIds
        ];

        return existingTasks;
    }

    //CM Sales Scheduler - Getting existing related ServiceAppointments to SiteVisit object
    private static List<ServiceAppointment> getExistingServiceAppointment(Map<Id, Park_Tour__c> newMap) {
        Set<Id> siteVisitId = newMap.keySet();

        List<ServiceAppointment> existingServiceAppointments = [
            SELECT Id, Park_Tour__c, SchedStartTime, ActualStartTime, COI_Synced_on_Insert__c, Agent_at_First_Visit__c,
                Community_of_Interest_Inactive_Reason__c, Community_of_Interest_Rating__c, Agent_Account__c, NHA__c,
                NHS__c, Community_Site__c, ServiceNote, Return_Visitor__c, Status, Task_Id__c, AppointmentType,
                Virtual_Tour__c, ContactId, Lead__c, Appointment_Category__c
            FROM ServiceAppointment
            WHERE Park_Tour__c IN :siteVisitId
        ];
        return existingServiceAppointments;
    }

    //CM Sales Scheduler - Getting existing related ServiceAppointments to SiteVisit object
    // based on ServiceAppointment lookup field on SiteVisit object
    private static List<ServiceAppointment> getExistingServiceAppointmentOnSiteVisit(Map<Id, Park_Tour__c> newMap) {
        Set<Id> sAppIds = new Set<Id>();

        for (Park_Tour__c siteVisit : newMap.values()) {
            sAppIds.add(siteVisit.Service_Appointment__c);
        }

        List<ServiceAppointment> existingServiceAppointments = [
            SELECT Id, Park_Tour__c, SchedStartTime, ActualStartTime, COI_Synced_on_Insert__c, Agent_at_First_Visit__c,
                Community_of_Interest_Inactive_Reason__c, Community_of_Interest_Rating__c, Agent_Account__c, NHA__c,
                NHS__c, Community_Site__c, ServiceNote, Return_Visitor__c, Status, Task_Id__c, AppointmentType,
                Virtual_Tour__c, ContactId, Lead__c, Appointment_Category__c
            FROM ServiceAppointment
            WHERE Id IN :sAppIds
        ];
        return existingServiceAppointments;
    }

    //CM Sales Scheduler - Getting existing related Tasks to SiteVisit object
    //todo: Todd, and here
    private static List<Task> getExistingTaskOnSiteVisit(Map<Id, Park_Tour__c> newMap) {
        Set<Id> taskIds = new Set<Id>();
        for (Park_Tour__c siteVisit : newMap.values()) {
            if (siteVisit.Task_Id__c != null) {
                taskIds.add(siteVisit.Task_Id__c);
            }
        }

        List<Task> existingTask = [SELECT Id, Service_Appointment__c FROM Task WHERE Id IN :taskIds];

        return existingTask;
    }

    //CM Sales Scheduler - Getting existing related ServiceAppointments to SiteVisit object
    // based on ServiceAppointment field on Task object
    private static List<ServiceAppointment> getExistingServiceAppOnTask(List<Task> tasks) {
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (Task task : tasks) {
            if (task.Service_Appointment__c != null) {
                serviceAppointmentIds.add(task.Service_Appointment__c);
            }
        }

        List<ServiceAppointment> existingServiceAppointments = [
            SELECT Id, Park_Tour__c, SchedStartTime, ActualStartTime, COI_Synced_on_Insert__c, Agent_at_First_Visit__c,
                Community_of_Interest_Inactive_Reason__c, Community_of_Interest_Rating__c, Agent_Account__c, NHA__c,
                NHS__c, Community_Site__c, ServiceNote, Return_Visitor__c, Status, Task_Id__c, AppointmentType,
                Virtual_Tour__c, ContactId, Lead__c, Appointment_Category__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ];

        return existingServiceAppointments;

    }

    //CM Sales Scheduler - Getting existing related Tasks to ServiceAppointment object
    //todo: Todd, and here
    private static List<Task> getExistingTaskOnAppointment(List<ServiceAppointment> serviceAppointments) {
        Set<Id> serAppIds = new Set<Id>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serAppIds.add(serviceAppointment.Id);
        }

        List<Task> existTask = [SELECT Id, Service_Appointment__c FROM Task WHERE Service_Appointment__c IN :serAppIds];

        return existTask;

    }

    //CM Sales Scheduler - Getting CreatedBy SiteVisit users
    private static Map<Id, User> getCreatedByUsers(List<Park_Tour__c> listSiteVisits) {
        Set<Id> setUserIds = new Set<Id>();
        for (Park_Tour__c thisSiteVisit : listSiteVisits) {
            setUserIds.add(thisSiteVisit.CreatedById);
        }
        List<User> listUsers = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Id IN :setUserIds];
        return new Map<Id, User>(listUsers);
    }

    //CM Sales Scheduler - Getting CommunitySite Id to ServiceTerritory map
    // based on populated Community_Site__c field on SiteVisit object
    private static Map<Id, ServiceTerritory> getServiceTerritoryByCommunitySiteId(List<Park_Tour__c> listSiteVisits) {
        Set<Id> setCommunitSiteIds = new Set<Id>();
        Map<Id, ServiceTerritory> mapServiceTerritoryByCommunityId = new Map<Id, ServiceTerritory>();
        for (Park_Tour__c thisSiteVisit : listSiteVisits) {
            setCommunitSiteIds.add(thisSiteVisit.Community_Site__c);
        }
        for (ServiceTerritory thisServiceTerritory : [
            SELECT Id, Community_Site__c, Street, City, State, StateCode, PostalCode, Country, CountryCode
            FROM ServiceTerritory
            WHERE Community_Site__c IN :setCommunitSiteIds
        ]) {
            mapServiceTerritoryByCommunityId.put(thisServiceTerritory.Community_Site__c, thisServiceTerritory);
        }
        return mapServiceTerritoryByCommunityId;
    }
}
