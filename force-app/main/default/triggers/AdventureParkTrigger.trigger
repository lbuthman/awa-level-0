//=================================================================================================
// Company: Apex Backwoods Adventures
//  Author: Sarah Sandbox
// Created: 04/17/2017
// Comment: AdventurePark trigger calling Adventure Park Trigger Handler Class
//=================================================================================================
//          Date            Purpose
// Changes: 04/17/2017    Sarah Sandbox - Created
//=================================================================================================
trigger AdventureParkTrigger on Adventure_Park__c (before insert, before update, before delete, after insert, after update, after delete) {

    //After Insert
    if (Trigger.isAfter && Trigger.isInsert) {
        // Tristan TPP-6384
        AdventureParkTrigger_Handler.onAfterInsert(trigger.new);
        ServiceAppointmentHandler.createOpeningAppointments(trigger.new,trigger.newmap,null);
    }

    //Before Insert
    if(Trigger.isBefore && Trigger.isInsert) {
        AdventureParkTrigger_Handler.OnBeforeInsert(Trigger.new);
    }

    //Before Update
    if (Trigger.isBefore && Trigger.isUpdate) {
        AdventureParkTrigger_Handler.OnBeforeUpdate(Trigger.newMap,Trigger.oldMap);
    }

    //After Update
    if (Trigger.isAfter && Trigger.isUpdate) {
        //<Addition> Levi Logger 16-10-2018
        //<ReasonLead Lifecycle Project</Reason
        AdventureParkTrigger_Handler.OnAfterUpdate(Trigger.newMap,Trigger.oldMap);
        //</Addition>
        // Tristan TPP-6384
        ServiceAppointmentHandler.createOpeningAppointments(trigger.new,trigger.newmap,trigger.oldMap);
    }

    //After Delete
    if (Trigger.isAfter && Trigger.isDelete) {

    }

    //Before delete
    if (Trigger.isBefore && Trigger.isDelete) {

    }
}
