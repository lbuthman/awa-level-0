public without sharing class ParkTourTrigger_Handler {

    public void onBeforeInsert(List<Park_Tour__c> newParkTours) {
        List<Park_Tour__c> parkTourForParkOfInterestRatingUpdate = new List<Park_Tour__c>();
        List<Park_Tour__c> parkToursToUpdateReturnVisitorAndMaybeAccountId = new List<Park_Tour__c>();
        for (Park_Tour__c newSiteVisitParkTour : newParkTours) {
            if (newSiteVisitParkTour.Park_Interest_Rating__c == null) {
                parkTourForParkOfInterestRatingUpdate.add(newSiteVisitParkTour);
            }
            parkToursToUpdateReturnVisitorAndMaybeAccountId.add(newSiteVisitParkTour);
        }

        if (parkTourForParkOfInterestRatingUpdate.size() > 0) {
            ParkTourTrigger_Helper.getPOIrating(parkTourForParkOfInterestRatingUpdate);
        }

        if (parkToursToUpdateReturnVisitorAndMaybeAccountId.size() > 0) {
            ParkTourTrigger_Helper.checkNewVisitor(parkToursToUpdateReturnVisitorAndMaybeAccountId);
        }
    }

    public void onAfterInsert(List<Park_Tour__c> newList, Map<Id, Park_Tour__c> newToursMap) {
        List<Park_Tour__c> updatePOIList = new List<Park_Tour__c>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> parkIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Park_Tour__c newParkTour : newToursMap.values()) {
            if (newParkTour.Park_Interest_Rating__c != null && newParkTour.POI_Synced_On_Insert__c == false) {

                if (!updatePOIList.contains(newParkTour)) {
                    updatePOIList.add(newParkTour);
                }
            }
            if (newParkTour.Lead__c != null) {
                leadIds.add(newParkTour.Lead__c);
            }
            if (newParkTour.Adventure_Park__c != null) {
                parkIds.add(newParkTour.Adventure_Park__c);
            }
            if (newParkTour.Contact__c != null) {
                contactIds.add(newParkTour.Contact__c);
            }
        }

        Set<Id> accountIds = new Set<Id>();
        List<Park_Of_Interest__c> parksOfInterestForUpdate = new List<Park_Of_Interest__c>();
        if (updatePOIList != null && !updatePOIList.isEmpty()) {
            parksOfInterestForUpdate = ParkTourTrigger_Helper.updatPOIRating(updatePOIList);
        }

        if (parksOfInterestForUpdate != null && !parksOfInterestForUpdate.isEmpty()) {
            update parksOfInterestForUpdate;
        }
    }

    public void onAfterUpdate(Map<Id, Park_Tour__c> newMap, Map<Id, Park_Tour__c> oldMap) {
        List<Park_Tour__c> updatePOIList = new List<Park_Tour__c>();
        List<Park_Of_Interest__c> poisForUpdate = new List<Park_Of_Interest__c>();
        for (Park_Tour__c pt : newMap.values()) {
            Park_Tour__c oldPT = oldMap.get(pt.Id);
            if (pt.Park_Interest_Rating__c != oldPT.Park_Interest_Rating__c) {
                if (!updatePOIList.contains(pt)) {
                    updatePOIList.add(pt);
                }
            }
        }

        if (updatePOIList != null && !updatePOIList.isEmpty()) {
            poisForUpdate = ParkTourTrigger_Helper.updatPOIRating(updatePOIList);
        }

        if (poisForUpdate != null && !poisForUpdate.isEmpty()) {
            update poisForUpdate;
        }
    }
}