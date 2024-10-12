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

    public static void onAfterInsert(List<Adventure_Park__c> newParks) {
        Pricebook2 standardPriceBook = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        List<Account> accounts = new List<Account>();
        List<Product2> products = new List<Product2>();
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        List<Asset> assets = new List<Asset>();
        for (Adventure_Park__c park : newParks) {

            Account account = new Account(
                Name = park.Name + ' Account',
                Adventure_Park__c = park.Id
            );
            accounts.add(account);

            Product2 product = new Product2(
                Name = park.Name + ' Product',
                IsActive = true
            );
            products.add(product);

            // Create a Pricebook Entry in the Standard Price Book
            PricebookEntry standardPBE = new PricebookEntry(
                Pricebook2Id = standardPriceBook.Id,
                Product2Id = product.Id,
                UnitPrice = park.Admission_Price__c,
                IsActive = true
            );
            pricebookEntries.add(standardPBE);

            // Create a Pricebook Entry in the Custom Price Book
            PricebookEntry customPBE = new PricebookEntry(
                Pricebook2Id = park.Price_Book__c,
                Product2Id = product.Id,
                UnitPrice = park.Admission_Price__c,
                IsActive = true
            );
            pricebookEntries.add(customPBE);

            Asset asset = new Asset(
                Name = park.Name + ' Asset',
                Product2Id = product.Id,
                AccountId = account.Id
            );
            assets.add(asset);
        }

        if (!accounts.isEmpty()) {
            insert accounts;
        }

        if (!products.isEmpty()) {
            insert products;
        }

        if (!pricebookEntries.isEmpty()) {
            insert pricebookEntries;
        }

        if (!assets.isEmpty()) {
            insert assets;
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
