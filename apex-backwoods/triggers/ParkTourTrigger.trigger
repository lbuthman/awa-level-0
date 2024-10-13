trigger ParkTourTrigger on Park_Tour__c (before insert, before update, after insert, after update) {

    ParkTourTrigger_Handler handler = new ParkTourTrigger_Handler();

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            handler.onBeforeInsert(Trigger.new);
        }
    }

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.onAfterInsert(Trigger.new, Trigger.newMap);
        }
        if(Trigger.isUpdate){
            handler.onAfterUpdate(Trigger.newMap,Trigger.oldMap);
        }
    }
}
