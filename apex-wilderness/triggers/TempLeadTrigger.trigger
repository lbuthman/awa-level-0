//=================================================================================================
// Company: Apex Backwoods Adventures
// Author: Sarah Sandbox
// Created: 6/20/2019
// Comment: Temp_Lead__c Trigger
//=================================================================================================

trigger TempLeadTrigger on Temp_Lead__c (after insert, after update ) {
    Map<ID, Temp_Lead__c> newTempLeadMap = new Map<ID, Temp_Lead__c>();
    List<Temp_Lead__c> newTempLeadList = new List<Temp_Lead__c>();
    List<Temp_Lead__c> newTempListListUpdate = new List<Temp_Lead__c>();

    if(Trigger.isAfter && Trigger.isInsert){
        //<Modification> Levi - June 04, 2020 - CAT Integration Project changes
        //<Reason> Separate TempLead records on the basis of 'Lead Source' Type that whether records has inserted via DOG or CAT </Reason>
        for(Temp_Lead__c eachTempLead : Trigger.new){
            //<Modification> Levi - Nov 17, 2020 - If LeadSource is CAT then execute CAT related functionality otherwise execute DOG functionality - As per Tristan request in STDN-386
            /*if(eachTempLead.Lead_Source__C == 'DOG'){
                newTempLeadMap.put(eachTempLead.ID, eachTempLead);
            }
            else if(eachTempLead.Lead_Source__C == 'CAT'){
                newTempLeadList.add(eachTempLead);
            }
            else if(eachTempLead.Lead_Source__C == null || eachTempLead.Lead_Source__C != 'CAT' || eachTempLead.Lead_Source__C != 'DOG'){
                eachTempLead.addError('Please make sure you have entered correct Lead Source type');
            }*/
            if(eachTempLead.Lead_Source__C == null || eachTempLead.Lead_Source__C == ''){
                eachTempLead.addError('Please make sure you have entered Lead Source');
            }
            //</Modification> Levi - Nov 17, 2020
        }
        if(newTempLeadMap != null && !newTempLeadMap.isEmpty())
            TempLeadTrigger_Handler.onAfterInsert(newTempLeadMap);

        //</Modification> Levi - June 04, 2020
    }
    //<Addition> Levi - 24 July,2020 - CAT Integration Project changes on After Update
    if(Trigger.isAfter && Trigger.isUpdate && TempLeadTrigger_Handler.avoidRecursion == false){
        for(Temp_Lead__c eachTempLead : Trigger.new){
            if(eachTempLead.Lead_Source__C == 'CAT'){
                newTempListListUpdate.add(eachTempLead);
            }
        }
    }
    //</Addition> Levi - 24 July,2020
}
