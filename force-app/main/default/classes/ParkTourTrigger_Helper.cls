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
            cois = [Select Id, Rating__c, Lead__c, Contact__c, Adventure_Park__c,
                Community_of_Interest_Inactive_Reason__c from Park_Of_Interest__c where
                (Lead__c in :leadConIds OR Contact__c in : leadConIds)
                and Adventure_Park__c in :commIds Order by CreatedDate DESC];
        }

        for(Park_Tour__c sv : visits){

            if(sv.Lead__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(sv.Lead__c == coi.Lead__c && sv.Adventure_Park__c == coi.Adventure_Park__c){
                        if(coi.Rating__c != null){
                            sv.Community_of_Interest_Rating__c = coi.Rating__c;
                            if(coi.Community_of_Interest_Inactive_Reason__c != null){
                                sv.Community_of_Interest_Inactive_Reason__c = coi.Community_of_Interest_Inactive_Reason__c;
                            }
                        }
                        sv.COI_Synced_on_Insert__c = true;
                        break;
                    }
                }
            }

            if(sv.Contact__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(sv.Contact__c == coi.Contact__c && sv.Adventure_Park__c == coi.Adventure_Park__c){
                        if(coi.Rating__c != null){
                            sv.Community_of_Interest_Rating__c = coi.Rating__c;
                            if(coi.Community_of_Interest_Inactive_Reason__c != null){
                                sv.Community_of_Interest_Inactive_Reason__c = coi.Community_of_Interest_Inactive_Reason__c;
                            }
                        }
                        sv.COI_Synced_on_Insert__c = true;
                        break;
                    }
                }
            }
        }
    }

    public static List<Park_Of_Interest__c> updatCOIRating(/*Set<Id> svIds*/ List<Park_Tour__c> visits){//Passed site visit list to save one query - SPDN-317 - Aakanksha - 09-07-20
        /*List<Park_Tour__c> visits = [Select Id, Lead__c, Adventure_Park__c, Contact__c,
                                      Community_of_Interest_Rating__c,  Community_of_Interest_Inactive_Reason__c
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
            cois = [Select Id, Rating__c, Lead__c, Contact__c, Community_of_Interest_Inactive_Reason__c
            from Park_Of_Interest__c where Lead__c in :leadConIds OR Contact__c in :leadConIds];
        }

        List<Park_Of_Interest__c> coisForUpdate = new List<Park_Of_Interest__c>();

        for(Park_Tour__c sv : visits){
            if(sv.Lead__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(coi.Lead__c != null && coi.Lead__c == sv.Lead__c){
                        if(sv.Community_of_Interest_Rating__c != coi.Rating__c ||
                            sv.Community_of_Interest_Inactive_Reason__c != coi.Community_of_Interest_Inactive_Reason__c){
                            coi.Rating__c = sv.Community_of_Interest_Rating__c;
                            coi.Community_of_Interest_Inactive_Reason__c = sv.Community_of_Interest_Inactive_Reason__c;
                            coisForUpdate.add(coi);
                            break;
                        }
                    }
                }
            }

            if(sv.Contact__c != null){
                for(Park_Of_Interest__c coi : cois){
                    if(coi.Contact__c != null && coi.Contact__c == sv.Contact__c){
                        if(sv.Community_of_Interest_Rating__c != coi.Rating__c ||
                            sv.Community_of_Interest_Inactive_Reason__c != coi.Community_of_Interest_Inactive_Reason__c){
                            coi.Rating__c = sv.Community_of_Interest_Rating__c;
                            coi.Community_of_Interest_Inactive_Reason__c = sv.Community_of_Interest_Inactive_Reason__c;
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

    //Added by Grazitti for update Task status to 'Complete' as per JIRA ticket [SP2D-156]- 14 June, 2018
    //<Modification> Garima - 26 Feb, 2019
    //<Reason> Added by Grazitti for update Task status to 'Complete' on Lead and Contact as per JIRA ticket SPDN-47 </Reason>
    public static void updateTasktoComplete(Set<Id> leadIds, Set<Id> conIds, List<Park_Tour__c> newVisits, Map<Id, List<Contact>> accToContacts, Set<String> commSitesUnderMPC, Set<Id> MPCCommSiteId){
        Set<Id> contactIds = new Set<Id>();
        Map<Id, List<Task>> leadContactToTask= new Map<Id, List<Task>>();
        Set<String> taskCommunities= new Set<String>();
        Boolean checkTaskCommSiteIsMPC= false;

        //Fetch all contacts related to account
        for(Id accId: accToContacts.keySet()){
            for(Contact con: accToContacts.get(accId)){
                contactIds.add(con.Id);
            }
        }
        if((leadIds!= null && !leadIds.isEmpty()) || (contactIds!= null && !contactIds.isEmpty())){ //Added null check as per SPDN-199 by Aakanksha - 08-04-20
            //Fetch Task related to Lead and Contact
            //Added Auto Completed field in SOQL - Aakanksha - SPDN-304 - 07-07-20
            for(Task each: [SELECT Id,createddate,Site_Visit_Id__c, Auto_Completed__c, Appointment_Kept__c, WhoId, Subject, Status, ActivityDate, Division__c, Community_Site_Picklist__c FROM Task WHERE isClosed = false AND ((WhoId IN: leadIds) OR (WhoId IN: contactIds))]){ //<Addition> Sushama, July 06, 2020 -  Added check to fetch only open tasks as per SPDN-315 </Addition>
                //<Modification> Sushama - May 11, 2020
                //<Reason> Checking the availability of the Task Subject in custom Label to avoid hard coded values as per SPDN-217 </Reason>
                if(each.WhoId != NULL && each.Subject != NULL && (System.Label.CommunityAppointmentTaskSubjects.contains(each.Subject) || System.Label.ChatBotTasksSubject.contains(each.Subject))){ //</Modification> Sushama - May 11, 2020
                    //Aakanksha - 04-06-20 Added ChatBotTasksSubject in above if condition as per SPDN-229
                    if(leadContactToTask != NULL && leadContactToTask.containsKey(each.WhoId)){
                        List<Task> taskList= leadContactToTask.get(each.WhoId);
                        taskList.add(each);
                        leadContactToTask.put(each.WhoId,taskList);
                    }else{
                        leadContactToTask.put(each.WhoId,new List<Task>{each});
                    }
                    //Fetch task Community Sites for checking it is MPC or not
                    if(each.Community_Site_Picklist__c!=null){
                        if(each.Community_Site_Picklist__c.contains(';')){
                            List<String> taskCommunitySites= each.Community_Site_Picklist__c.toLowercase().split(';');
                            for(String taskCommunity: taskCommunitySites){
                                taskCommunities.add(taskCommunity);
                            }
                        }else{
                            taskCommunities.add(each.Community_Site_Picklist__c.toLowercase());
                        }
                    }
                }
            }
        }
        //Set Boolean Variable is true if task Community Site is MPC as per SPDN-205 ticket
        //<Modification> Lalit - 22-07-2020 - Insert the Ids of Master_Planned_Community__c in a set to compare it as per SPDN-307
        Set<Id> MPCCommSiteIds = new Set<Id>();
        if(taskCommunities!=null && !taskCommunities.isEmpty()){
            for(Adventure_Park__c commSite: [SELECT Id, Master_Plan_Community__c, Master_Planned_Community__c FROM Adventure_Park__c WHERE Name IN: taskCommunities and Master_Planned_Community__c!=null]){
                if(!MPCCommSiteIds.contains(commSite.Master_Planned_Community__c)){
                    MPCCommSiteIds.add(commSite.Master_Planned_Community__c);
                }
                //checkTaskCommSiteIsMPC= true;
            }
        }
        //</Modification>

        List<Contact> contactsToUpdate = new List<Contact>();
        List<Task> tasksToComplete= new List<Task>();
        //<Modification> Sushama - June 26, 2020, <Reason> Commented this code from here and place inner Task 'For-loop' to fix issue as per SPDN-291 </Reason>
        /*Boolean matchMasterPlanCommWithTaskCommSite = false;
        Boolean matchMasterPlanCommWithTaskCommSiteForChatBotTasks = false;
        Boolean matchTaskCommSiteWithSiteVisitCommSite = false;
        Boolean matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks = false;*/
        //</Modification> Sushama - June 26, 2020

        for(Park_Tour__c sv : newVisits){ //Removed SOQL and passed list of site visits coming from trigger.new as per SPDN-317 - Aakanksha - 13-07-20
            Date arrivalDate = sv.Arrival_Time__c != NULL ? sv.Arrival_Time__c.date() : NULL;
            // Update Task status to "Complete" on Lead as per SPDN-47 ticket - 11/01/2019
            if(leadContactToTask.ContainsKey(sv.Lead__c) && leadContactToTask.get(sv.Lead__c) != NULL){
                for(Task eachTask: leadContactToTask.get(sv.Lead__c)){
                    //<Modification> Sushama - June 26, 2020, <Reason> Declared these variables here to avoid issue if there are more than one Tasks under Lead as per SPDN-291 </Reason>
                    Boolean matchMasterPlanCommWithTaskCommSite = false;
                    Boolean matchMasterPlanCommWithTaskCommSiteForChatBotTasks = false;
                    Boolean matchTaskCommSiteWithSiteVisitCommSite = false;
                    Boolean matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks = false;
                    //</Modification> Sushama - June 26, 2020
                    //check division
                    //check comm site
                    //Check task community site with Communities under MPC
                    //And Site Visit Community Site is of MPC
                    if(commSitesUnderMPC !=null && !commSitesUnderMPC.isEmpty() && String.isNotBlank(eachTask.Community_Site_Picklist__c)){
                        //If task with multiple communities sites
                        if(!System.Label.ChatBotTasksSubject.contains(eachTask.Subject)){//Aakanksha 05-06-20 - check if the task is not created from event as per SPDN-229
                            if(eachTask.Community_Site_Picklist__c.contains(';')){
                                List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                    //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan as per SPDN-205
                                    //Added a check of MPCCommSiteIds to check whether it contains the SiteVisit's community site's master plan id as per SPDN-307

                                    if(taskCommSites.contains(commSiteUnderMastePlannedComm) && /*(sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC) &&*/ MPCCommSiteIds.containsAll(MPCCommSiteId)){
                                        matchMasterPlanCommWithTaskCommSite = true;
                                    }
                                }
                            }else{ //If task with only one community site
                                //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan on Lead as per SPDN-205 ticket
                                //Added a check of MPCCommSiteIds to check whether it contains the SiteVisit's community site's master plan id as per SPDN-307

                                if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.toLowercase()) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){
                                    matchMasterPlanCommWithTaskCommSite = true;
                                }
                            }
                        }else{ //Aakanksha 05-06-20 - check if the task is created from event as per SPDN-229
                            if(eachTask.Community_Site_Picklist__c.contains(';')){
                                List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                    //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan as per SPDN-205
                                    if(taskCommSites.contains(commSiteUnderMastePlannedComm) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){ //Added condition to check of site visit's community site and task's community site's master planned community is same as per SPDN-338 - Aakanksha - 05-08-20
                                        matchMasterPlanCommWithTaskCommSiteForChatBotTasks = true;
                                    }
                                }
                            }else{ //If task with only one community site
                                //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan on Lead as per SPDN-205 ticket

                                if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.toLowercase()) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){ //Added condition to check of site visit's community site and task's community site's master planned community is same as per SPDN-338 - Aakanksha - 05-08-20
                                    matchMasterPlanCommWithTaskCommSiteForChatBotTasks = true;
                                }
                            }
                        }
                    }

                    //If Site Visit Community Site is not MPC as per SPDN-205 ticket - Garima - 1 April,2020
                    if(!matchMasterPlanCommWithTaskCommSite ){
                        if(!System.Label.ChatBotTasksSubject.contains(eachTask.Subject)){//Aakanksha 05-06-20 - check if the task is not created from event as per SPDN-229
                            if(eachTask.Community_Site_Picklist__c!=null && sv.Adventure_Park__c != null){ //Added null check as per SPDN-211 - Aakanksha - 16-04-20
                                if(eachTask.Community_Site_Picklist__c.contains(';')){
                                    List<String> taskCommSites= eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                    for(String tskCommSite: taskCommSites){
                                        //Match task community site with
                                        if(tskCommSite==sv.Community_site_name__c.toLowercase()){
                                            matchTaskCommSiteWithSiteVisitCommSite= true;
                                        }
                                        else{
                                            if(sv.Community_Marketing_Name__c != null){ //Aakanksha - 02-06-20 SPDN-250- check if community marketing name matches
                                                if(tskCommSite==sv.Community_Marketing_Name__c.toLowercase()){
                                                    matchTaskCommSiteWithSiteVisitCommSite= true;
                                                }
                                            }
                                        }
                                    }
                                }else{
                                    if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_site_name__c.toLowercase()){
                                        matchTaskCommSiteWithSiteVisitCommSite= true;
                                    }
                                    else{
                                        if(sv.Community_Marketing_Name__c != null){
                                            if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_Marketing_Name__c.toLowercase()){ //Aakanksha - 02-06-20 SPDN-250 - check if community marketing name matches
                                                matchTaskCommSiteWithSiteVisitCommSite= true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if(!matchMasterPlanCommWithTaskCommSiteForChatBotTasks ){
                        if(System.Label.ChatBotTasksSubject.contains(eachTask.Subject)){//Aakanksha 05-06-20 - check if the task is created from event as per SPDN-229
                            if(eachTask.Community_Site_Picklist__c!=null && sv.Adventure_Park__c != null){ //Added null check as per SPDN-211 - Aakanksha - 16-04-20
                                if(eachTask.Community_Site_Picklist__c.contains(';')){
                                    List<String> taskCommSites= eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                    for(String tskCommSite: taskCommSites){
                                        //Match task community site with
                                        if(tskCommSite==sv.Community_site_name__c.toLowercase()){
                                            matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                        }
                                        else{
                                            if(sv.Community_Marketing_Name__c != null){ //Aakanksha - 02-06-20 SPDN-250- check if community marketing name matches
                                                if(tskCommSite==sv.Community_Marketing_Name__c.toLowercase()){
                                                    matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                                }
                                            }
                                        }
                                    }
                                }else{
                                    if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_site_name__c.toLowercase()){
                                        matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                    }
                                    else{
                                        if(sv.Community_Marketing_Name__c != null){
                                            if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_Marketing_Name__c.toLowercase()){ //Aakanksha - 02-06-20 SPDN-250 - check if community marketing name matches
                                                matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //Added condition to mark task as completed only if it is created before site visit - Aakanksha - 10-11-20
                    if(!System.Label.ChatBotTasksSubject.contains(eachTask.Subject) && eachTask.Division__c !=NULL && eachTask.Community_Site_Picklist__c !=NULL && sv.Site_Visit_Division__c != null && eachTask.Division__c == sv.Site_Visit_Division__c && sv.Adventure_Park__c != NULL && (matchTaskCommSiteWithSiteVisitCommSite || matchMasterPlanCommWithTaskCommSite) && arrivalDate != null && eachTask.ActivityDate != null && arrivalDate == eachTask.ActivityDate && eachTask.createddate < sv.createddate){
                        eachTask.Status= 'Completed';
                        if(eachTask.Appointment_Kept__c == NULL || eachTask.Appointment_Kept__c == ''){
                            eachTask.Appointment_Kept__c = 'Yes';
                            //Aakanksha - 23-09-20 - SPDN-414
                            eachTask.Site_Visit_Id__c = sv.Id;
                            //Aakanksha - 07-07-20 SPDN-304
                            //Mark Auto-Completed checkbox as True
                            eachTask.Auto_Completed__c = true;
                        }
                        if(!tasksToComplete.contains(eachTask))
                            tasksToComplete.add(eachTask);
                    }

                    //Aakanksha SPDN-229 - 08-06-20 complete tasks created from event if valid site visit exists
                    //Added condition to mark task as completed only if it is created before site visit - Aakanksha - 10-11-20
                    if(System.Label.ChatBotTasksSubject.contains(eachTask.Subject) && eachTask.Division__c !=NULL && eachTask.Community_Site_Picklist__c !=NULL && sv.Site_Visit_Division__c != null && eachTask.Division__c == sv.Site_Visit_Division__c && sv.Adventure_Park__c != NULL && (matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks || matchMasterPlanCommWithTaskCommSiteForChatBotTasks ) && arrivalDate != null && eachTask.ActivityDate != null && arrivalDate == eachTask.ActivityDate && eachTask.createddate < sv.createddate){
                        eachTask.Status= 'Completed';
                        if(eachTask.Appointment_Kept__c == NULL || eachTask.Appointment_Kept__c == ''){
                            eachTask.Appointment_Kept__c = 'Yes';
                            //Aakanksha - 23-09-20 - SPDN-414
                            eachTask.Site_Visit_Id__c = sv.Id;
                            //Aakanksha - 07-07-20 SPDN-304
                            //Mark Auto-Completed checkbox as True
                            eachTask.Auto_Completed__c = true;
                        }
                        if(!tasksToComplete.contains(eachTask))
                            tasksToComplete.add(eachTask);
                    }

                }
            }
            //Update Task status to "Complete" when any of the contact visits the site as per SPDN-47 ticket - 26 Feb, 2019
            else{
                for(Id con: contactIds){
                    if(leadContactToTask.containsKey(con) && leadContactToTask.get(con)!=NULL){
                        for(Task eachTask: leadContactToTask.get(con)){
                            //<Modification> Sushama - June 26, 2020, <Reason> Declared these variables here to avoid issue if there are more than one Tasks under Lead as per SPDN-291 </Reason>
                            Boolean matchMasterPlanCommWithTaskCommSite = false;
                            Boolean matchMasterPlanCommWithTaskCommSiteForChatBotTasks = false;
                            Boolean matchTaskCommSiteWithSiteVisitCommSite = false;
                            Boolean matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks = false;
                            //</Modification> Sushama - June 26, 2020
                            //check division
                            //check comm site

                            //Check task community site with Communities under MPC
                            if(commSitesUnderMPC !=null && !commSitesUnderMPC.isEmpty() && String.isNotBlank(eachTask.Community_Site_Picklist__c)){
                                if(!System.Label.ChatBotTasksSubject.contains(eachTask.Subject)){//Aakanksha 05-06-20 - check if the task is not created from event as per SPDN-229
                                    //If task with multiple communities sites
                                    if(eachTask.Community_Site_Picklist__c.contains(';')){
                                        List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                        for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                            //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan on Contact as per SPDN-205 ticket
                                            //Added a check of MPCCommSiteIds to check whether it contains the SiteVisit's community site's master plan id as per SPDN-307
                                            if(taskCommSites.contains(commSiteUnderMastePlannedComm) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){
                                                matchMasterPlanCommWithTaskCommSite = true;
                                            }
                                        }
                                    }else{ //If task with only one community site
                                        //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan as per SPDN-205 ticket
                                        //Added a check of MPCCommSiteIds to check whether it contains the SiteVisit's community site's master plan id as per SPDN-307
                                        if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.toLowercase()) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){
                                            matchMasterPlanCommWithTaskCommSite = true;
                                        }
                                    }
                                }else{ //Aakanksha 05-06-20 - check if the task is created from event as per SPDN-229

                                    //If task with multiple communities sites
                                    if(eachTask.Community_Site_Picklist__c.contains(';')){
                                        List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                        for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                            //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan on Contact as per SPDN-205 ticket
                                            if(taskCommSites.contains(commSiteUnderMastePlannedComm) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){ //Added condition to check of site visit's community site and task's community site's master planned community is same as per SPDN-338 - Aakanksha - 05-08-20
                                                matchMasterPlanCommWithTaskCommSiteForChatBotTasks = true;
                                            }
                                        }
                                    }else{ //If task with only one community site
                                        //Add Condition for checking either Task community site or Site Visit Community Site is Master Plan as per SPDN-205 ticket
                                        if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.toLowercase()) /*&& (sv.Master_plan_SiteVisit__c || checkTaskCommSiteIsMPC)*/ && MPCCommSiteIds.containsAll(MPCCommSiteId)){ //Added condition to check of site visit's community site and task's community site's master planned community is same as per SPDN-338 - Aakanksha - 05-08-20
                                            matchMasterPlanCommWithTaskCommSiteForChatBotTasks = true;
                                        }
                                    }
                                }
                            }

                            //If Site Visit Community Site is not MPC as per SPDN-205 ticket - Garima -1 April,2020
                            if(!matchMasterPlanCommWithTaskCommSite){
                                if(!System.Label.ChatBotTasksSubject.contains(eachTask.Subject)){//Aakanksha 05-06-20 - check if the task is not created from event as per SPDN-229
                                    if(eachTask.Community_Site_Picklist__c!=null && sv.Adventure_Park__c != null){ //Added null check as per SPDN-211 - Aakanksha - 16-04-20
                                        if(eachTask.Community_Site_Picklist__c.contains(';')){
                                            List<String> taskCommSites= eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                            for(String tskCommSite: taskCommSites){
                                                //Match task community site with
                                                if(tskCommSite==sv.Community_site_name__c.toLowercase()){
                                                    matchTaskCommSiteWithSiteVisitCommSite= true;
                                                }
                                                else{
                                                    if(sv.Community_Marketing_Name__c != null){
                                                        if(tskCommSite==sv.Community_Marketing_Name__c.toLowercase()){ //Aakanksha - 02-06-20 -SPDN-250 - check if community marketing name matches
                                                            matchTaskCommSiteWithSiteVisitCommSite= true;
                                                        }
                                                    }
                                                }
                                            }
                                        }else{
                                            if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_site_name__c.toLowercase()){
                                                matchTaskCommSiteWithSiteVisitCommSite= true;
                                            }
                                            else {
                                                if(sv.Community_Marketing_Name__c != null){
                                                    if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_Marketing_Name__c.toLowercase()){ //Aakanksha - 02-06-20 -SPDN-250- check if community marketing name matches
                                                        matchTaskCommSiteWithSiteVisitCommSite= true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if(!matchMasterPlanCommWithTaskCommSiteForChatBotTasks){
                                if(System.Label.ChatBotTasksSubject.contains(eachTask.Subject)){ //Aakanksha 05-06-20 - check if the task is created from event as per SPDN-229
                                    if(eachTask.Community_Site_Picklist__c!=null && sv.Adventure_Park__c != null){ //Added null check as per SPDN-211 - Aakanksha - 16-04-20
                                        if(eachTask.Community_Site_Picklist__c.contains(';')){
                                            List<String> taskCommSites= eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                            for(String tskCommSite: taskCommSites){
                                                //Match task community site with
                                                if(tskCommSite==sv.Community_site_name__c.toLowercase()){
                                                    matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                                }
                                                else{
                                                    if(sv.Community_Marketing_Name__c != null){
                                                        if(tskCommSite==sv.Community_Marketing_Name__c.toLowercase()){ //Aakanksha - 02-06-20 -SPDN-250 - check if community marketing name matches
                                                            matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                                        }
                                                    }
                                                }
                                            }
                                        }else{
                                            if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_site_name__c.toLowercase()){
                                                matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                            }
                                            else {
                                                if(sv.Community_Marketing_Name__c != null){
                                                    if(eachTask.Community_Site_Picklist__c.toLowerCase()==sv.Community_Marketing_Name__c.toLowercase()){ //Aakanksha - 02-06-20 -SPDN-250- check if community marketing name matches
                                                        matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks= true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            //Added condition to mark task as completed only if it is created before site visit - Aakanksha - 10-11-20
                            if(!System.Label.ChatBotTasksSubject.contains(eachTask.Subject) && eachTask.Division__c !=NULL && eachTask.Community_Site_Picklist__c !=NULL && sv.Site_Visit_Division__c != null && eachTask.Division__c == sv.Site_Visit_Division__c && (matchTaskCommSiteWithSiteVisitCommSite || matchMasterPlanCommWithTaskCommSite) && arrivalDate != null && eachTask.ActivityDate != null && arrivalDate == eachTask.ActivityDate && eachTask.createddate < sv.createddate){
                                eachTask.Status= 'Completed';
                                if(eachTask.Appointment_Kept__c == NULL || eachTask.Appointment_Kept__c == ''){
                                    eachTask.Appointment_Kept__c = 'Yes';
                                    //Aakanksha - 23-09-20 - SPDN-414
                                    eachTask.Site_Visit_Id__c = sv.Id;
                                    //Aakanksha - 07-07-20 SPDN-304
                                    //Mark Auto-Completed checkbox as True
                                    eachTask.Auto_Completed__c = true;
                                }
                                if(!tasksToComplete.contains(eachTask))
                                    tasksToComplete.add(eachTask);
                            }

                            //Aakanksha SPDN-229 - 08-06-20 complete tasks created from event if valid site visit exists
                            //Added condition to mark task as completed only if it is created before site visit - Aakanksha - 10-11-20
                            if(System.Label.ChatBotTasksSubject.contains(eachTask.Subject) && eachTask.Division__c !=NULL && eachTask.Community_Site_Picklist__c !=NULL && sv.Site_Visit_Division__c != null && eachTask.Division__c == sv.Site_Visit_Division__c && (matchTaskCommSiteWithSiteVisitCommSiteForChatBotTasks|| matchMasterPlanCommWithTaskCommSiteForChatBotTasks ) && arrivalDate != null && eachTask.ActivityDate != null && arrivalDate == eachTask.ActivityDate && eachTask.createddate < sv.createddate){
                                eachTask.Status= 'Completed';
                                if(eachTask.Appointment_Kept__c == NULL || eachTask.Appointment_Kept__c == ''){
                                    eachTask.Appointment_Kept__c = 'Yes';
                                    //Aakanksha - 23-09-20 - SPDN-414
                                    eachTask.Site_Visit_Id__c = sv.Id;
                                    //Aakanksha - 07-07-20 SPDN-304
                                    //Mark Auto-Completed checkbox as True
                                    eachTask.Auto_Completed__c = true;
                                }
                                if(!tasksToComplete.contains(eachTask))
                                    tasksToComplete.add(eachTask);
                            }
                        }
                    }
                }
            }
        }
        if(tasksToComplete !=NULL && !tasksToComplete.isEmpty()){
            for(Task task : tasksToComplete){
                task.Bypass_Date_Time__c = Datetime.now().addMinutes(5);
            }
            UPDATE tasksToComplete;
        }

    }
    //</Modification> Garima - 26 Feb, 2019


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
        for(String eachString : System.Label.CommunityAppointmentTaskSubjects.split(',')){
            taskSubjects.add(eachString);
        }
        Set<String> taskTypes = new Set<String>();
        for(String eachString : System.Label.CommunityAppointmentTaskTypes.split(',')){
            taskTypes.add(eachString);
        }
        //Aakanksha - 04-06-20 Added ChatBotTasksSubject and ChatBotTasksType in where clause as per SPDN-229
        for(Task t: [SELECT Id, WhoId, ActivityDate, Appointment_Kept__c, Community_Site_Picklist__c FROM Task
        WHERE WhoId IN: leadIds AND (Task_Type__c IN: taskTypes OR Task_Type__c =: System.Label.ChatBotTasksType) AND Appointment_Kept__c = 'Yes']){  //</Modification> Sushama - May 11, 2020
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
        for(Park_Tour__c sv: [SELECT Id, Lead__c,Community_Site__r.Community_Marketing_Name__c, Arrival_Time__c, New_Home_Advisor__c,New_Home_Advisor__r.Name, Adventure_Park__c, Community_Site__r.Name, lead__r.IsConverted FROM Park_Tour__c WHERE Lead__c IN: leadIds AND Adventure_Park__c IN: commSiteIds order by Arrival_Time__c]){
            //Convert lead if multiple site visit for same community site
            //<Addition> Garima- 25 may,2020
            //Added below code for checking Task and Site Visit CommSite, also Task Activity Date and Site Visit Arrival date
            //should be same, only then lead will convert as per SPDN-198 ticket
            if(leadToTasks!=null && !leadToTasks.isEmpty() && leadToTasks.containsKey(sv.Lead__c) && leadToTasks.get(sv.Lead__c)!=null){
                for(Task each: leadToTasks.get(sv.Lead__c)){
                    for(String taskCommSite: each.Community_Site_Picklist__c.toLowercase().split(';')){
                        //Aakanksha 03-07-20 - Added Community marketing name condition as per SPDN-309
                        if((taskCommSite==sv.Community_Site__r.Name.toLowercase() || (sv.Community_Site__r.Community_Marketing_Name__c != null && taskCommSite==sv.Community_Site__r.Community_Marketing_Name__c.toLowercase())) && each.ActivityDate== sv.Arrival_Time__c.Date())
                            sameTaskAndSiteVisitCommSiteAndDate= true;
                    }
                }
            }
            //</Addition> Garima- 25 may,2020

            if(leadids.contains(sv.Lead__c) && !tempLeadIds.contains(sv.Lead__c)){
                i++;
                if(i>1 && commSiteIds.contains(sv.Adventure_Park__c)){
                    tempLeadIds.add(sv.Lead__c);
                    Database.LeadConvert tempLC = new Database.LeadConvert();
                    tempLC.setLeadId(sv.Lead__c);
                    tempLC.setOwnerId(sv.New_Home_Advisor__c);
                    tempLC.setConvertedStatus('Converted');
                    if(!leadsToConvert.contains(tempLC) && sv.lead__r.IsConverted == FALSE){
                        leadsToConvert.add(tempLC);
                    }
                    Lead ld= new Lead(Id=sv.Lead__c, Converted_Community__c=sv.Adventure_Park__c);
                    leadStatusToUpdate.add(ld);
                }
                //Commented below code for converting site visit community site to lower case as per SPDN-205 ticket - Garima- 30 March,2020
                //else if(leadToCommSiteToApptKept != NULL && leadToCommSiteToApptKept.containsKey(sv.Lead__c) && leadToCommSiteToApptKept.get(sv.Lead__c) != NULL && leadToCommSiteToApptKept.get(sv.Lead__c).contains(sv.Community_Site__r.Name)){
                //<Modification> Garima- 25 May,2020
                //<Reason> Check on the basis of boolean, only then lead should be converted as per SPDN-198 ticket </Reason>
                else if(sameTaskAndSiteVisitCommSiteAndDate){
                    Database.LeadConvert tempLC = new Database.LeadConvert();
                    tempLC.setLeadId(sv.Lead__c);
                    tempLC.setOwnerId(sv.New_Home_Advisor__c);
                    tempLC.setConvertedStatus('Converted');
                    if(!leadsToConvert.contains(tempLC) && sv.lead__r.IsConverted == FALSE){
                        leadsToConvert.add(tempLC);
                    }
                    tempLeadIds.add(sv.Lead__c);
                    Lead ld= new Lead(Id=sv.Lead__c, Converted_Community__c=sv.Adventure_Park__c);
                    leadStatusToUpdate.add(ld);
                }

            }

        }
        for(Park_Tour__c sv: siteVisits){
            if(!tempLeadIds.contains(sv.Lead__c)){
                Lead ld= new Lead(Id=sv.Lead__c, Status='NHA Engaged');
                RecursionHandling.leadStatusChangedFromCode = TRUE;
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
    //<Addition> Anmol Baweja- 11-03-2019 Auto-convert to opportunity at the Contact level as per SPDN-77
    //<Modification> Lalit - 30-10-2020 - Removing contacts checks and parameters in methods as site visit is populating on account level as per SPDN-419#
    public static List<Opportunity> createOpportunityUnderContact(List<Park_Tour__c> siteVisitList, /*Set<Id> conIds,*/ Set<String> commSitesUnderMPC){
        //If multiple site visits done for same community site
        //If NHS appt. and site visit for same community site
        //Contact should not have any Contract Pending/Contracted/Escrow opportunity related to it
        Set<Id> contactIds= new Set<Id>();
        Set<Id> accountIds= new Set<Id>();
        Set<Id> accountOppIds = new Set<Id>();
        List<Opportunity> opportunityToCreated = new List<Opportunity>();

        for(Park_Tour__c each: siteVisitList){
            contactIds.add(each.Contact__c);
            accountIds.add(each.Account__c);
        }
        Map<Id, Set<String>> accountToCLosedOpps = new Map<Id, Set<String>>();
        Map<Id, Set<String>> accountToOpenOpps = new Map<Id, Set<String>>();
        Map<Id, Map<Id, Integer>> accountToComSiteToSiteVisit = new Map<Id, Map<Id, Integer>>();
        Map<Id, List<ActivityHistory>> accountToTasks = new Map<Id, List<ActivityHistory>>();

        List<Account> accounts = new List<Account> ();
        if(accountIds != null && !accountIds.isEmpty()){ //Added null check as per SPDN-199 by Aakanksha - 08-04-20
            //<Modification> Sushama - May 11, 2020
            //<Reason> Checking the availability of the Task Subject and Type in custom Label to avoid hard coded values as per SPDN-217 </Reason>
            Set<String> taskSubjects = new Set<String>();
            for(String eachString : System.Label.CommunityAppointmentTaskSubjects.split(',')){
                taskSubjects.add(eachString);
            }
            Set<String> taskTypes = new Set<String>();
            for(String eachString : System.Label.CommunityAppointmentTaskTypes.split(',')){
                taskTypes.add(eachString);
            }
            //Aakanksha - 04-06-20 Added ChatBotTasksSubject and ChatBotTasksType in where clause as per SPDN-229
            //Aakanksha - 09-09-20 Added additional checks to fetch only customer accounts - SPDN-400
            accounts= [SELECT Id, (SELECT Id FROM Contacts), (SELECT Id, Adventure_Park__c FROM Park_Tour__r), (SELECT Id, Subject, Status, Community_Site_Picklist__c, Appointment_Kept__c, ActivityDate FROM ActivityHistories WHERE (Subject IN: taskSubjects OR Subject =: System.Label.ChatBotTasksSubject) AND (Task_Type__c IN: taskTypes OR Task_Type__c =: System.Label.ChatBotTasksType) AND ActivityDate <= LAST_N_DAYS:365 AND Appointment_Kept__c = 'Yes' AND Status = 'Completed'), (SELECT Id, Adventure_Park__c, Community_Site__r.Name, IsClosed, IsWon, StageName FROM Opportunities) FROM Account WHERE Id IN: accountIds AND RecordtypeName__c = 'Customer Account' AND (Type = 'Prospect' OR Type = 'Buyer' OR Type = 'Home Owner' )];
            //</Modification> Sushama - May 11, 2020
        }
        for(Account each: accounts){
            for(Contact eachCon: each.Contacts){
                //Account to all Opportunities
                if(each.Opportunities.size() > 0){
                    for(Opportunity eachOpp: each.Opportunities){
                        //Account having all opportunities except Contract Pending/Contraced/Escrow/Cancellation Pending because no operation need to be performed on these opportunities

                        //Commented below if condition and added new wherein added new opportunity stages check as per new cancellation process - Aakanksha - 15-12-20 - SPDN-432
                        //if(eachOpp.StageName != 'Contract Pending' && eachOpp.StageName != 'Contracted' && eachOpp.StageName != 'Escrow' && eachOpp.StageName != 'Cancellation Pending'){
                        if(eachOpp.StageName != 'Contract Pending' && eachOpp.StageName != 'Contracted' && eachOpp.StageName != 'Escrow' && eachOpp.StageName != 'Pending Cancellation' && eachOpp.StageName != 'Cancellation Approved' && eachOpp.StageName != 'Cancellation Submitted' && eachOpp.StageName != 'Cancelled'){
                            if(eachOpp.Adventure_Park__c != NULL){
                                if(eachOpp.IsClosed || eachOpp.IsWon){//Map of account to it's closed opps community sites
                                    //Contact to only closed opps
                                    if(!accountToCLosedOpps.containsKey(each.Id)){
                                        accountToCLosedOpps.put(each.Id, new Set<String>{eachOpp.Community_Site__r.Name});
                                    }else{
                                        Set<String> temp= accountToCLosedOpps.get(each.Id);
                                        if(temp != NULL) temp.add(eachOpp.Community_Site__r.Name);
                                        accountToCLosedOpps.put(each.Id,temp);
                                    }
                                }else if(!eachOpp.IsClosed && !eachOpp.IsWon){
                                    if(!accountToOpenOpps.containsKey(each.Id)){//Map of account to it's open opps community sites
                                        accountToOpenOpps.put(each.Id, new Set<String>{eachOpp.Community_Site__r.Name});
                                    }else{
                                        Set<String> temp= accountToOpenOpps.get(each.Id);
                                        if(temp != NULL) temp.add(eachOpp.Community_Site__r.Name);
                                        accountToOpenOpps.put(each.Id,temp);
                                    }
                                }
                            }
                            if(accountToOpenOpps.containsKey(each.Id) && accountToCLosedOpps.containsKey(each.Id)){
                                accountToCLosedOpps.remove(each.Id);
                            }
                        }else{
                            if(accountToOpenOpps != NULL && accountToOpenOpps.containsKey(each.Id)){
                                accountToOpenOpps.remove(each.Id);
                            }
                            if(accountToCLosedOpps != NULL && accountToCLosedOpps.containsKey(each.Id)){
                                accountToCLosedOpps.remove(each.Id);
                            }
                            break;
                        }
                    }
                }
                //Accounts with no opportunities
                else{
                    accountOppIds.add(each.Id);
                }
            }
            //Account to all Site Visits
            if(each.Park_Tour__r != NULL && each.Park_Tour__r.size() > 0){//Add account as key in this map
                for(Park_Tour__c eachVisit: each.Park_Tour__r){
                    //Map of account to it's Site Visit's (Account to it's site visit's community site to No. of site visits)
                    if(!accountToComSiteToSiteVisit.containsKey(each.Id)){
                        Map<Id, Integer> commSiteToSiteVisit = new Map<Id, Integer>();
                        commSiteToSiteVisit.put(eachVisit.Adventure_Park__c, 1);
                        accountToComSiteToSiteVisit.put(each.Id, commSiteToSiteVisit);
                    }else{
                        if(accountToComSiteToSiteVisit.get(each.Id) !=NULL){
                            Map<Id, Integer> commSiteToVisits = accountToComSiteToSiteVisit.get(each.Id);
                            if(commSiteToVisits !=NULL && commSiteToVisits.containsKey(eachVisit.Adventure_Park__c) && commSiteToVisits.get(eachVisit.Adventure_Park__c) !=NULL){
                                Integer temp = commSiteToVisits.get(eachVisit.Adventure_Park__c)+1;
                                commSiteToVisits.put(eachVisit.Adventure_Park__c, temp);
                                accountToComSiteToSiteVisit.put(each.Id, commSiteToVisits);
                            }else{
                                commSiteToVisits.put(eachVisit.Adventure_Park__c, 1);
                                accountToComSiteToSiteVisit.put(each.Id, commSiteToVisits);
                            }
                        }
                    }
                }
            }

            //Account to all NHS Appointment Tasks
            if(each.ActivityHistories !=NULL && each.ActivityHistories.size()>0){
                for(ActivityHistory tsk: each.ActivityHistories){
                    //Map of Contact to All NHS Appointment Tasks
                    if(!accountToTasks.containsKey(each.Id)){
                        accountToTasks.put(each.Id, new List<ActivityHistory>{tsk});
                    }else{
                        if(accountToTasks.get(each.Id) !=NULL){
                            List<ActivityHistory> tasks = accountToTasks.get(each.Id);
                            tasks.add(tsk);
                            accountToTasks.put(each.Id, tasks);
                        }
                    }
                }
            }
        }

        //Multiple site visit
        for(Park_Tour__c each: siteVisitList){
            Boolean matchMasterPlanCommWithTaskCommSite= false;
            //Check if all account related opps are closed and it have multiple site visits
            if(accountToCLosedOpps.containsKey(each.Account__c)){
                if(accountToComSiteToSiteVisit.containsKey(each.Account__c) && accountToComSiteToSiteVisit.get(each.Account__c) !=NULL){
                    Map<Id, Integer> commSiteToSiteVisits = accountToComSiteToSiteVisit.get(each.Account__c);
                    //Check if all contact related opps are closed and it have multiple site visits, or
                    //No need to compare the community sites in case of muliple site visits
                    //Check if contact had already Task and it has single site visit
                    Boolean createOpp= FALSE;
                    if(commSiteToSiteVisits.get(each.Adventure_Park__c) > 1){
                        createOpp= TRUE;
                    }
                    if(commSiteToSiteVisits.get(each.Adventure_Park__c) == 1 && accountToTasks != NULL && accountToTasks.containsKey(each.Account__c) && accountToTasks.get(each.Account__c) !=NULL){
                        createOpp= FALSE;
                        for(ActivityHistory eachTask: accountToTasks.get(each.Account__c)){
                            if(commSitesUnderMPC !=null && !commSitesUnderMPC.isEmpty() && String.isNotBlank(eachTask.Community_Site_Picklist__c)){
                                if(eachTask.Community_Site_Picklist__c.contains(';')){
                                    List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                    for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                        if(taskCommSites.contains(commSiteUnderMastePlannedComm)){
                                            matchMasterPlanCommWithTaskCommSite = true;
                                        }
                                    }
                                }else{ //If task with only one community site
                                    if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.toLowercase())){
                                        matchMasterPlanCommWithTaskCommSite = true;
                                    }
                                }
                            }

                            //Check if Contact had already Task and user visits the site with same community site same as Task's community site, and
                            //User visits the site on same date on which appointment is set
                            //Aakanksha 06-07-20 - Added Community marketing name condition as per SPDN-309
                            if(eachTask.Community_Site_Picklist__c != NULL && each.Community_site_name__c !=NULL && (eachTask.Community_Site_Picklist__c.toLowerCase().Contains(each.Community_site_name__c.toLowercase()) || matchMasterPlanCommWithTaskCommSite || (each.Community_Marketing_Name__c != null && eachTask.Community_Site_Picklist__c.toLowerCase().Contains(each.Community_Marketing_Name__c.toLowercase()))) && eachTask.ActivityDate == each.Arrival_Time__c.Date()){
                                createOpp= TRUE;
                                BREAK;
                            }
                        }
                    }
                    if(commSiteToSiteVisits.get(each.Adventure_Park__c) == 1){
                        createOpp = true;
                    }
                    //Create Opportunity
                    opportunityToCreated = createOppsUnderContactBasedUponSiteVisit(createOpp, each);
                }
            }
            //Check if all contact related opps are open
            if(accountToOpenOpps.containsKey(each.Account__c) && accountToComSiteToSiteVisit.containsKey(each.Account__c) && accountToComSiteToSiteVisit.get(each.Account__c) !=NULL){
                Map<Id, Integer> commSiteToSiteVisits = accountToComSiteToSiteVisit.get(each.Account__c);
                //Check open opportunities community site with site visit's community site
                //Need to compare for already existing open opportunity with same community site(Site Visit), so that no new open opportunity creates
                Boolean createOpp= FALSE;
                //Site Visit more than 1 and need to compare community site of open opportunities
                if(!accountToOpenOpps.get(each.Account__c).contains(each.Community_site_name__c) && commSiteToSiteVisits.get(each.Adventure_Park__c) > 1){
                    createOpp = TRUE;
                }
                if(!accountToOpenOpps.get(each.Account__c).contains(each.Community_site_name__c) && commSiteToSiteVisits.get(each.Adventure_Park__c) == 1 && accountToTasks != NULL && accountToTasks.containsKey(each.Account__c) && accountToTasks.get(each.Account__c) !=NULL){
                    createOpp= FALSE;
                    for(ActivityHistory eachTask: accountToTasks.get(each.Account__c)){
                        if(commSitesUnderMPC !=null && !commSitesUnderMPC.isEmpty() && String.isNotBlank(eachTask.Community_Site_Picklist__c)){
                            if(eachTask.Community_Site_Picklist__c.contains(';')){
                                List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';');
                                for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                    if(taskCommSites.contains(commSiteUnderMastePlannedComm)){
                                        matchMasterPlanCommWithTaskCommSite = true;
                                    }
                                }
                            }else{ //If task with only one community site
                                if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.toLowercase())){
                                    matchMasterPlanCommWithTaskCommSite = true;
                                }
                            }
                        }
                        //Compare Community site of site visits with the Task Community Site, and
                        //Check if user visits the site on same date on which appiontment is set
                        //Aakanksha 06-07-20 - Added Community marketing name condition as per SPDN-309
                        if(eachTask.Community_Site_Picklist__c != NULL && each.Community_site_name__c !=NULL && (eachTask.Community_Site_Picklist__c.toLowerCase().Contains(each.Community_site_name__c.toLowercase()) || matchMasterPlanCommWithTaskCommSite || (each.Community_Marketing_Name__c != null && eachTask.Community_Site_Picklist__c.toLowerCase().Contains(each.Community_Marketing_Name__c.toLowercase()))) && eachTask.ActivityDate == each.Arrival_Time__c.Date()){
                            createOpp= TRUE;
                            BREAK;
                        }
                    }
                }
                //Create opportunity
                opportunityToCreated = createOppsUnderContactBasedUponSiteVisit(createOpp, each);
            }

            //Account without opportunities
            if(accountOppIds !=NULL && !accountOppIds.isEmpty() && accountToComSiteToSiteVisit.containsKey(each.Account__c) && accountToComSiteToSiteVisit.get(each.Account__c) !=NULL){
                Map<Id, Integer> commSiteToSiteVisits = accountToComSiteToSiteVisit.get(each.Account__c);
                Boolean createOpp= FALSE;
                //Contact with no opportunities and site visits more than 1
                if(commSiteToSiteVisits.get(each.Adventure_Park__c) > 1){
                    createOpp = TRUE;
                }
                //Contact had already NHS Apoointment Task
                if(commSiteToSiteVisits.get(each.Adventure_Park__c) == 1 && accountToTasks != NULL && accountToTasks.containskey(each.Account__c) && accountToTasks.get(each.Account__c) !=NULL){
                    createOpp= FALSE;
                    for(ActivityHistory eachTask: accountToTasks.get(each.Account__c)){
                        if(commSitesUnderMPC !=null && !commSitesUnderMPC.isEmpty() && !commSitesUnderMPC.isEmpty() && String.isNotBlank(eachTask.Community_Site_Picklist__c)){
                            if(eachTask.Community_Site_Picklist__c.contains(';')){
                                List<String> taskCommSites = eachTask.Community_Site_Picklist__c.toLowercase().split(';'); //Converted to lowercase as per SPDN-448 - Aakanksha - 11-12-20
                                for(String commSiteUnderMastePlannedComm: commSitesUnderMPC){
                                    if(taskCommSites.contains(commSiteUnderMastePlannedComm.toLowerCase())){ //Converted to lowercase as per SPDN-448 - Aakanksha - 11-12-20
                                        matchMasterPlanCommWithTaskCommSite = true;
                                    }
                                }
                            }else{ //If task with only one community site

                                if(commSitesUnderMPC.contains(eachTask.Community_Site_Picklist__c.tolowercase())){ //Converted to lowercase as per SPDN-448 - Aakanksha - 11-12-20
                                    matchMasterPlanCommWithTaskCommSite = true;
                                }
                            }
                        }

                        //Check if Contact had already Task and user visits the site with same community site same as Task's community site, and
                        //User visits the site on same date on which appointment is set
                        //Aakanksha 06-07-20 - Added Community marketing name condition as per SPDN-309
                        if(eachTask.Community_Site_Picklist__c != NULL && each.Community_site_name__c !=NULL && (eachTask.Community_Site_Picklist__c.toLowerCase().Contains(each.Community_site_name__c.toLowercase()) || matchMasterPlanCommWithTaskCommSite || (each.Community_Marketing_Name__c != null && eachTask.Community_Site_Picklist__c.toLowerCase().Contains(each.Community_Marketing_Name__c.toLowercase()))) && eachTask.ActivityDate == each.Arrival_Time__c.Date()){
                            createOpp= TRUE;
                            BREAK;
                        }
                    }
                }
                if(commSiteToSiteVisits.get(each.Adventure_Park__c) == 1){
                    createOpp = true;
                }
                //Create Opportunity
                opportunityToCreated = createOppsUnderContactBasedUponSiteVisit(createOpp, each);
            }
        }
        return opportunityToCreated;
    }
    //</Modification>

    public static List<Opportunity> createOppsUnderContactBasedUponSiteVisit(Boolean opportunityToCreated, Park_Tour__c eachSiteVisit){
        if(opportunityToCreated){
            Opportunity opp = new Opportunity();
            opp.Name = 'Test Opp';
            //opp.Has_NHS_Appointment__c = true;
            opp.AccountId = eachSiteVisit.Account__c;
            opp.Contact_Name__c = eachSiteVisit.Contact__c;
            opp.Adventure_Park__c = eachSiteVisit.Adventure_Park__c;
            opp.StageName = 'Discovery';
            opp.CloseDate = system.today().addMonths(3);
            //Opportunity owner should be the NHA from the last Site Visit listed as per SPDN-102 ticket
            if(eachSiteVisit.New_Home_Advisor__c!=null)
                opp.OwnerId = eachSiteVisit.New_Home_Advisor__c;
            oppToInsert.add(opp);
        }
        return oppToInsert;
    }
    //</Addition> Anmol Baweja- 11-03-2019
}
