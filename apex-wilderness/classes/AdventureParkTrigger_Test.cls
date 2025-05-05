@IsTest
private class AdventureParkTrigger_Test {
    @IsTest
    static void Test_creatingAPark() {
        Adventure_Park__c park = createPark();
        insert park;

        Adventure_Park__c parkNow = [SELECT Price_Book__c FROM Adventure_Park__c WHERE Id = :park.Id];
        Assert.isNotNull(parkNow.Price_Book__c);

        List<Account> accounts = [SELECT Id FROM Account WHERE Adventure_Park__c = :park.Id];
        Assert.areEqual(1, accounts.size());

        List<Product2> products = [SELECT Id FROM Product2 WHERE Adventure_Park__c = :parkNow.Id];
        Assert.areEqual(1, products.size());

        List<PricebookEntry> pricebookEntries = [SELECT Id FROM PricebookEntry WHERE Product2Id IN :products];
        Assert.areEqual(2, pricebookEntries.size());

        List<Asset> assets = [SELECT Id FROM Asset WHERE Product2Id IN :products];
        Assert.areEqual(1, assets.size());

    }

    @IsTest
    static void Test_updatingAPark() {
        Adventure_Park__c park = createPark();
        insert park;

        Lead lead = new Lead(FirstName='Test', LastName='Lead', Company = 'Acme');
        insert lead;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Lead__c = lead.Id,
            Adventure_Park__c = park.Id,
            Inactive__c = false
        );
        insert poi;

        park.Open_Date__c = Date.today();
        update park;

        Adventure_Park__c nowPark = [SELECT Is_Active__c FROM Adventure_Park__c WHERE Id = :park.Id];
        Assert.isTrue(nowPark.Is_Active__c, 'Opened park should be active.');

        park.Is_Active__c = false;
        park.Open_Date__c = Date.today().addDays(-1);
        update park;

        nowPark = [SELECT Inactivated_Date__c FROM Adventure_Park__c WHERE Id = :park.Id];
        Assert.areEqual(Date.today(), nowPark.Inactivated_Date__c);

        Park_Of_Interest__c nowPOI = [SELECT Inactive__c, Inactivated_Date__c FROM Park_Of_Interest__c WHERE Id = :poi.Id];
        Assert.isTrue(nowPOI.Inactive__c);
        Assert.areEqual(nowPark.Inactivated_Date__c, nowPOI.Inactivated_Date__c);
    }

    private static Adventure_Park__c createPark() {
        return new Adventure_Park__c(
            Name = 'Test Park',
            Park_Number__c = '123123123123'
        );
    }

    @TestSetup
    static void setup() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }
}
