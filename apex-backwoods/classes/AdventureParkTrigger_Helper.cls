public with sharing class AdventureParkTrigger_Helper {

    public static Map<Id, Pricebook2> createPB(List<Adventure_Park__c> parks) {

        Map<Id, Pricebook2> pbMap = new Map<Id, Pricebook2>();
        List<Pricebook2> pbList = new List<Pricebook2>();
        for (Adventure_Park__c p : parks) {
            Pricebook2 pb = new Pricebook2();
            pb.Name = p.Name;
            pb.IsActive = true;
            pbList.add(pb);
            pbMap.put(p.Id, pb);
        }

        insert pbList;
        return pbMap;

    }
}
