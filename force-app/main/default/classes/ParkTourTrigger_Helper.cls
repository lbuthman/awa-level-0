//=================================================================================================
// Company: TRI Pointe Group
//  Author: Matt Starr (EnablePath)
// Created: 05/09/2016
// Comment: Site Visit Trigger Methods Class
//=================================================================================================
//          Date            Purpose
// Changes: 05/09/2016      Matt Starr (EnablePath) Created
//          06/06/2016      Matt Starr (EnablePath) added method for Return Visitors
//=================================================================================================

public without sharing class ParkTourTrigger_Helper {
    public static List<Opportunity> oppToInsert = new List<Opportunity>();
    public static Boolean leadOwnerNHAFutureCalled = false;

    public static void getCOIrating(List<Park_Tour__c> visits){
        Set<Id> leadConIds = new Set<Id>();
        Set<Id> commIds = new Set<Id>();

        for(Park_Tour__c sv : visits){
            if(sv.Lead__c != null){
                leadConIds.add(sv.Lead__c);
            }
            if(sv.Contact__c != null){
                leadConIds.add(sv.Contact__c);
            }
            if(sv.Adventure_Park__c != null){
                commIds.add(sv.Adventure_Park__c);
            }
        }

        List<Park_Of_Interest__c> cois = new List<Park_Of_Interest__c> ();
        if(leadConIds != null && !leadConIds.isEmpty() && commIds != null && !commIds.isEmpty()){ //Added null check as per SPDN-199 by Aakanksha - 02-04-20
            cois = [Select Id, Rating__c, Lead__c, Contact__c, Adventure_Park__c
                 from Park_Of_Interest__c where
                (Lead__c in :leadConIds OR Contact__c in : leadConIds)
                and Adventure_Park__c in :commIds Order by CreatedDate DESC];
        }

        for(Park_Tour__c sv : visits){

            if(sv.Lead__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(sv.Lead__c == coi.Lead__c && sv.Adventure_Park__c == coi.Adventure_Park__c){
                        if(coi.Rating__c != null){
                            sv.Park_Interest_Rating__c = coi.Rating__c;
                        }
                        sv.POI_Synced_On_Insert__c = true;
                        break;
                    }
                }
            }

            if(sv.Contact__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(sv.Contact__c == coi.Contact__c && sv.Adventure_Park__c == coi.Adventure_Park__c){
                        if(coi.Rating__c != null){
                            sv.Park_Interest_Rating__c = coi.Rating__c;
                        }
                        sv.POI_Synced_On_Insert__c = true;
                        break;
                    }
                }
            }
        }
    }

    public static List<Park_Of_Interest__c> updatCOIRating(/*Set<Id> svIds*/ List<Park_Tour__c> visits){//Passed site visit list to save one query - SPDN-317 - Aakanksha - 09-07-20
        /*List<Park_Tour__c> visits = [Select Id, Lead__c, Adventure_Park__c, Contact__c,
                                      Park_Interest_Rating__c,  Community_of_Interest_Inactive_Reason__c
                                      from Park_Tour__c where Id in :svIds];*/

        Set<Id> communityIds = new Set<Id>();
        Set<Id> leadConIds = new Set<Id>();

        for(Park_Tour__c sv : visits){
            if(sv.Adventure_Park__c != null){
                communityIds.add(sv.Adventure_Park__c);
            }
            if(sv.Lead__c != null){
                leadConIds.add(sv.Lead__c);
            }
            if(sv.Contact__c != null){
                leadConIds.add(sv.Contact__c);
            }
        }
        List<Park_Of_Interest__c> cois = new List<Park_Of_Interest__c>();
        if(leadConIds != null && !leadConIds.isEmpty()){ //Added null check as per SPDN-199 by Aakanksha - 02-04-20
            cois = [Select Id, Rating__c, Lead__c, Contact__c
            from Park_Of_Interest__c where Lead__c in :leadConIds OR Contact__c in :leadConIds];
        }

        List<Park_Of_Interest__c> coisForUpdate = new List<Park_Of_Interest__c>();

        for(Park_Tour__c sv : visits){
            if(sv.Lead__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(coi.Lead__c != null && coi.Lead__c == sv.Lead__c){
                        if(sv.Park_Interest_Rating__c != coi.Rating__c ){
                            coi.Rating__c = sv.Park_Interest_Rating__c;
                            coisForUpdate.add(coi);
                            break;
                        }
                    }
                }
            }

            if(sv.Contact__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(coi.Contact__c != null && coi.Contact__c == sv.Contact__c){
                        if(sv.Park_Interest_Rating__c != coi.Rating__c){
                            coi.Rating__c = sv.Park_Interest_Rating__c;
                            coisForUpdate.add(coi);
                            break;
                        }
                    }
                }
            }
        }
        return coisForUpdate;
    }

    public static void checkNewVisitor(List<Park_Tour__c> newVisits){
        Set<Id> conIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();

        for(Park_Tour__c sv : newVisits){
            if(sv.Lead__c != null){
                leadIds.add(sv.Lead__c);
            }
            if(sv.Contact__c != null){
                conIds.add(sv.Contact__c);
            }
        }

        if(leadIds.size() > 0){
            List<Lead> leads = [Select Id, (Select Id, Adventure_Park__c from Park_Tour__r) from Lead where Id in :leadIds];

            for(Park_Tour__c sv : newVisits){
                if(sv.Lead__c != null){
                    for(Lead l : leads){
                        if(l.Id == sv.Lead__c){
                            if(l.Park_Tour__r.size() == 0){
                                break;
                            }else{
                                for(Park_Tour__c exVisit : l.Park_Tour__r){
                                    if(exVisit.Adventure_Park__c == sv.Adventure_Park__c){
                                        sv.Return_Visitor__c = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if(conIds.size() > 0){
            List<Contact> cons = [Select Id, AccountId, (Select Id, Adventure_Park__c from Park_Tour__r) from Contact where Id in :conIds];

            for(Park_Tour__c sv : newVisits){
                if(sv.Contact__c != null){
                    for(Contact c : cons){
                        if(c.Id == sv.Contact__c){
                            //<Addition> - Garima - 31 July 2019
                            //<Reason> Added accountId in Site visit record when any user manually creates site visit record </Reason>
                            if(c.AccountId != null){
                                sv.Account__c = c.AccountId;
                            }
                            //</Addition> - Garima - 31 July 2019
                            if(c.Park_Tour__r.size() == 0){
                                break;
                            }else{
                                for(Park_Tour__c exVisit : c.Park_Tour__r){
                                    if(exVisit.Adventure_Park__c == sv.Adventure_Park__c){
                                        sv.Return_Visitor__c = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    //Elixiter Lead Lifecycle - 30-10-2018
    @future
    public static void leadOwnerNHA(String siteVisitList, Set<Id> leadIds, Set<Id> commSiteIds){
        List<Park_Tour__c> siteVisits= (List<Park_Tour__c>)Json.deserialize(siteVisitList,List<Park_Tour__c>.class);
        Map<Id, Park_Tour__c> temp= new Map<Id, Park_Tour__c>();
        Integer i= 0;
        Set<Id> tempLeadIds= new Set<Id>();
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        Map<Id, List<String>> leadToCommSiteToApptKept= new Map<Id, List<String>>();
        List<Lead> leadConvertCommSiteUpdate= new List<Lead>();
        //Below two variables used as per SPDN-198 ticket - Garima- 25 May,2020
        Map<Id, List<Task>> leadToTasks= new Map<Id, List<Task>>();
        Boolean sameTaskAndSiteVisitCommSiteAndDate= false;

        //<Modification> Sushama - May 11, 2020
        //<Reason> Checking the availability of the Task Subject and Type in custom Label to avoid hard coded values as per SPDN-217 </Reason>
        Set<String> taskSubjects = new Set<String>();
        for(String eachString : System.Label.Appointment_Task_Subjects.split(',')){
            taskSubjects.add(eachString);
        }
        //Aakanksha - 04-06-20 Added TasksSubject in where clause as per SPDN-229
        for(Task t: [SELECT Id, WhoId, ActivityDate, WhatId FROM Task
        WHERE WhoId IN: leadIds AND Subject IN :taskSubjects]){  //</Modification> Sushama - May 11, 2020
            //<Modification> Garima- 25 May,2020
            //<Reason>Commented and below code for creating map of Task's whoId(Lead) to tasks
            //to check Task and Site Visit Comm site, also Task Activity date and Site Visit Arrival Date should be same as per SPDN-198 ticket </Reason>
            //Commented below code for converting task community site to lower case as per SPDN-205 ticket - Garima- 30 March,2020
            //List<String> communitySites = t.Community_Site_Picklist__c != null ? t.Community_Site_Picklist__c.split(';') : new List<String>();
            //List<String> communitySites = t.Community_Site_Picklist__c != null ? t.Community_Site_Picklist__c.toLowercase().split(';') : new List<String>();
            //if(t.Appointment_Kept__c == 'Yes'){
            /*if(communitySites != Null && !communitySites.IsEmpty()){
List<string> tempList= new List<String>();
tempList.addAll(communitySites);
if(leadToCommSiteToApptKept.containsKey(t.WhoId)){
tempList.addAll(leadToCommSiteToApptKept.get(t.WhoId));
}
leadToCommSiteToApptKept.put(t.WhoId,tempList);
}*/
            if(leadToTasks.containsKey(t.WhoId) && leadToTasks.get(t.WhoId)!=null){
                List<Task> eachTask= leadToTasks.get(t.WhoId);
                eachTask.add(t);
                leadToTasks.put(t.WhoId, eachTask);
            }else{
                leadToTasks.put(t.WhoId, new List<Task>{t});
            }
            //}
        }
        List<Lead> leadStatusToUpdate= new List<Lead>();

        //<Addition> 07/11/19 Aakanksha - Added Order By Clause in order to fetch records in ascending order so that the latest NHA user on site visit becomes the opportunity owner
        for(Park_Tour__c sv: [SELECT Id, Lead__c,Adventure_Park__r.Name, Arrival_Time__c, Adventure_Park__c, lead__r.IsConverted FROM Park_Tour__c WHERE Lead__c IN: leadIds AND Adventure_Park__c IN: commSiteIds order by Arrival_Time__c]){
            //Convert lead if multiple site visit for same community site
            //<Addition> Garima- 25 may,2020
            //Added below code for checking Task and Site Visit CommSite, also Task Activity Date and Site Visit Arrival date
            //should be same, only then lead will convert as per SPDN-198 ticket
            if(leadToTasks!=null && !leadToTasks.isEmpty() && leadToTasks.containsKey(sv.Lead__c) && leadToTasks.get(sv.Lead__c)!=null){
                for(Task each: leadToTasks.get(sv.Lead__c)){
                    //Aakanksha 03-07-20 - Added Community marketing name condition as per SPDN-309
                    if((each.WhatId==sv.Adventure_Park__c) && each.ActivityDate== sv.Arrival_Time__c.Date())
                        sameTaskAndSiteVisitCommSiteAndDate= true;
                }
            }
            //</Addition> Garima- 25 may,2020

            if(leadids.contains(sv.Lead__c) && !tempLeadIds.contains(sv.Lead__c)){
                i++;
                if(i>1 && commSiteIds.contains(sv.Adventure_Park__c)){
                    tempLeadIds.add(sv.Lead__c);
                    Database.LeadConvert tempLC = new Database.LeadConvert();
                    tempLC.setLeadId(sv.Lead__c);
                    tempLC.setConvertedStatus('Converted');
                    if(!leadsToConvert.contains(tempLC) && sv.lead__r.IsConverted == FALSE){
                        leadsToConvert.add(tempLC);
                    }
                }
                //Commented below code for converting site visit community site to lower case as per SPDN-205 ticket - Garima- 30 March,2020
                //else if(leadToCommSiteToApptKept != NULL && leadToCommSiteToApptKept.containsKey(sv.Lead__c) && leadToCommSiteToApptKept.get(sv.Lead__c) != NULL && leadToCommSiteToApptKept.get(sv.Lead__c).contains(sv.Adventure_Park__r.Name)){
                //<Modification> Garima- 25 May,2020
                //<Reason> Check on the basis of boolean, only then lead should be converted as per SPDN-198 ticket </Reason>
                else if(sameTaskAndSiteVisitCommSiteAndDate){
                    Database.LeadConvert tempLC = new Database.LeadConvert();
                    tempLC.setLeadId(sv.Lead__c);
                    tempLC.setConvertedStatus('Converted');
                    if(!leadsToConvert.contains(tempLC) && sv.lead__r.IsConverted == FALSE){
                        leadsToConvert.add(tempLC);
                    }
                    tempLeadIds.add(sv.Lead__c);
                }

            }

        }
        for(Park_Tour__c sv: siteVisits){
            if(!tempLeadIds.contains(sv.Lead__c)){
                Lead ld= new Lead(Id=sv.Lead__c, Status='Engaged');
                leadStatusToUpdate.add(ld);
            }
        }

        if(leadStatusToUpdate != NULL && !leadStatusToUpdate.IsEmpty()){
            UPDATE leadStatusToUpdate;
        }
        if(leadsToConvert != NULL && !leadsToConvert.IsEmpty()){
            Database.LeadConvertResult[] lc = Database.convertLead(leadsToConvert);

        }
    }
}
