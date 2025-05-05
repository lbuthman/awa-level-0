//=================================================================================================
// Company: Apex Backwoods Adventures
// Author: Tristan Tracker
// Created: 05/27/2016
// Comment: Park Of Interest Trigger Handler Class for processing Park Of Interest triggers
//=================================================================================================
//          Date            Purpose
// Changes: 01/13/2016      Tristan Tracker  RFC#44885 Initial Developement
//          05/27/2016      Levi Logger RFC 59720 adding After Insert trigger methods calls
//=================================================================================================


trigger ParkOfInterestTrigger on Park_Of_Interest__c (before insert, before update, before delete,
    after insert, after update, after delete, after undelete) {

    ParkOfInterestTrigger_Handler handler = new ParkOfInterestTrigger_Handler();

    if(Trigger.isBefore && Trigger.isInsert) {
        handler.onBeforeInsert(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert && ParkOfInterestTrigger_Handler.avoidRecursion == false){ //Sarah, July 14, 2020 - Added recursion check as per STDN-317
        handler.onAfterInsert(Trigger.new, Trigger.newMap, Trigger.oldMap);  //<Addition> Flora - Sep 23, 2020 - Added newMap and oldMap as per STDN-395
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isUpdate && ParkOfInterestTrigger_Handler.avoidRecursionUpdate == false) { //<Addition> Flora - Sep 23, 2020 - Added recursion check as per STDN-395
        handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete && ParkOfInterestTrigger_Handler.avoidRecursionDelete == false){ //<Addition> Flora - Sep 23, 2020 - Added recursion check as per STDN-395
        handler.onAfterDelete(Trigger.old);
    }

    if(Trigger.isAfter && Trigger.isUndelete){
        handler.onAfterUnDelete(Trigger.new);
    }
}
