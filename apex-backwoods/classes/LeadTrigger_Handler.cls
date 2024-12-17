public with sharing class LeadTrigger_Handler {

    public static Boolean isRunningOnce = true;
    public static Boolean alreadyRan = false;

    public void onBeforeInsert(List<Lead> newLeads) {
        LeadTrigger_Helper.captureStatusChangeDate(newLeads);
    }

    public void onAfterInsert(List<Lead> newLeads) {

        Set<Id> leadsForPark = new Set<Id>();
        Set<Id> leadsForParkDOG = new Set<Id>();
        Set<Id> agentLeads = new Set<Id>();
        Set<Id> newLeadIds = new Set<Id>();
        List<Park_Of_Interest__c> parksOfIntrstListToUpdate = new List<Park_Of_Interest__c>();

        for (Lead lead : newLeads) {
            newLeadIds.add(lead.Id);

            if (lead.Is_Agent__c == true) {
                agentLeads.add(lead.Id);
            }

            if (lead.Parks_Of_Interest__c != null && lead.LeadSource != 'DOG') {
                leadsForPark.add(lead.Id);
            }

            if (lead.Parks_Of_Interest__c != null && lead.LeadSource == 'DOG') {
                leadsForParkDOG.add(lead.Id);
            }
        }

        if (leadsForPark.size() > 0) {
            LeadTrigger_Helper.parkIntrestCreate(leadsForPark, true);
        }

        if (leadsForParkDOG.size() > 0) {
            LeadTrigger_Helper.parkIntrestCreateWithRatings(leadsForParkDOG, true);
        }

        if (parksOfIntrstListToUpdate.size() > 0) {
            update parksOfIntrstListToUpdate;
        }
    }

    public void onBeforeUpdate(Map<Id, Lead> triggerNewMap, Map<Id, Lead> oldLeadMap) {
        Map<Id, Lead> newLeadMap = new Map<Id, Lead>();
        for(Lead thisLead : triggerNewMap.values()){
            newLeadMap.put(thisLead.Id, thisLead);
        }
        if(newLeadMap.isEmpty()) return;

        List<Lead> LeadOwnersUpdate = new List<Lead>();
        List<Lead> leadsWStatusChange = new List<Lead>();

        for (Lead l : newLeadMap.values()) {
            Boolean isChangedFromCode = false;
            Lead oldLead = oldLeadMap.get(l.Id);

            if (l.Accept_Lead__c == true) {
                LeadOwnersUpdate.add(l);
            }

            //If Planner user edits the record then assign the lead to Planner user and change the status to 'Engaged'
            if (!isChangedFromCode &&
                !(oldLead.Reprocessed_Reason__c != l.Reprocessed_Reason__c) &&
                !(oldLead.Disinterested_Reason__c != l.Disinterested_Reason__c)
            ) {
                l.OwnerId = UserInfo.getUserId();
                l.Status = 'Engaged';
                isChangedFromCode = true;
            }
            if (
                (oldLead.Disinterested_Reason__c != l.Disinterested_Reason__c && l.Disinterested_Reason__c != null) ||
                    (l.Reprocessed_Reason__c != null && oldLead.Reprocessed_Reason__c != l.Reprocessed_Reason__c)
            ) {
                LeadTrigger_Helper.processReprocessedAndDisinterestedLeads(l, oldLead);
                isChangedFromCode = true;
            }
            if (oldLead.Status != l.Status) {
                leadsWStatusChange.add(l);
            }
        }

        if (!leadsWStatusChange.isEmpty()) {
            LeadTrigger_Helper.captureStatusChangeDate(leadsWStatusChange);
        }

        if (LeadOwnersUpdate.size() > 0) {
            LeadTrigger_Helper.reassignLead(LeadOwnersUpdate);
        }
    }

    public void OnAfterUpdate(Map<Id, Lead> triggerNewMap, Map<Id, Lead> oldLeadMap) {
        Map<Id, Lead> newLeadMap = new Map<Id, Lead>();
        for(Lead thisLead : triggerNewMap.values()){
            newLeadMap.put(thisLead.Id, thisLead);
        }
        if(newLeadMap.isEmpty()) return;

        Set<Id> LeadIdsForLTUpdate = new Set<Id>();
        Set<Id> leadsForParkDOG = new Set<Id>();
        Set<Id> leadsForPark = new Set<Id>();
        Set<Id> reprocessedLeadTasks = new Set<Id>();
        Set<Id> agentLeadIDSet = new Set<Id>();
        List<Park_Of_Interest__c> parkOfIntrstListToUpdate = new List<Park_Of_Interest__c>();

        for (Lead lead : newLeadMap.values()) {

            Lead oldLead = oldLeadMap.get(lead.Id);
            if (!lead.IsConverted) {
                if (lead.Reprocessed_Reason__c != null && lead.Reprocessed_Reason__c.left(9) == 'Different' &&
                    ((oldLead.Reprocessed_Reason__c == null) ||
                        (oldLead.Reprocessed_Reason__c != null && oldLead.Reprocessed_Reason__c.left(9) != 'Different'))) {
                    if (isRunningOnce) {
                        isRunningOnce = false;
                        reprocessedLeadTasks.add(lead.Id);
                    }
                }
            }

            if (lead.IsConverted) {
                LeadIdsForLTUpdate.add(lead.Id);
            }

            if (lead.Parks_Of_Interest__c != null && !lead.IsConverted && lead.Park_Of_Interest_Rating__c == null) {
                leadsForPark.add(lead.Id);
            }

            if (lead.Parks_Of_Interest__c != null && !lead.IsConverted && lead.Park_Of_Interest_Rating__c != null) {
                leadsForParkDOG.add(lead.Id);
            }
        }

        if (reprocessedLeadTasks.size() > 0) {
            LeadTrigger_Helper.assignPlannerTasks(reprocessedLeadTasks);
        }

        if (LeadIdsForLTUpdate.size() > 0) {
            LeadTrigger_Helper.startLeadConvertProcess(LeadIdsForLTUpdate);
        }

        if (leadsForPark.size() > 0) {
            LeadTrigger_Helper.parkIntrestCreate(leadsForPark, false);
        }

        if (leadsForParkDOG.size() > 0) {
            LeadTrigger_Helper.parkIntrestCreateWithRatings(leadsForParkDOG, false);
        }

        if (parkOfIntrstListToUpdate.size() > 0) {
            List<Park_Of_Interest__c> updatedPOIrecord = new List<Park_Of_Interest__c>();
            User userDetail = [SELECT Id, Name, Profile.Name, Division, CompanyName FROM User WHERE Id = :UserInfo.getUserId()];
            if (userDetail.Profile.Name == 'System Administrator' || userDetail.Profile.Name == 'Marketing Users') {
                update parkOfIntrstListToUpdate;
            }
            else {
                if (!updatedPOIrecord.isEmpty() && updatedPOIrecord != null && updatedPOIrecord.size() > 0) {
                    update updatedPOIrecord;
                }
            }
        }
    }

    public void OnBeforeDelete(Map<Id, Lead> oldLeadMap) {
        if (oldLeadMap != null && oldLeadMap.size() > 0) {
            List<Park_Of_Interest__c> interestForLeads = new List<Park_Of_Interest__c>([SELECT Id FROM Park_Of_Interest__c WHERE Lead__c IN :oldLeadMap.keySet()]);
            if (interestForLeads != null && !interestForLeads.isEmpty()) {
                delete interestForLeads;
            }
        }
    }
}
