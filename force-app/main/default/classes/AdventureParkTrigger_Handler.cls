public with sharing class AdventureParkTrigger_Handler {

    public static void onBeforeUpdate(Map<Id, Adventure_Park__c> newMap, Map<Id, Adventure_Park__c> oldMap) {

        List<Adventure_Park__c> needPB = new List<Adventure_Park__c>();
        for (Adventure_Park__c cs : newMap.values()) {
            if (cs.Open_Date__c >= Date.today() && cs.Is_Active__c == false) {
                cs.Is_Active__c = true;
            }
            if (cs.Price_Book__c == null) {
                needPB.add(cs);
            }
        }
        getPricebooks(needPB);

    }

    public static void onBeforeInsert(List<Adventure_Park__c> comms) {

        List<Adventure_Park__c> needPB = new List<Adventure_Park__c>();
        for (Adventure_Park__c c : comms) {
            if (c.Price_Book__c == null) {
                needPB.add(c);
            }
        }
        getPricebooks(needPB);

    }

    private static void getPricebooks(List<Adventure_Park__c> needPB) {
        Map<Id, Pricebook2> pbMap = AdventureParkTrigger_Helper.createPB(needPB);
        for (Adventure_Park__c c : needPB) {
            if (pbMap.get(c.Id) != null) {
                c.Price_Book__c = pbMap.get(c.Id).Id;
            }
        }
    }

    public static void onAfterUpdate(Map<Id, Adventure_Park__c> newMap, Map<Id, Adventure_Park__c> oldMap) {
        Set<Id> commSiteIds = new Set<Id>();
        for (Id commId : newMap.keySet()) {
            if (newMap.get(commId).Open_Date__c != oldMap.get(commId).Open_Date__c ||
                newMap.get(commId).Is_Active__c != oldMap.get(commId).Is_Active__c
            ) {
                commSiteIds.add(commId);
            }
        }

        if (commSiteIds != null && !commSiteIds.isEmpty()) {
            //todo: close all related and inactivate all Parks of Interest
        }
    }
}
