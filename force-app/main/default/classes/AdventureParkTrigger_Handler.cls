public with sharing class AdventureParkTrigger_Handler {

    public static void onBeforeUpdate(Map<Id, Adventure_Park__c> newMap, Map<Id, Adventure_Park__c> oldMap) {

        List<Adventure_Park__c> needPB = new List<Adventure_Park__c>();
        for (Adventure_Park__c park : newMap.values()) {
            if (park.Open_Date__c >= Date.today() && park.Is_Active__c == false) {
                park.Is_Active__c = true;
            }
            if (park.Price_Book__c == null) {
                needPB.add(park);
            }
            if (park.Is_Active__c == false && park.Open_Date__c > Date.today()) {
                park.Inactivated_Date__c = Date.today();
            }
        }
        getPricebooks(needPB);

    }

    public static void onBeforeInsert(List<Adventure_Park__c> parks) {

        List<Adventure_Park__c> needPB = new List<Adventure_Park__c>();
        for (Adventure_Park__c p : parks) {
            if (p.Price_Book__c == null) {
                needPB.add(p);
            }
        }
        getPricebooks(needPB);

    }

    private static void getPricebooks(List<Adventure_Park__c> needPB) {
        Map<Id, Pricebook2> pbMap = AdventureParkTrigger_Helper.createPB(needPB);
        for (Adventure_Park__c p : needPB) {
            if (pbMap.get(p.Id) != null) {
                p.Price_Book__c = pbMap.get(p.Id).Id;
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
                Adventure_Park__c = park.Id,
                AccountSource = 'Automation'
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

    public static void OnAfterUpdate(Map<Id, Adventure_Park__c> newMap, Map<Id, Adventure_Park__c> oldMap) {
        Set<Id> parksIds = new Set<Id>();
        for (Id parkId : newMap.keySet()) {
            if (newMap.get(parkId).Open_Date__c > Date.today() && newMap.get(parkId).Is_Active__c != oldMap.get(parkId).Is_Active__c && !newMap.get(parkId).Is_Active__c && newMap.get(parkId).Inactivated_Date__c != null) {
                parksIds.add(parkId);
            }
        }

        if (parksIds != null && !parksIds.isEmpty()) {
            List<Park_Of_Interest__c> parkOfInterests = new List<Park_Of_Interest__c>();
            for (Park_Of_Interest__c parkOfInterest: [
                SELECT Inactive__c, Adventure_Park__c
                FROM Park_Of_Interest__c
                WHERE Adventure_Park__c IN :oldMap.keySet()
            ]) {
                parkOfInterest.Inactive__c = true;
                parkOfInterest.Inactivated_Date__c = newMap.get(parkOfInterest.Adventure_Park__c).Inactivated_Date__c;
                parkOfInterests.add(parkOfInterest);
            }
            update parkOfInterests;
        }
    }
}
