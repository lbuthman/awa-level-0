public with sharing class ParkOfInterestTrigger_Handler {
    public static Boolean avoidRecursion = false;
    public static Boolean avoidRecursionUpdate = false;
    public static Boolean avoidRecursionDelete = false;

    public void onBeforeInsert(List<Park_Of_Interest__c> newList) {
        Map<Park_Of_Interest__c, Id> parkOfInterestToAccountMap = new Map<Park_Of_Interest__c, Id>();
        List<Park_Of_Interest__c> missingAccounts = new List<Park_Of_Interest__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> parkIds = new Set<Id>();
        Set<Id> inrstInactiveParkIds = new Set<Id>();

        for (Park_Of_Interest__c theParkOfInterest : newList) {
            if (theParkOfInterest.Account__c != null && theParkOfInterest.Contact__c == null) {
                parkOfInterestToAccountMap.put(theParkOfInterest, theParkOfInterest.Account__c);
            }

            if (theParkOfInterest.Contact__c != null && theParkOfInterest.Account__c == null) {
                missingAccounts.add(theParkOfInterest);
            }
            //Add account Ids when Contact and Account id of newly inserted ParkOfInterest is not NULL
            //as per requirement of Added Rating under POI under newly created contact - Data Purification Project
            if (theParkOfInterest.Contact__c != null && theParkOfInterest.Account__c != null) {
                accountIds.add(theParkOfInterest.Account__c);
            }

            if (theParkOfInterest.Adventure_Park__c != null) {
                parkIds.add(theParkOfInterest.Adventure_Park__c);
            }
        }

        //Mark Inactive field of POI record as TRUE if inserted park is Inactive
        if (parkIds != null && !parkIds.isEmpty()) {
            for (Park_Of_Interest__c parkOfInterest : [
                SELECT Id, Rating__c, Inactive__c, Adventure_Park__r.Is_Active__c
                FROM Park_Of_Interest__c
                WHERE Adventure_Park__c IN :parkIds
                AND (Adventure_Park__r.Is_Active__c = FALSE)
            ]) {
                inrstInactiveParkIds.add(parkOfInterest.Adventure_Park__c);
            }
        }


        for (Park_Of_Interest__c CommunityOfInterestRecord : newList) {
            if (inrstInactiveParkIds.contains(CommunityOfInterestRecord.Adventure_Park__c)) {
                CommunityOfInterestRecord.Inactive__c = true;
            }
        }

        if (!parkOfInterestToAccountMap.isEmpty()) {
            ParkOfInterestTrigger_Helper.synchronizeParkOfInterestContact(parkOfInterestToAccountMap);
        }

        if (missingAccounts.size() > 0) {
            ParkOfInterestTrigger_Helper.addMissingAccount(missingAccounts);
        }

        if (accountIds.size() > 0) {
            ParkOfInterestTrigger_Helper.createPOIRating(accountIds, newList);
        }
    }

    public void onAfterInsert(List<Park_Of_Interest__c> newList, Map<Id, Park_Of_Interest__c> newMap, Map<Id, Park_Of_Interest__c> oldMap) {
        Set<Id> contactSync = new Set<Id>();
        List<Park_Of_Interest__c> newPOIlist = new List<Park_Of_Interest__c>();
        Set<Id> leadSet = new Set<Id>();
        Set<Id> contactSet = new Set<Id>();
        Map<Id, Id> leadToParkMap = new Map<Id, Id>();
        Map<Id, Id> contactToParkMap = new Map<Id, Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> parkIds = new Set<Id>();

        for (Park_Of_Interest__c poi : newList) {
            if (poi.Contact__c != null && !contactSet.contains(poi.Contact__c) && !poi.Inactive__c) {
                contactSet.add(poi.Contact__c);
                contactToParkMap.put(poi.Contact__c, poi.Adventure_Park__c);
            }
            if (poi.Lead__c != null && !leadSet.contains(poi.Lead__c) && !poi.Inactive__c) {
                leadSet.add(poi.Lead__c);
                leadToParkMap.put(poi.Lead__c, poi.Adventure_Park__c);
            }

            if (poi.Contact__c != null && poi.Synced_From_Related_Contact__c == false) {
                newPOIlist.add(poi);
                contactSync.add(poi.Contact__c);
            }

            if (poi.Contact__c != null && poi.Adventure_Park__c != null) {
                parkIds.add(poi.Adventure_Park__c);
                contactIds.add(poi.Contact__c);
            }
        }

        if (newPOIlist.size() > 0) {
            ParkOfInterestTrigger_Helper.createContactPOIs(newPOIlist);
        }

        ParkOfInterestTrigger_Helper.replicateParkOfInterestToPartners(Trigger.new, null, null);

        if (newMap != null && !newMap.isEmpty() && parkIds != null && !parkIds.isEmpty() && contactIds != null && !contactIds.isEmpty()) {
            ParkOfInterestTrigger_Helper.deleteduplicatePOI(newMap, oldMap, parkIds, contactIds);
        }
    }

    public void onBeforeUpdate(Map<Id, Park_Of_Interest__c> triggerNewMap, Map<Id, Park_Of_Interest__c> oldMap) {
        Map<Id, Park_Of_Interest__c> newMap = new Map<Id, Park_Of_Interest__c>();
        for(Park_Of_Interest__c thiParkOfInterst : triggerNewMap.values()){
            newMap.put(thiParkOfInterst.Id, thiParkOfInterst);
        }
        if(newMap.isEmpty()) return;

        Map<Park_Of_Interest__c, Id> parkOfInterestToAccountMap = new Map<Park_Of_Interest__c, Id> ();

        for (Park_Of_Interest__c theParkOfInterest : newMap.values()) {
            if (theParkOfInterest.Account__c != oldMap.get(theParkOfInterest.Id).Account__c) {
                if (theParkOfInterest.Account__c != null) {
                    parkOfInterestToAccountMap.put(theParkOfInterest, theParkOfInterest.Account__c);
                }
                else {
                    theParkOfInterest.Contact__c = null;
                }
            }
        }
        if (!parkOfInterestToAccountMap.isEmpty()) {
            ParkOfInterestTrigger_Helper.synchronizeParkOfInterestContact(parkOfInterestToAccountMap);
        }
    }

    public void onAfterUpdate(Map<Id, Park_Of_Interest__c> triggerNewMap, Map<Id, Park_Of_Interest__c> oldMap) {
        Map<Id, Park_Of_Interest__c> newMap = new Map<Id, Park_Of_Interest__c>();
        for(Park_Of_Interest__c thiParkofInterest : triggerNewMap.values()){
            newMap.put(thiParkofInterest.Id, thiParkofInterest);
        }
        if(newMap.isEmpty()) return;

        List<Park_Of_Interest__c> convertedLists = new List<Park_Of_Interest__c>();
        Set<Id> leadSet = new Set<Id>();
        Set<Id> contactSet = new Set<Id>();

        Set<Id> contactIds = new Set<Id>();
        Set<Id> parkIds = new Set<Id>();

        for (Park_Of_Interest__c poi : newMap.values()) {
            Park_Of_Interest__c oldpoi = oldMap.get(poi.Id);

            if (oldpoi.Lead__c != null && poi.Lead__c == null && oldpoi.Contact__c == null && poi.Contact__c != null) {
                convertedLists.add(poi);
            }
            if (oldpoi.Inactive__c != poi.Inactive__c) {
                if (poi.Lead__c != null) leadSet.add(poi.Lead__c);
                if (poi.Contact__c != null) contactSet.add(poi.Contact__c);
            }
            if (oldpoi.Rating__c != poi.Rating__c) {
                if (poi.Lead__c != null) leadSet.add(poi.Lead__c);
                if (poi.Contact__c != null) contactSet.add(poi.Contact__c);
            }

            if (poi.Contact__c != null && poi.Contact__c != oldMap.get(poi.Id).Contact__c && poi.Adventure_Park__c != null) {
                parkIds.add(poi.Adventure_Park__c);
                contactIds.add(poi.Contact__c);
            }
        }

        if (convertedLists.size() > 0) {
            ParkOfInterestTrigger_Helper.createContactPOIs(convertedLists);
        }

        ParkOfInterestTrigger_Helper.replicateParkOfInterestToPartners(Trigger.new, null, null);

        if (newMap != null && !newMap.isEmpty() && parkIds != null && !parkIds.isEmpty() && contactIds != null && !contactIds.isEmpty()) {
            ParkOfInterestTrigger_Helper.deleteduplicatePOI(newMap, oldMap, parkIds, contactIds);
        }
    }

    public void onAfterDelete(List<Park_Of_Interest__c> deletedLists) {
        if (avoidRecursionDelete) return;

        Map<Id, Id> conIdsForSync = new Map<Id, Id>();

        Set<Id> leadsSet = new Set<Id>();
        //Create Map as per requirement of "Deleting POI under all contacts whenever delete from any of the contact" - Data Purification Project
        Map<String, Id> parkToAccountMap = new Map<String, Id>();
        for (Park_Of_Interest__c poi : deletedLists) {
            if (poi.Contact__c != null) {
                conIdsForSync.put(poi.Id, poi.Contact__c);
            }

            if (poi.Lead__c != null) {
                leadsSet.add(poi.Lead__c);
            }

            //as per requirement "Deleting POI under all contacts whenever delete from any of the contact" - Data Purification Project
            if (poi.Contact__c != null && poi.Account__c != null) {
                parkToAccountMap.put(poi.Adventure_Park__c, poi.Account__c);
            }
        }

        if (leadsSet.size() > 0 || conIdsForSync.size() > 0) {
            ParkOfInterestTrigger_Helper.deletePOIFromLeadContact(leadsSet, new Set<Id>(conIdsForSync.values()), deletedLists);
        }

        //Call method for "Deleting POI under all contacts whenever delete from any of the contact" - Data Purification Project
        if (parkToAccountMap != null && !parkToAccountMap.isEmpty() && parkToAccountMap.size() > 0) {
            ParkOfInterestTrigger_Helper.deletePOIUnderContact(parkToAccountMap, deletedLists);
        }
    }

    public void onAfterUnDelete(List<Park_Of_Interest__c> unDeletedLists) {
        Map<Id, Id> conIdsForSync = new Map<Id, Id>();

        for (Park_Of_Interest__c poi : unDeletedLists) {
            if (poi.Contact__c != null) {
                conIdsForSync.put(poi.Id, poi.Contact__c);
            }
        }
    }
    //Sarah 07/2
    public void populateMostRecentPOI(List<Park_Of_Interest__c> newParkOfInterst) {

        List<Id> parkIdList = new List<Id>();
        List<Contact> contactListtoUpdate = new List<Contact>();
        List<Lead> leadListToUpdate = new List<Lead>();

        for (Park_Of_Interest__c poiObj : newParkOfInterst) {
            parkIdList.add(poiObj.Adventure_Park__c);
        }

        Map<Id, Adventure_Park__c> parkMap = new Map<Id, Adventure_Park__c>([
            SELECT Id
            FROM Adventure_Park__c
            WHERE Id IN :parkIdList
        ]);

        for (Park_Of_Interest__c poiObj : newParkOfInterst) {

            if (poiObj.Contact__c == null && poiObj.Lead__c != null) {
                Lead leadObj = new Lead();
                leadObj.Id = poiObj.Lead__c;
                leadListToUpdate.add(leadObj);
            }
            else if (poiObj.Contact__c != null) {
                Contact conObj = new Contact();
                conObj.Id = poiObj.Contact__c;
                contactListtoUpdate.add(conObj);
            }
        }
        if (!contactListtoUpdate.isEmpty()) {
            update contactListtoUpdate;
        }
        if (!leadListToUpdate.isEmpty()) {
            update leadListToUpdate;
        }
    }
}
