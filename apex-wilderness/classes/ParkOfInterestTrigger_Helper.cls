//Working code for STDN-109
//=================================================================================================
// Company: Apex Backwoods Adventures
//  Author: Tristan Tracker
// Created: 05/27/2016
// Comment: Park of Interest Helper Class for processing Lead triggers
//=================================================================================================
//          Date            Purpose
// Changes: 05/27/2016      Tristan Tracker Created
//          8/24/2016       Levi Logger - Replicating POI to Partner Records
//=================================================================================================

public without sharing class ParkOfInterestTrigger_Helper {
    //<Addition> Quinn Query - 23-10-2018
    //<Reason> Added below method as per requirement of Added Rating of Park of Interest under newly created contact - Data Purification Project </Reason>
    public static void createPOIRating(Set<Id> accIds, List<Park_Of_Interest__c> newList){
        Map<Id, Map<Id,String>> acctToParkMap = new Map<Id, Map<Id,String>>();
        //Below query is not required because it is fetching POI records based on the accountids that are coming from ParkOfInterestTrigger_Handler
        //Instead of doing this, have put an if condition to check if the POI record's Account is a part of accountIds set
        //Flora - 18-05-20- STDN-226
        //for(Park_Of_Interest__c poiList : [SELECT Id, Account__c, Contact__r.account_type__c, Rating__c, Adventure_Park__c FROM Park_Of_Interest__c WHERE Account__c IN: accIds]){
        for(Park_Of_Interest__c poiList : newList){
            if(accIds.contains(poiList.Account__c)){
                if(acctToParkMap !=null && acctToParkMap.containsKey(poiList.Account__c)){
                    Map<Id,String> temp = acctToParkMap.get(poiList.Account__c);
                    if(!temp.containsKey(poiList.Adventure_Park__c) && poiList.Rating__c !=null){
                        temp.put(poiList.Adventure_Park__c, poiList.Rating__c);
                    }
                    acctToParkMap.put(poiList.Account__c,temp);
                }
                else{
                    if(poiList.Rating__c !=null){
                        Map<Id,String> parkToRating = new Map<Id,String>();
                        parkToRating.put(poiList.Adventure_Park__c, poiList.Rating__c);
                        acctToParkMap.put(poiList.Account__c,parkToRating);
                    }
                }
            }
        }

        for(Park_Of_Interest__c poi: newList){
            if(poi.Rating__c == null && acctToParkMap.containsKey(poi.Account__c)){
                Map<Id, String> parkToRating = acctToParkMap.get(poi.Account__c);
                if(parkToRating != null && parkToRating.containsKey(poi.Adventure_Park__c)){
                    poi.Rating__c= parkToRating.get(poi.Adventure_Park__c);
                }
            }
        }
    }
    //</Addition> Quinn Query - 23-10-2018

    public static void synchronizeParkOfInterestContact(Map<Park_Of_Interest__c,Id> parkOfInterestToAccountMap) {
        Map<Id, Id> AccountToContactMap = new Map<Id, Id>();

        for (Contact theContact : [ SELECT accountId FROM Contact WHERE accountId IN :parkOfInterestToAccountMap.values() ORDER BY createdDate]) {
            if (!AccountToContactMap.containsKey(theContact.accountId)) {
                AccountToContactMap.put(theContact.accountId, theContact.Id);
            }
        }

        if (!AccountToContactMap.isEmpty()) {
            for (Park_Of_Interest__c theCommunityOfInterest : parkOfInterestToAccountMap.keySet()) {
                if (AccountToContactMap.containsKey(theCommunityOfInterest.Account__c)) {
                    theCommunityOfInterest.Contact__c = AccountToContactMap.get(theCommunityOfInterest.Account__c);
                }
            }
        }
    }

    public static void addMissingAccount(List<Park_Of_Interest__c> newLists){
        Set<Id> conIds = new Set<Id>();
        for(Park_Of_Interest__c poi : newLists){
            conIds.add(poi.Contact__c);
        }

        List<Contact> cons = [SELECT Id, AccountId FROM Contact WHERE Id IN : conIds];

        for(Park_Of_Interest__c poi : newLists){
            for(Contact c : cons){
                if(c.Id == poi.Contact__c){
                    poi.Account__c = c.AccountId;
                    break;
                }
            }

        }
    }

    public static void createContactPOIs(/*Set<Id> poiIds*/ List<Park_Of_Interest__c> newPOIList){
        //Below query was not required as we only needed Account and Contact of POI which is already coming from the list of POI records
        // therefore, commented it- Flora - STDN-226- 18-05-20
        //List<Park_Of_Interest__c> poiRecs = [Select Id, Account__c, Contact__c, Contact__r.AccountId, Adventure_Park__c, Rating__c from Park_Of_Interest__c where Id in :poiIds];
        Set<Id> acctIds = new  Set<Id>();
        Set<Id> conIds = new Set<Id>();
        List<Park_Of_Interest__c> poiList = new List<Park_Of_Interest__c>();
        List<Contact> contactsForUpdate = new List<Contact>();

        for(Park_Of_Interest__c poi : newPOIList){
            if(poi.Account__c != null)
                acctIds.add(poi.Account__c);
            if(poi.Contact__c != null)
                conIds.add(poi.Contact__c);
        }

        //<Modification> Quinn Query - 25-10-2018
        //<Reason> Removed check Account_Type__c != 'Alternate Contact' and commented old one code as per requirement for showing POI under the Alternate Contact as well - Data Purification project </Reason>
        /*List<Contact> coBuyers = [Select Id, AccountId, Email,
                                (Select Id, Adventure_Park__c from Parks_Of_Interest__r)
                                from Contact where AccountId in :acctIds and Id not in :conIds and
                                Account_Type__c != 'Alternate Contact'];*/
        List<Contact> coBuyers = new List<Contact>();
        //Added null check as per STDN-199 by Flora - 08-04-20
        if(acctIds != null && !acctIds.isEmpty() && conIds!= null && !conIds.isEmpty()){
            coBuyers = [SELECT Id, AccountId, Email,
            (SELECT Id, Adventure_Park__c FROM Parks_Of_Interest__r)
            FROM Contact WHERE AccountId IN :acctIds AND Id NOT IN :conIds];
        }
        //</Modification> Quinn Query - 25-10-2018
        for(Park_Of_Interest__c newPOI : newPOIList){
            List<Contact> cons = new List<Contact>();

            for(Contact c : coBuyers){
                if(c.AccountId == newPOI.Account__c){
                    cons.add(c);
                }
            }

            for(Contact c : cons){
                Boolean hasPOI = false;

                for(Park_Of_Interest__c poi : c.Parks_Of_Interest__r){
                    if(poi.Adventure_Park__c == newPOI.Adventure_Park__c){
                        hasPOI = true;
                        break;
                    }
                }

                if(hasPOI == false){
                    Park_Of_Interest__c poiNew = new Park_Of_Interest__c(
                        Account__c = c.AccountId,
                        Contact__c = c.Id,
                        Adventure_Park__c = newPOI.Adventure_Park__c,
                        Rating__c = newPOI.Rating__c,
                        Synced_From_Related_Contact__c = true);
                    poiList.add(poiNew);
                }else{
                    break;
                }
            }

        }

        if(poiList.size() > 0){
            insert poiList;
        }

        if(contactsForUpdate.size() > 0){
            update contactsForUpdate;
        }
    }

    //public static void deletePOIFromLeadContact(Set<Id> leadsSet, Map<Id,Id> conIdsForSync, List<Park_Of_Interest__c> deletedPOIs){
    public static void deletePOIFromLeadContact(Set<Id> leadsSet, Set<Id> conIdsForSync, List<Park_Of_Interest__c> deletedPOIs){
        //<Modification> Quinn Query 12-10-2018
        //<Reason>Did some changes in query Lead Lifecycle Project</Reason
        //Map<Id, Lead> leadsMap = leadsSet.size()==0?null:new Map<Id, Lead>([Select Id, Coming_Soon_Park__c from Lead where Id in :leadsSet]);
        //Map<Id, Contact> contactsMap = conIdsForSync.size()==0?null:new Map<Id, Contact>([Select Id ,Coming_Soon_Park__c from Contact where Id in :conIdsForSync.values()]);

        Map<Id, Lead> leadsMap = leadsSet.size()==0?null:new Map<Id, Lead>([SELECT Id, isConverted, Coming_Soon_Park__c, (SELECT Id, Adventure_Park__r.Open_Date__c FROM Parks_Of_Interest__r WHERE Adventure_Park__r.Open_Date__c > TODAY) FROM Lead WHERE isConverted = FALSE AND Id IN :leadsSet]);
        //Map<Id, Contact> contactsMap = conIdsForSync.size()==0?null:new Map<Id, Contact>([Select Id, Coming_Soon_Park__c, (SELECT Id,Adventure_Park__r.Open_Date__c FROM Parks_Of_Interest__r WHERE Adventure_Park__r.Open_Date__c > today) from Contact where Id in :conIdsForSync.values()]);
        Map<Id, Contact> contactsMap = conIdsForSync.size()==0?null:new Map<Id, Contact>([SELECT Id, Coming_Soon_Park__c, (SELECT Id,Adventure_Park__r.Open_Date__c FROM Parks_Of_Interest__r WHERE Adventure_Park__r.Open_Date__c > TODAY) FROM Contact WHERE Id IN :conIdsForSync]);
        //</Modification>

        for (Park_Of_Interest__c oldPOI : deletedPOIs){
            String deletedParkName = oldPOI.Adventure_Park__c;
            if(leadsMap!=null && leadsMap.get(oldPOI.Lead__c)!=null){
                Lead leadIns = leadsMap.get(oldPOI.Lead__c);

                //<Addition> Quinn Query 12-10-2018
                //<Reason>Lead Lifecycle Project</Reason>
                if(leadIns.Parks_Of_Interest__r.size() == 0){
                    leadIns.Coming_Soon_Park__c = false;
                }
                //</Addition>
            }
            if(contactsMap!=null && contactsMap.get(oldPOI.Contact__c)!=null){
                Contact contactIns = contactsMap.get(oldPOI.Contact__c);

                //<Addition> Quinn Query 12-10-2018
                //<Reason>Lead Lifecycle Project</Reason>
                if(contactIns.Parks_Of_Interest__r.size() == 0 ){
                    contactIns.Coming_Soon_Park__c = false;
                }
                //</Addition>
            }
        }

        if(leadsMap!=null && leadsMap.size()>0){
            update leadsMap.values();
        }
        if(contactsMap!=null && contactsMap.size()>0){
            update contactsMap.values();
        }
    }

    //<Addition> Quinn Query - 29-10-2018
    //<Reason> Added below method which delete POI under all contacts whenever delete from any of the contact - Data Purification Project </Reason>
    public static void deletePOIUnderContact(Map<String,Id> parkToAccount, List<Park_Of_Interest__c> deletedPOIs){
        List<Contact> conList = [SELECT Id, Name, AccountId, (SELECT Id, Contact__c, Account__c, Adventure_Park__c FROM Parks_Of_Interest__r WHERE Adventure_Park__c IN: parkToAccount.keySet()) FROM Contact WHERE AccountId IN: parkToAccount.values()];
        List<Park_Of_Interest__c> poiList = new List<Park_Of_Interest__c>();

        //<Addition> Flora - Sep 23, 2020 - Added this code to check if there is any other duplicate POIs present under contact for which POI is getting deleted then no POI should be deleted from all the related contacts.  As per STDN-395.
        Set<ID> accountSet = new Set<ID>();
        for(Contact con: conList){
            for(Park_Of_Interest__c poi: con.Parks_Of_Interest__r){
                for(Park_Of_Interest__c deletePOI: deletedPOIs){
                    if(deletePOI.Contact__c == poi.Contact__c && deletePOI.Adventure_Park__c == poi.Adventure_Park__c){
                        accountSet.add(con.AccountId);
                    }
                }
            }
        }
        //</Addition> Flora - Sep 23, 2020 -
        for(Contact con: conList){
            if(!accountSet.contains(con.AccountId)){ //<Addition> Flora - Sep 23, 2020 - Added this check as per STDN-395.
                for(Park_Of_Interest__c poi: con.Parks_Of_Interest__r){
                    if(parkToAccount!=null && parkToAccount.containsKey(poi.Adventure_Park__c) && parkToAccount.get(poi.Adventure_Park__c) !=null && con.AccountId == parkToAccount.get(poi.Adventure_Park__c)){
                        poiList.add(poi);
                    }
                }
            }
        }
        if(poiList != null && !poiList.isEmpty()){
            delete poiList;
        }
    }
    //</Addition> Quinn Query - 29-10-2018

    //<Addition> Flora - Sep 23, 2020 - Restrict to insert Duplicate POI records under the same Contact while inserting/updating POI records manually or during merging process - as per JIRA Ticket STDN-395
    public static void deleteduplicatePOI(Map<Id, Park_Of_Interest__c> newMap, Map<Id, Park_Of_Interest__c> oldMap, Set<Id> parkIds, Set<Id> contactIds){
        List<Park_Of_Interest__c> existingPOIList = new List<Park_Of_Interest__c>();
        Set<Id> poiIdsToDelete = new Set<Id>();
        List<Park_Of_Interest__c> poiDeleteList = new List<Park_Of_Interest__c>();
        List<Park_Of_Interest__c> poiUpdateList = new List<Park_Of_Interest__c>();

        if(newMap != null && !newMap.isEmpty() && parkIds != null && !parkIds.isEmpty() && contactIds != null && !contactIds.isEmpty()){
            existingPOIList = [SELECT Id, Rating__c, Contact__c, Account__c, Adventure_Park__c, LastModifiedDate FROM Park_Of_Interest__c WHERE Id NOT IN : newMap.keyset() AND Adventure_Park__c IN : parkIds AND Contact__c IN : contactIds];
        }

        if(existingPOIList != null && !existingPOIList.isEmpty()){
            for(Park_Of_Interest__c existingPOI : existingPOIList){
                DateTime latestModifiedDate = existingPOI.LastModifiedDate;
                for(Park_Of_Interest__c newPOI : newMap.Values()){
                    if(existingPOI.Contact__c == newPOI.Contact__c){
                        if(existingPOI.Adventure_Park__c == newPOI.Adventure_Park__c){
                            if(newPOI.Rating__c != null && newPOI.Rating__c != '' && existingPOI.Rating__c != newPOI.Rating__c){
                                //Update existing POI's Rating of a contact when any other existing duplicate POI (from different contact) is getting inserted under that Contact with different Rating and having latest modifiedDate. And if existing POI has Rating NULL then in each cases it should be updated with Rating of new one.
                                if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(newPOI.Id) && ((oldMap.get(newPOI.Id).LastModifiedDate > latestModifiedDate) || (existingPOI.Rating__c == null ||existingPOI.Rating__c == ''))){
                                    existingPOI.Rating__c = newPOI.Rating__c;
                                    latestModifiedDate = oldMap.get(newPOI.Id).LastModifiedDate;
                                    if(!poiUpdateList.contains(existingPOI)){
                                        poiUpdateList.add(existingPOI);
                                    }
                                }
                                //Update existing POI's Rating of a contact when new duplicate POI records are getting inserted with different Rating under same Contact
                                else if(oldMap == null){
                                    existingPOI.Rating__c = newPOI.Rating__c;
                                    if(!poiUpdateList.contains(existingPOI)){
                                        poiUpdateList.add(existingPOI);
                                    }
                                }
                            }
                            poiIdsToDelete.add(newPOI.ID);
                        }
                    }
                }
            }
        }

        if(poiIdsToDelete != null && !poiIdsToDelete.isEmpty()){
            poiDeleteList = [SELECT Id, Rating__c, Contact__c, Account__c, Adventure_Park__c FROM Park_Of_Interest__c WHERE Id IN :poiIdsToDelete];
        }
        //Deleting duplicae POI before they insert under a contact that has already POI of same community
        if(poiDeleteList != null && !poiDeleteList.isEmpty()){
            delete poiDeleteList;
        }
        //Updating existing POI Rating
        if(poiUpdateList != null && !poiUpdateList.isEmpty()){
            update poiUpdateList;
        }


    }
    //</Addition> Flora - Sep 23, 2020


}
