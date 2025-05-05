@IsTest
public class TestUtils {

    private static Boolean PRICE_BOOK_ACTIVATED = false;

    public static Adventure_Park__c createNewPark(String name, String parkNumber) {
        if (!PRICE_BOOK_ACTIVATED) {
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            update standardPricebook;
            PRICE_BOOK_ACTIVATED = true;
        }

        return new Adventure_Park__c(Name = name, Park_Number__c = parkNumber);
    }
}
