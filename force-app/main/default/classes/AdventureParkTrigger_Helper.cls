public with sharing class AdventureParkTrigger_Helper {

    public static Map<Id, Pricebook2> createPB(List<Adventure_Park__c> comms) {

        Map<Id, Pricebook2> pbMap = new Map<Id, Pricebook2>();
        List<Pricebook2> pbList = new List<Pricebook2>();
        for (Adventure_Park__c c : comms) {
            Pricebook2 pb = new Pricebook2();
            pb.Name = c.Name;
            pb.IsActive = true;
            pbList.add(pb);
            pbMap.put(c.Id, pb);
        }

        insert pbList;
        return pbMap;

    }
}
