//=================================================================================================
// Company: TRI Pointe Group
//  Author: Michael Mock (Birlasoft)
// Created: 04/17/2017
// Comment: CommunitySite trigger calling CommunitySite Trigger Handler Class
//=================================================================================================
//          Date            Purpose
// Changes: 04/17/2017    Michael Mock (Birlasoft) Created
//=================================================================================================
trigger AdventurePark_Trigger on Adventure_Park__c (before insert, before update, before delete, after insert, after update, after delete) {

    //After Insert
    if (Trigger.isAfter && Trigger.isInsert) {
        // Akashdeep TPG-6384
        ServiceTerritoryHandler.createTerritory(trigger.new,trigger.newmap,null);
    }

    //Before Insert
    if(Trigger.isBefore && Trigger.isInsert) {
        CommunitySiteTriggerHandler.OnBeforeInsert(Trigger.new);
    }

    //Before Update
    if (Trigger.isBefore && Trigger.isUpdate) {
        CommunitySiteTriggerHandler.OnBeforeUpdate(Trigger.newMap,Trigger.oldMap);
    }

    //After Update
    if (Trigger.isAfter && Trigger.isUpdate) {
        //<Addition> Anmol Baweja 16-10-2018
        //<ReasonLead Lifecycle Project</Reason
        CommunitySiteTriggerHandler.OnAfterUpdate(Trigger.newMap,Trigger.oldMap);
        //</Addition>
        // Akashdeep TPG-6384
        ServiceTerritoryHandler.createTerritory(trigger.new,trigger.newmap,trigger.oldMap);
    }

    //After Delete
    if (Trigger.isAfter && Trigger.isDelete) {

    }

    //Before delete
    if (Trigger.isBefore && Trigger.isDelete) {

    }
}
