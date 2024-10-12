public without sharing class ParkTourTrigger_Handler {

    public void onBeforeInsert(List<Park_Tour__c> newSiteVisits) {
        List<Park_Tour__c> siteVisitsForCommunityOfInterestRatingUpdate = new List<Park_Tour__c>();
        List<Park_Tour__c> siteVisitsToUpdateReturnVisitorAndMaybeAccountId = new List<Park_Tour__c>();
        for (Park_Tour__c newSiteVisit : newSiteVisits) {
            //When Park_Interest_Rating__c is not populated. Comes from Walk In Form
            if (newSiteVisit.Park_Interest_Rating__c == null) {
                siteVisitsForCommunityOfInterestRatingUpdate.add(newSiteVisit);
            }
            siteVisitsToUpdateReturnVisitorAndMaybeAccountId.add(newSiteVisit);
        }

        if (siteVisitsForCommunityOfInterestRatingUpdate.size() > 0) {
            ParkTourTrigger_Helper.getCOIrating(siteVisitsForCommunityOfInterestRatingUpdate);
        }

        if (siteVisitsToUpdateReturnVisitorAndMaybeAccountId.size() > 0) {
            ParkTourTrigger_Helper.checkNewVisitor(siteVisitsToUpdateReturnVisitorAndMaybeAccountId);
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
            if (newSiteVisit.Park_Interest_Rating__c != null && newSiteVisit.POI_Synced_On_Insert__c == false) {

                if (!updateCOIList.contains(newSiteVisit)) {
                    updateCOIList.add(newSiteVisit);
                }
            }
            if (newSiteVisit.Lead__c != null) {
                leadIds.add(newSiteVisit.Lead__c);
            }
            if (newSiteVisit.Adventure_Park__c != null) {
                communitySiteIds.add(newSiteVisit.Adventure_Park__c);
            }
            if (newSiteVisit.Contact__c != null) {
                contactIds.add(newSiteVisit.Contact__c);
            }
        }

        Set<Id> accountIds = new Set<Id>();
        Set<String> masterPlannedCommunitySiteNameSet = new Set<String>();
        collectAccountIdsBasedOnContacts(contactIds, accountIds);

        Map<Id, List<Contact>> accountIdToContacts = new Map<Id, List<Contact>>();
        //todo: interestingly first we use Contact Ids to collect Account Ids, then turn right around and
        //  use the Account Ids to collect Contacts ...
        collectAccountIdToContactsMap(accountIds, accountIdToContacts);

        List<Park_Of_Interest__c> communitiesOfInterestForUpdate = new List<Park_Of_Interest__c>();
        if (updateCOIList != null && !updateCOIList.isEmpty()) {
            communitiesOfInterestForUpdate = ParkTourTrigger_Helper.updatCOIRating(updateCOIList);
        }

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        if (newVisitsMap != null &&
            !newVisitsMap.isEmpty() &&
            (newVisitsMap != null || (masterPlannedCommunitySiteNameSet != null && !masterPlannedCommunitySiteNameSet.isEmpty()))
        ) {
            opportunitiesToInsert = ParkTourTrigger_Helper.createOpportunityUnderContact(Trigger.new, masterPlannedCommunitySiteNameSet);
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

    public void onAfterUpdate(Map<Id, Park_Tour__c> newMap, Map<Id, Park_Tour__c> oldMap) {
        List<Park_Tour__c> updateCOIList = new List<Park_Tour__c>();
        List<Park_Of_Interest__c> coisForUpdate = new List<Park_Of_Interest__c>();
        for (Park_Tour__c sv : newMap.values()) {
            Park_Tour__c oldSV = oldMap.get(sv.Id);
            if (sv.Park_Interest_Rating__c != oldSV.Park_Interest_Rating__c) {
                if (!updateCOIList.contains(sv)) {
                    updateCOIList.add(sv);
                }
            }
        }

        if (updateCOIList != null && !updateCOIList.isEmpty()) {
            coisForUpdate = ParkTourTrigger_Helper.updatCOIRating(updateCOIList);
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
            if (sv.Adventure_Park__c != null) {
                comSites.add(sv.Adventure_Park__c);
            }
            if (sv.Contact__c != null) {
                contactIds.add(sv.Contact__c);
            }
            if (sv.CreatedDate.date() != sv.LastModifiedDate.date()) {
                doNotUpdate = true;
            }
        }

        if (!doNotUpdate) {
            collectAccountIdsBasedOnContacts(contactIds, accountIds);
            //todo: see note on previous code
            collectAccountIdToContactsMap(accountIds, accountToContactsMap);

            if (newMap != null &&
                !newMap.isEmpty() &&
                (newMap != null || (masterPlanCommSite != null && !masterPlanCommSite.isEmpty()))
            ) {
                oppToInsert = ParkTourTrigger_Helper.createOpportunityUnderContact(Trigger.new, masterPlanCommSite);
            }

            if (oppToInsert != null && !oppToInsert.isEmpty()) {
                insert oppToInsert;
            }
        }
    }
}
