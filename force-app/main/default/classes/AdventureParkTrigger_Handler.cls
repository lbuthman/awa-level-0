public with sharing class AdventureParkTrigger_Handler {

    public static void onBeforeUpdate(Map<Id, Adventure_Park__c> newMap, Map<Id, Adventure_Park__c> oldMap) {

        List<Schema.FieldSetMember> fields = SObjectType.Adventure_Park__c.fieldSets.CalculatingFields.getFields();
        List<Adventure_Park__c> needPB = new List<Adventure_Park__c>();
        for (Adventure_Park__c cs : newMap.values()) {
            for (Schema.FieldSetMember f : fields) {
                if (cs.get(f.getFieldPath()) != oldMap.get(cs.Id).get(f.getFieldPath())) {
                    cs.RefreshProducts__c = true;
                }
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
        Map<Id, Pricebook2> pbMap = Methods_CommunitySite.createPB(needPB);
        for (Adventure_Park__c c : needPB) {
            if (pbMap.get(c.Id) != null) {
                c.Price_Book__c = pbMap.get(c.Id).Id;
            }
            c.RefreshProducts__c = true;
        }
    }

    public static void onAfterUpdate(Map<Id, Adventure_Park__c> newMap, Map<Id, Adventure_Park__c> oldMap) {
        Set<Id> commSiteIds = new Set<Id>();
        for (Id commId : newMap.keySet()) {
            if (newMap.get(commId).Open_for_Sales__c != oldMap.get(commId).Open_for_Sales__c ||
                newMap.get(commId).Active__c != oldMap.get(commId).Active__c ||
                newMap.get(commId).Sold_Out__c != oldMap.get(commId).Sold_Out__c
            ) {
                commSiteIds.add(commId);
            }
        }

        if (commSiteIds != null && !commSiteIds.isEmpty()) {
            Database.executeBatch(new CommSiteToLeadContactUpdateBatch(commSiteIds));
        }
    }
}
