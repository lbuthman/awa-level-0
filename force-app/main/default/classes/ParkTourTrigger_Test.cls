@IsTest
private class ParkTourTrigger_Test {
    @IsTest
    static void testLeadBehavior() {
        Adventure_Park__c adventurePark = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        insert adventurePark;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Last',
            Company = 'Acme'
        );
        insert lead;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id,
            Rating__c = 'Hot'
        );
        insert poi;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id
        );
        insert tour;

    }

    @IsTest
    static void testLeadBehavior2() {
        Adventure_Park__c adventurePark = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        insert adventurePark;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Last',
            Company = 'Acme'
        );
        insert lead;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id
        );
        insert tour;

        Park_Tour__c tour2 = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id
        );
        insert tour2;
    }

    @IsTest
    static void testLeadBehavior3() {
        Adventure_Park__c adventurePark = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        insert adventurePark;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Last',
            Company = 'Acme'
        );
        insert lead;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id,
            Rating__c = 'Hot'
        );
        insert poi;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id
        );
        insert tour;

        Park_Tour__c tour2 = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id
        );
        insert tour2;

        tour2.Park_Interest_Rating__c = 'Cold';
        update tour2;

    }

    @IsTest
    static void testContactBehavior() {
        Adventure_Park__c adventurePark = TestUtils.createNewPark('The Slippery Slopes', '123123123123');

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert contact;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id,
            Rating__c = 'Hot'
        );
        insert poi;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id
        );
        insert tour;
    }

    @IsTest
    static void testContactBehavior2() {
        Adventure_Park__c adventurePark = TestUtils.createNewPark('The Slippery Slopes', '123123123123');

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert contact;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id
        );
        insert tour;

        Park_Tour__c tour2 = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id
        );
        insert tour2;
    }

    @IsTest
    static void testContactBehavior3() {
        Adventure_Park__c adventurePark = TestUtils.createNewPark('The Slippery Slopes', '123123123123');

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert contact;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id,
            Rating__c = 'Hot'
        );
        insert poi;

        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id
        );
        insert tour;

        Park_Tour__c tour2 = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Contact__c = contact.Id
        );
        insert tour2;

        tour2.Park_Interest_Rating__c = 'Cold';
        update tour2;
    }
}