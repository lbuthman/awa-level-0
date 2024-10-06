//=================================================================================================
// Company: Apex Backwoods Adventures
//  Author: Flora Flow
// Created: 07/28/2015
// Comment: Lead trigger calling Lead Trigger Handler Class
//=================================================================================================
//          Date            Purpose
// Changes: 07/28/2015    Flora Flow Created
//=================================================================================================
trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {

    if(Test.isRunningTest()){
        //Trigger Handler
        LeadTrigger_Handler handler = new LeadTrigger_Handler();
        //After Insert
        if (Trigger.isAfter && Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        }

        //Before Insert
        if (Trigger.isBefore && Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        }

        //Before Update
        if (Trigger.isBefore && Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }

        //After Update
        if (Trigger.isAfter && Trigger.isUpdate) {
            handler.OnAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }

        //Before delete
        /***Starts Here***   Code Added by Tristan for Park Of Interest changes on 18-11-2016 */
        if (Trigger.isBefore && Trigger.isDelete) {
            //if(checkRecursive.run!=null && checkRecursive.run==false){
            // checkRecursive.run = true;
            //}else{
            handler.OnBeforeDelete(Trigger.oldMap);
            // }
        }
        /***Ends Here***/
    }
}
