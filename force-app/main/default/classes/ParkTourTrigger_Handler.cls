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
        List<Park_Of_Interest__c> communitiesOfInterestForUpdate = new List<Park_Of_Interest__c>();
        if (updateCOIList != null && !updateCOIList.isEmpty()) {
            communitiesOfInterestForUpdate = ParkTourTrigger_Helper.updatCOIRating(updateCOIList);
        }

        if (communitiesOfInterestForUpdate != null && !communitiesOfInterestForUpdate.isEmpty()) {
            update communitiesOfInterestForUpdate;
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
    }
}
