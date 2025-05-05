//=================================================================================================
// Company: Apex Backwoods Adventures
// Author: Sarah Sandbox/Levi Logger
// Created: 6/20/2019
// Last modified: 8/4/20
// Comment: TempLeadTrigger_Handler created.
//=================================================================================================

public with sharing class TempLeadTrigger_Handler {

    public static Boolean avoidRecursion = false;
    public static Set<String> emailList = new Set<String>();

    public static void onAfterInsert(Map <Id,Temp_Lead__c> tempLeadRecords){
        Map<Id, String> contactsToEmail = new Map<Id, String>();
        Set<Id> sameLeadIds = new Set<Id>();
        Set<Id> sameConIds = new Set<Id>();
        Set<Id> accWithOppsInReview= new Set<Id>();
        Set<Id> contactsToUpdatePartially= new Set<Id>();
        Set<Id> ldIds = new Set<Id>();
        Set<Id> conIds = new Set<Id>();
        Set<String> lastNameList = new Set<String>();
        Set<String> firstNameList = new Set<String>();
        Set<String> tempLeadParkNumber = new Set<String>();
        Map<Id, Id> tempLeadToLead = new Map<Id, Id>();
        Map<Id, Id> templeadToContact = new Map<Id, Id>();
        Map<Id, Map<String, Id>> tempIdtoEmailtoParkId = new Map<Id, Map<String, Id>>();
        Map<Id, Map<Id, String>> tempIdToParkIdToRating = new Map<Id, Map<Id, String>>();
        Set<String> conEmail = new Set<String>();
        Set<String> conLastName = new Set<String>();
        Set<Id> accountIds = new Set<Id>();
        Boolean upsertLead = false;
        Boolean upsertContact= false;

        if(tempLeadRecords != null && !tempLeadRecords.isEmpty()){
            for(Temp_Lead__c tempLead : tempLeadRecords.values()){
                if(tempLead.Lead_Email__c != null && tempLead.Lead_Email__c != '')
                    emailList.add(tempLead.Lead_Email__c);
                if(tempLead.Lead_Last_Name__c!= null && tempLead.Lead_Last_Name__c != '')
                    lastNameList.add(tempLead.Lead_Last_Name__c);
                if(tempLead.Lead_First_Name__c!= null && tempLead.Lead_First_Name__c != '')
                    firstNameList.add(tempLead.Lead_First_Name__c);
                if(tempLead.Park_Number__c != null && tempLead.Park_Number__c !='')
                    tempLeadParkNumber.add(tempLead.Park_Number__c);
            }
        }

        if(tempLeadParkNumber != null && !tempLeadParkNumber.isEmpty()){
            for(Adventure_Park__c eachPark : [SELECT Id,Park_Number__c FROM Adventure_Park__c WHERE Park_Number__c IN : tempLeadParkNumber LIMIT 50000]){
                for(Temp_Lead__c eachTemp : tempLeadRecords.values()){
                    if(eachPark.Park_Number__c == eachTemp.Park_Number__c){
                        tempIdtoEmailtoParkId.put(eachTemp.Id,new Map<String, Id>{eachTemp.Lead_Email__c => eachPark.Id});
                        tempIdToParkIdToRating.put(eachTemp.Id,new Map<Id, String>{eachPark.Id => eachTemp.Lead_Rating__c});
                    }
                }
            }
        }
        //Added for update in below SOQLs to lock the record when it is being processed as per STDN-328 - Levi - 04-08-20
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT id, firstname, lastname, email, phone,
            MobilePhone, isConverted FROM lead WHERE isConverted = FALSE AND email IN: emailList AND lastName IN: lastNameList AND email != NULL LIMIT 50000 FOR UPDATE]);

        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT id,AccountId, firstname, lastname, email, phone, MobilePhone FROM Contact WHERE email IN: emailList AND lastName IN: lastNameList AND email != NULL LIMIT 50000 FOR UPDATE]);

        //<Addition> Levi - 01-05-20
        //<Reason> Scenario #1 - check in the LeadMap if more than one lead has similar email and lastname
        //if yes, compare it with the firstname of templead record
        //remove the lead from the LeadMap whose firstName does not match
        if(leadMap != null && !leadMap.isEmpty()){
            for(Integer j=0;j<=leadMap.values().size();j++){
                for(Integer i=0;i<=leadMap.values().size()-2;i++){
                    if(leadMap.values()[i].lastname == leadMap.values()[i+1].lastname && leadMap.values()[i].email == leadMap.values()[i+1].email){
                        if(leadMap.values()[i].firstname != leadMap.values()[i+1].firstname){

                            if(!firstNameList.contains(leadMap.values()[i].firstname) && lastNameList.contains(leadMap.values()[i].lastname) && emailList.contains(leadMap.values()[i].email))
                                sameLeadIds.add(leadMap.values()[i].Id);

                            if(!firstNameList.contains(leadMap.values()[i+1].firstname) && lastNameList.contains(leadMap.values()[i+1].lastname) && emailList.contains(leadMap.values()[i+1].email))
                                sameLeadIds.add(leadMap.values()[i+1].Id);

                        }
                    }
                }
            }
        }
        //</Reason>

        //<Reason> Scenario #2 - check in the contactMap if more than one contact has similar email and lastname
        //if yes, compare it with the firstname of templead record
        //remove the contact from the contactMap whose firstName does not match
        if(contactMap != null && !contactMap.isEmpty()){
            for(Integer j=0;j<=contactMap.values().size();j++){
                for(Integer i=0;i<=contactMap.values().size()-2;i++){
                    if(contactMap.values()[i].lastname == contactMap.values()[i+1].lastname && contactMap.values()[i].email == contactMap.values()[i+1].email){
                        if(contactMap.values()[i].firstname != contactMap.values()[i+1].firstname){

                            if(!firstNameList.contains(contactMap.values()[i].firstname) && lastNameList.contains(contactMap.values()[i].lastname) && emailList.contains(contactMap.values()[i].email))
                                sameConIds.add(contactMap.values()[i].Id);

                            if(!firstNameList.contains(contactMap.values()[i+1].firstname) && lastNameList.contains(contactMap.values()[i+1].lastname) && emailList.contains(contactMap.values()[i+1].email))
                                sameConIds.add(contactMap.values()[i+1].Id);

                        }
                    }
                }
            }
        }
        //</Reason>

        //<Reason> Scenario #3 - check if contact and lead has similar email and lastname
        //if yes, compare it with the firstname of templead record
        //remove the contact/lead from their respective maps whose firstName does not match
        if(leadMap != null && !leadMap.isEmpty() && contactMap != null && !contactMap.isEmpty()){
            for(Id eachLead : leadMap.keyset()){
                for(Id eachCon : contactMap.keyset()){
                    if(leadMap.get(eachLead) != null && contactMap.get(eachCon) != null){
                        if(leadMap.get(eachLead).email == contactMap.get(eachCon).email && leadMap.get(eachLead).lastName == contactMap.get(eachCon).lastName && leadMap.get(eachLead).firstName != contactMap.get(eachCon).firstName){
                            if(!firstNameList.contains(contactMap.get(eachCon).firstName) && lastNameList.contains(contactMap.get(eachCon).lastName) && emailList.contains(contactMap.get(eachCon).email))
                                sameConIds.add(eachCon);

                            if(!firstNameList.contains(leadMap.get(eachLead).firstName) && lastNameList.contains(leadMap.get(eachLead).lastName) && emailList.contains(leadMap.get(eachLead).email))
                                sameLeadIds.add(eachLead);

                        }
                    }
                }
            }
        }

        if(sameLeadIds != null && !sameLeadIds.isEmpty()){
            for(Id each : leadMap.keyset()){
                if(sameLeadIds.contains(each))
                    leadMap.remove(each);
            }
        }

        if(sameConIds != null && !sameConIds.isEmpty()){
            for(Id each : contactMap.keyset()){
                if(sameConIds.contains(each))
                    contactMap.remove(each);
            }
        }

        //</Addition> Levi - 01-05-20

        for(Temp_Lead__c temp : tempLeadRecords.values()){
            if(leadMap != null && !leadMap.isEmpty()){
                for(Lead lead : leadMap.values()){
                    if(temp.Lead_Email__c == lead.email && temp.Lead_Last_Name__c == lead.lastName){
                        tempLeadToLead.put(temp.Id, lead.Id);
                        ldIds.add(lead.Id);
                    }
                }
            }

            if(contactMap != null && !contactMap.isEmpty()){
                for(Contact con : contactMap.values()){
                    if(temp.Lead_Email__c == con.email && temp.Lead_Last_Name__c == con.lastName){
                        templeadToContact.put(temp.Id, con.Id);
                        conIds.add(con.Id);
                        accountIds.add(con.AccountId);
                        conEmail.add(con.email);
                        conLastName.add(con.lastName);
                    }
                }
            }
        }

        for(Account acc : [SELECT Id, (SELECT id,AccountId, StageName FROM opportunities) FROM Account WHERE Id IN : accountIds]){
            if(acc.Opportunities != null && !acc.Opportunities.isEmpty()){
                for(Opportunity opp : acc.Opportunities){
                    if(opp.StageName == 'Negotiation/Review'){
                        accWithOppsInReview.add(opp.AccountId);
                    }
                }
            }
        }

        for(Contact con : [SELECT Id,email,AccountId FROM Contact WHERE AccountId IN : accWithOppsInReview AND email != NULL]){
            contactsToUpdatePartially.add(con.Id);
            contactsToEmail.put(con.Id, con.email);
        }

        if(tempLeadToLead != null && !tempLeadToLead.isEmpty()){
            for(Id each : tempLeadToLead.keySet()){
                if(tempLeadToLead.containsKey(each) && tempLeadToLead.get(each) != null){
                    upsertLead = true;
                }
            }
        }

        if(templeadToContact != null && !templeadToContact.isEmpty()){
            for(Id each : templeadToContact.keySet()){
                if(templeadToContact.containsKey(each) && templeadToContact.get(each) != null){
                    upsertContact = true;
                }
            }
        }

        if(upsertLead && !upsertContact){
            upsertLeadData(tempLeadRecords,tempLeadToLead,ldIds,tempIdtoEmailtoParkId,conEmail,conLastName,tempIdToParkIdToRating);
        }
        if(!upsertLead){
            upsertLeadData(tempLeadRecords,tempLeadToLead,ldIds,tempIdtoEmailtoParkId,conEmail,conLastName,tempIdToParkIdToRating);
        }
        if(upsertContact && !upsertLead){
            upsertContactData(tempLeadRecords,templeadToContact,conIds,tempIdtoEmailtoParkId,tempIdToParkIdToRating,contactsToUpdatePartially,contactsToEmail);
        }
        if(upsertContact && upsertLead){
            upsertLeadData(tempLeadRecords,tempLeadToLead,ldIds,tempIdtoEmailtoParkId,conEmail,conLastName,tempIdToParkIdToRating);
            upsertContactData(tempLeadRecords,templeadToContact,conIds,tempIdtoEmailtoParkId,tempIdToParkIdToRating,contactsToUpdatePartially,contactsToEmail);
        }

    }

    public static String estimatedHouseHoldIncome(String s) {
        if (s != null) {
            s = s.replace('$', '').replace(',', '');
            s = s.trim();
            String[] s2 = new String[2];
            if (s.contains('+')) {
                s2[0] = '0';
                s2[1]=s.replace('+','');
            }
            else {
                s2 = s.split('-');
            }
            Integer[] income = new Integer[2];

            income[0] = integer.valueof(s2[0].trim());
            income[1] = integer.valueof(s2[1].trim());
            if (income[1] == null) {
                s = 'Under $64K';
            }
            else if (income[1] < 65000) {
                s = 'Under $64K';
            }
            else if (income[1]<= 99999) {
                s = '$65K-99K';
            }
            else if (income[1] <= 149999) {
                s = '$100K-149K';
            }
            else if (income[1] <= 199999) {
                s = '$150K-199K';
            }
            else if (income[1] <= 249999) {
                s = '$200K-249K';
            }
            else if (income[1] <= 299999) {
                s = '$250K-299K';
            }
            else {
                s = '$300K+';
            }
        }
        return s;
    }

    public static String adventureTimeFrame(String s) {
        if(s != null) {
            s = s.trim();
            String[] s2 = new String[2];
            s2 = s.split('/');
            Integer[] n = new Integer[2];
            n[0] = integer.valueof(s2[0].trim());
            n[1] = integer.valueof(s2[1].trim());
            Date moveInDate = Date.newInstance(n[1], n[0], 01);
            Date todaysDate = Date.today();
            Integer monthDiff = todaysDate.monthsBetween(moveInDate);

            //Insructed to round down the month difference.
            if (monthDiff <= 2) {
                s = '1 Month';
            }
            else if (monthDiff <= 5) {
                s = '3 Months';
            }
            else if (monthDiff <= 8) {
                s = '6 Months';
            }
            else if (monthDiff <= 11) {
                s = '9 Months';
            }
            else {
                s = '1 Year +';
            }
        }
        return s;
    }

    public static void upsertLeadData(Map<Id,Temp_Lead__c> ldTemp, Map<Id, Id> temptoLead,Set<Id> existingLeadIds,Map<Id, Map<String, Id>> TemptoEmailtoPark, Set<String> emailSet, Set<String> lastNameSet,Map<Id, Map<Id, String>> tempToParkToRating) {
        Set<String> leadEmail = new Set<String>();
        Set<String> leadLastName = new Set<String>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> existingParks = new Set<Id>();
        List<Park_Of_Interest__c> parksOfInterest = new List<Park_Of_Interest__c>();
        Map<String, Set<Id>> leadEmailtoParkId = new Map<String, Set<Id>>();
        Map<Id, Lead> tempLeadToLead= new Map<Id, Lead>();
        List<Temp_Lead__c> TempleadList = ldTemp.values();
        TempleadList.sort();
        //To sort the records in the latest created order
        List<Temp_Lead__c> finalList = new List<Temp_Lead__c>();
        for(Integer i = TempleadList.size()-1; i>=0;i--){
            finalList.add(TempleadList.get(i));
        }
        for(Temp_Lead__c ld :  finalList){
            if(((lastNameSet == null || lastNameSet.isEmpty()) && (emailSet == null || emailSet.isEmpty())) || (lastNameSet != null && !lastNameSet.isEmpty() && emailSet != null && !emailSet.isEmpty() && !lastNameSet.contains(ld.Lead_Last_Name__c) && !emailSet.contains(ld.Lead_Email__c))){
                Lead lead1 = new Lead(firstname = ld.Lead_First_Name__c, lastname = ld.Lead_Last_Name__c,
                    email = ld.Lead_Email__c, phone = ld.Lead_Phone_Number__c, id = temptoLead.get(ld.Id),
                    Vendor_Segment_Id__c = ld.Vendor_Segment_Id__c,
                    company = ld.Lead_Last_Name__c, Country =  ld.Lead_Country_Code__c,
                    State = ld.Lead_State__c, Street = ld.Lead_Street_Address__c, City = ld.Lead_City__c,  PostalCode = ld.Lead_Postal_Code__c);
                if(ld.Is_Agent__c){
                    lead1.Is_Agent__c = true;
                }

                //Update lead source
                if(temptoLead.get(ld.Id) != null){
                    lead1.Most_Recent_Lead_Source__c = ld.Lead_Source__c;
                }
                else{
                    lead1.LeadSource = ld.Lead_Source__c;
                    lead1.Most_Recent_Lead_Source__c = ld.Lead_Source__c;
                    lead1.Status = 'Known';
                }
                //Update HouseHold Income
                lead1.Household_Income__c = estimatedHouseHoldIncome(ld.Estimated_Household_Income__c);
                //Update adventure timeline.
                lead1.Adventure_Timeframe__c = adventureTimeFrame(ld.Lead_Adventure_Date__c);


                if(temptoLead.get(ld.Id) == null || (temptoLead.get(ld.Id) != null && !leadIds.contains(temptoLead.get(ld.Id)))){
                    if(!leadEmail.contains(ld.Lead_Email__c) && !leadLastName.contains(ld.Lead_Last_Name__c)){
                        tempLeadToLead.put(ld.Id, lead1);
                        leadEmail.add(ld.Lead_Email__c);
                        leadLastName.add(ld.Lead_Last_Name__c);
                    }
                }
                if(temptoLead.get(ld.Id) != null)
                    leadIds.add(temptoLead.get(ld.Id));
            }
        }

        if(tempLeadToLead != null && !tempLeadToLead.isEmpty())
            upsert tempLeadToLead.values();

        List<Lead> existingLeads = [SELECT Id,email, (SELECT Id, Lead__c,Rating__c, Adventure_Park__c,Adventure_Park__r.Park_Number__c,Adventure_Park__r.Name, Lead__r.lastName, Lead__r.email FROM Parks_Of_Interest__r WHERE Lead__c IN: existingLeadIds ) FROM Lead WHERE Id IN: existingLeadIds LIMIT 50000];

        for(Lead eachLead : existingLeads){
            if(eachLead.Parks_Of_Interest__r != null && !eachLead.Parks_Of_Interest__r.isEmpty()){
                for(Park_Of_Interest__c eachPOI :  eachLead.Parks_Of_Interest__r){
                    if(leadEmailtoParkId.containsKey(eachLead.email))
                        leadEmailtoParkId.get(eachLead.email).add(eachPOI.Adventure_Park__c);
                    else
                        leadEmailtoParkId.put(eachLead.email,new Set<Id>{eachPOI.Adventure_Park__c});
                }
            }
        }

        for(Park_Of_Interest__c existingPOIs : [SELECT Id, Lead__c,Rating__c, Adventure_Park__c,Adventure_Park__r.Park_Number__c,Adventure_Park__r.Name, Lead__r.lastName, Lead__r.email FROM Park_Of_Interest__c WHERE Lead__c IN: existingLeadIds LIMIT 50000]){
            for(Id each : ldTemp.keyset()){
                if(ldTemp.get(each).Lead_rating__c != null && ldTemp.get(each).Lead_rating__c != existingPOIs.Rating__c && ldTemp.get(each).Lead_email__c == existingPOIs.Lead__r.email && ldTemp.get(each).Lead_Last_Name__c == existingPOIs.Lead__r.lastName){
                    if((ldTemp.get(each).Park_Number__c != null && ldTemp.get(each).Park_Number__c == existingPOIs.Adventure_Park__r.Park_Number__c) || (ldTemp.get(each).Park_Number__c != null && ldTemp.get(each).Park_Number__c == existingPOIs.Adventure_Park__r.Park_Number__c))
                        //update rating of existing park of interst
                        existingPOIs.Rating__c = ldTemp.get(each).Lead_rating__c;
                    if(!parksOfInterest.contains(existingPOIs))
                        parksOfInterest.add(existingPOIs);
                }
            }
        }
        //<Addition> - 19-12-19- Levi
        //If multiple templead records are inserted at the same time having different park Id,
        //create POI records with those parks respectively
        for(Id each : tempLeadToLead.keyset()){
            for(Id eachId : TemptoEmailtoPark.keyset()){
                for(String eachEmail : TemptoEmailtoPark.get(eachId).keyset()){
                    if(existingLeadIds.contains(tempLeadToLead.get(each).id)){
                        if(eachEmail == tempLeadToLead.get(each).email){
                            for(String park :  TemptoEmailtoPark.get(eachId).values()){
                                if(leadEmailtoParkId != null && leadEmailtoParkId.containsKey(eachEmail) && leadEmailtoParkId.get(eachEmail) != null){
                                    //for(String eachEmailId : leadEmailtoParkId.keyset()){
                                    if(!leadEmailtoParkId.get(eachEmail).contains(park)){
                                        for(String POIrating : tempToParkToRating.get(eachId).values()){
                                            Park_Of_Interest__c poi = new Park_Of_Interest__c();
                                            poi.Adventure_Park__c = park;
                                            poi.Lead__c = tempLeadToLead.get(each).id;
                                            poi.Rating__c = POIrating;
                                            if(!parksOfInterest.contains(poi))
                                                parksOfInterest.add(poi);
                                        }
                                    }
                                    //  }
                                }else{
                                    for(String POIrating : tempToParkToRating.get(eachId).values()){
                                        Park_Of_Interest__c poi = new Park_Of_Interest__c();
                                        poi.Adventure_Park__c = park;
                                        poi.Lead__c = tempLeadToLead.get(each).id;
                                        poi.Rating__c = POIrating;
                                        if(!parksOfInterest.contains(poi))
                                            parksOfInterest.add(poi);
                                    }
                                }
                            }
                        }
                    }
                    if(!existingLeadIds.contains(tempLeadToLead.get(each).id)){
                        if(eachEmail == tempLeadToLead.get(each).email){
                            for(String park :  TemptoEmailtoPark.get(eachId).values()){
                                for(String POIrating : tempToParkToRating.get(eachId).values()){
                                    Park_Of_Interest__c poi = new Park_Of_Interest__c();
                                    poi.Adventure_Park__c = park;
                                    poi.Lead__c = tempLeadToLead.get(each).id;
                                    poi.Rating__c = POIrating;
                                    if(!parksOfInterest.contains(poi))
                                        parksOfInterest.add(poi);
                                }
                            }
                        }
                    }
                }
            }
        }
        parksOfInterest.sort();
        //To sort the records in the latest created order
        List<Park_Of_Interest__c> poiFinalList = new List<Park_Of_Interest__c>();
        for(Integer i = parksOfInterest.size()-1; i>=0;i--){
            poiFinalList.add(parksOfInterest.get(i));
        }

        for(Integer j=0;j<=poiFinalList.size();j++){
            for(Integer i=0;i<=poiFinalList.size()-2;i++){
                if(poiFinalList[i].Lead__c == poiFinalList[i+1].Lead__c){
                    if(poiFinalList[i].Adventure_Park__c == poiFinalList[i+1].Adventure_Park__c )
                        poiFinalList.remove(i+1);
                }
            }
        }

        //</Addition> 19-12-19
        if(poiFinalList != null && !poiFinalList.isEmpty())
            upsert poiFinalList;
    }

    public static void upsertContactData(Map<Id,Temp_Lead__c> ldTemp, Map<Id, Id> tempLeadtoContact,Set<Id> existingConIds, Map<Id, Map<String, Id>> TemptoEmailtoPark,Map<Id, Map<Id, String>> TempToParkToRating,Set<Id> conWithOppsInReview, Map<Id, String> conToEmail){
        Set<String> conEmail = new Set<String>();
        Set<String> conLastName = new Set<String>();
        Set<Id> existingParks = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Contact> tempParkToContact= new Map<Id, Contact>();
        List<Park_Of_Interest__c> poiList = new List<Park_Of_Interest__c>();
        Map<String, Set<Id>> conEmailtoParkId = new Map<String, Set<Id>>();
        //changes for integration ticket 311743 Added orderby to use index
        List<Account> agentAccounts = [SELECT Id, name FROM Account WHERE Type = 'Agent'  AND Email__c IN : emailList LIMIT 50000];
        //end changes

        List<Temp_Lead__c> TempleadList = ldTemp.values();
        TempleadList.sort();
        Contact con = new Contact();
        //To sort the records in the latest created order
        List<Temp_Lead__c> finalList = new List<Temp_Lead__c>();
        for(Integer i = TempleadList.size()-1; i>=0;i--){
            finalList.add(TempleadList.get(i));
        }
        for(Temp_Lead__c ld : finalList){
            if(tempLeadtoContact.get(ld.Id) != null){
                if(conWithOppsInReview == null || conWithOppsInReview.isEmpty()){
                    con = new Contact(firstname = ld.Lead_First_Name__c, lastname = ld.Lead_Last_Name__c,
                        email = ld.Lead_Email__c, phone = ld.Lead_Phone_Number__c, id = tempLeadtoContact.get(ld.Id),
                        Vendor_Segment_Id__c = ld.Vendor_Segment_Id__c,
                        MailingCountry = ld.Lead_Country_Code__c, MailingState = ld.Lead_State__c, MailingStreet = ld.Lead_Street_Address__c,
                        MailingCity = ld.Lead_City__c,  MailingPostalCode = ld.Lead_Postal_Code__c,
                        Most_Recent_Lead_Source__c = ld.Lead_Source__c);
                }else{
                    if(conToEmail != null && !conToEmail.isEmpty()){
                        con = new Contact(id = tempLeadtoContact.get(ld.Id), email = conToEmail.get(tempLeadtoContact.get(ld.Id)),
                            Vendor_Segment_Id__c = ld.Vendor_Segment_Id__c,
                            MailingCountry = ld.Lead_Country_Code__c, MailingState = ld.Lead_State__c, MailingStreet = ld.Lead_Street_Address__c,
                            MailingCity = ld.Lead_City__c,  MailingPostalCode = ld.Lead_Postal_Code__c,
                            Most_Recent_Lead_Source__c = ld.Lead_Source__c);
                    }
                }
                if(ld.Is_Agent__c){
                    if(agentAccounts!= null && !agentAccounts.isEmpty()){
                        for(Account acc : agentAccounts){
                            acc.Agent_First_Name__c = ld.Lead_First_Name__c;
                            acc.Agent_Last_Name__c = ld.Lead_Last_Name__c;
                            acc.Phone = ld.Lead_Phone_Number__c;
                        }
                    }
                }
                //Update house hold income.
                con.Household_Income__c = estimatedHouseHoldIncome(ld.Estimated_Household_Income__c);

                //Update adventure timeframe.
                con.Adventure_Timeframe__c = adventureTimeFrame(ld.Lead_Adventure_Date__c);

                if(tempLeadtoContact.get(ld.Id) == null || (tempLeadtoContact.get(ld.Id) != null && !contactIds.contains(tempLeadtoContact.get(ld.Id)))){
                    if(!conEmail.contains(con.Email) && !conLastName.contains(con.lastName)){
                        tempParkToContact.put(ld.Id,con);
                        conEmail.add(con.Email);
                        conLastName.add(con.lastName);
                    }

                }
                if(tempLeadtoContact.get(ld.Id) != null){
                    contactIds.add(tempLeadtoContact.get(ld.Id));
                }

            }
        }
        if(tempParkToContact != null && !tempParkToContact.isEmpty()){
            upsert tempParkToContact.values();
        }

        List<Contact> existingContacts = [SELECT Id,email, (SELECT Id, Contact__c,Rating__c, Adventure_Park__c,Adventure_Park__r.Park_Number__c,Adventure_Park__r.Name, Contact__r.lastName, Contact__r.email FROM Parks_Of_Interest__r WHERE Contact__c IN: existingConIds) FROM Contact WHERE Id IN: existingConIds LIMIT 50000];

        for(Contact eachCon : existingContacts){
            if(eachCon.Parks_Of_Interest__r != null && !eachCon.Parks_Of_Interest__r.isEmpty()){
                for(Park_Of_Interest__c eachPOI :  eachCon.Parks_Of_Interest__r){
                    if(conEmailtoParkId.containsKey(eachCon.email))
                        conEmailtoParkId.get(eachCon.email).add(eachPOI.Adventure_Park__c); //Map of existing contact's email to its POI reord's park
                    else
                        conEmailtoParkId.put(eachCon.email,new Set<Id>{eachPOI.Adventure_Park__c});
                }
            }
        }

        for(Park_Of_Interest__c existingPOIs : [SELECT Id, Contact__c,Rating__c, Adventure_Park__c,Adventure_Park__r.Park_Number__c,Adventure_Park__r.Name,Contact__r.lastName, Contact__r.email FROM Park_Of_Interest__c WHERE Contact__c IN: existingConIds LIMIT 50000]){
            for(Id each : ldTemp.keyset()){
                if(ldTemp.get(each).Lead_rating__c != null && ldTemp.get(each).Lead_rating__c != existingPOIs.Rating__c && ldTemp.get(each).Lead_email__c == existingPOIs.Contact__r.email && ldTemp.get(each).Lead_Last_Name__c == existingPOIs.Contact__r.lastName){
                    if((ldTemp.get(each).Park_Number__c != null && ldTemp.get(each).Park_Number__c == existingPOIs.Adventure_Park__r.Park_Number__c) || (ldTemp.get(each).Park_Number__c != null && ldTemp.get(each).Park_Number__c == existingPOIs.Adventure_Park__r.Park_Number__c))
                        //update rating of existing POI
                        existingPOIs.Rating__c = ldTemp.get(each).Lead_rating__c;
                    if(!poiList.contains(existingPOIs))
                        poiList.add(existingPOIs);
                }
            }
        }
        //<Addition> - 19-12-19- Levi
        //If multiple templead records are inserted at the same time having different park Id,
        //create POI records with those parks respectively
        for(Id each : tempParkToContact.keyset()){
            for(Id eachId : TemptoEmailtoPark.keyset()){
                for(String eachEmail : TemptoEmailtoPark.get(eachId).keyset()){
                    if(existingConIds.contains(tempParkToContact.get(each).id)){
                        if(eachEmail == tempParkToContact.get(each).email){
                            for(String park :  TemptoEmailtoPark.get(eachId).values()){
                                if(conEmailtoParkId != null && conEmailtoParkId.containsKey(eachEmail) && conEmailtoParkId.get(eachEmail) != null){
                                    //for(String eachEmailId : conEmailtoParkId.keyset()){
                                    if(!conEmailtoParkId.get(eachEmail).contains(park)){ //check if the park already exists
                                        for(String POIrating : TempToParkToRating.get(eachId).values()){
                                            Park_Of_Interest__c poi = new Park_Of_Interest__c();
                                            poi.Adventure_Park__c = park;
                                            poi.Contact__c = tempParkToContact.get(each).id;
                                            poi.Rating__c = POIrating;
                                            if(!poiList.contains(poi))
                                                poiList.add(poi);
                                        }
                                    }
                                    //}
                                }else{
                                    for(String POIrating : TempToParkToRating.get(eachId).values()){
                                        Park_Of_Interest__c poi = new Park_Of_Interest__c();
                                        poi.Adventure_Park__c = park;
                                        poi.Contact__c = tempParkToContact.get(each).id;
                                        poi.Rating__c = POIrating;
                                        if(!poiList.contains(poi))
                                            poiList.add(poi);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        //</Addition> 19-12-19

        poiList.sort();
        //To sort the records in the latest created order
        List<Park_Of_Interest__c> poiFinalList = new List<Park_Of_Interest__c>();
        for(Integer i = poiList.size()-1; i>=0;i--){
            poiFinalList.add(poiList.get(i));
        }

        for(Integer j=0;j<=poiFinalList.size();j++){
            for(Integer i=0;i<=poiFinalList.size()-2;i++){
                if(poiFinalList[i].Contact__c == poiFinalList[i+1].Contact__c ){
                    if(poiFinalList[i].Adventure_Park__c == poiFinalList[i+1].Adventure_Park__c )
                        poiFinalList.remove(i+1);
                }
            }
        }
        if(poiFinalList!= null && !poiFinalList.isEmpty())
            upsert poiFinalList;
    }
}
