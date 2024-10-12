public with sharing class EventHandler {

    public static void createOpeningEvents(List<Adventure_Park__c> newList, Map<Id, Adventure_Park__c> newmap, Map<Id, Adventure_Park__c> oldmap) {
        List<ServiceAppointment> InsertList = new List<ServiceAppointment>();
        List<ServiceAppointment> UpdateList = new List<ServiceAppointment>();
        Map<Id, ServiceAppointment> mapOfParkIdtoAppointment = new Map<Id, ServiceAppointment>();
        Map<Id, Account> accountByParkId = new Map<Id, Account>();
        for (Account account: [SELECT Adventure_Park__c FROM Account WHERE Adventure_Park__c IN :newList]) {
            accountByParkId.put(account.Adventure_Park__c, account);
        }
        Map<Id, Asset> assetsByAccount = new Map<Id, Asset>();
        for (Asset asset: [SELECT AccountId FROM Asset WHERE AccountId IN :accountByParkId.values()]) {
            assetsByAccount.put(asset.AccountId, asset);
        }
        Set<Id> csIds = new Set<Id>();
        for (Adventure_Park__c each : newList) {
            Adventure_Park__c oldRecord;
            if (oldmap != null && !oldmap.isEmpty()) {
                oldRecord = oldmap.get(each.Id);
            }
            if (each.Is_Active__c && Trigger.isInsert) {
                Account account = accountByParkId.get(each.Id);
                ServiceAppointment newRecord = new ServiceAppointment();
                newRecord.ParentRecordId = assetsByAccount.get(account.Id).Id;
                newRecord.Status = each.Open_Date__c == Date.today() ? 'In Progress' : 'Scheduled';
                //todo: do more with Service Appointment
                InsertList.add(newRecord);
            }

            if (oldRecord != null && (each.Is_Active__c != oldRecord.Is_Active__c)) {
                csIds.add(each.Id);

            }
        }
        System.debug('@@###' + mapOfParkIdtoAppointment);
        for (ServiceAppointment each : [SELECT Id, Account.Adventure_Park__c, Status FROM ServiceAppointment WHERE Account.Adventure_Park__c IN :csIds]) {
            mapOfParkIdtoAppointment.put(each.Account.Adventure_Park__c, each);
        }
        for (Adventure_Park__c each : newList) {
            Adventure_Park__c oldRecord;
            if (oldmap != null && !oldmap.isEmpty()) {
                oldRecord = oldmap.get(each.Id);
                if (((!each.Is_Active__c && oldRecord.Is_Active__c)) && mapOfParkIdtoAppointment != null && !mapOfParkIdtoAppointment.isEmpty() && mapOfParkIdtoAppointment.containsKey(each.Id)) {
                    ServiceAppointment updateRecord = mapOfParkIdtoAppointment.get(each.Id);
                    updateRecord.Status = 'None';
                    UpdateList.add(updateRecord);
                }
                if ((each.Is_Active__c && !oldRecord.Is_Active__c)) {
                    if (mapOfParkIdtoAppointment != null && !mapOfParkIdtoAppointment.isEmpty() && mapOfParkIdtoAppointment.containsKey(each.Id)) {
                        ServiceAppointment updateRecord = mapOfParkIdtoAppointment.get(each.Id);
                        updateRecord.Status = each.Open_Date__c == Date.today() ? 'In Progress' : 'Scheduled';
                        UpdateList.add(updateRecord);
                    }
                    else {
                        Account account = accountByParkId.get(each.Id);
                        ServiceAppointment newRecord = new ServiceAppointment();
                        newRecord.ParentRecordId = assetsByAccount.get(account.Id).Id;
                        newRecord.Status = each.Open_Date__c == Date.today() ? 'In Progress' : 'Scheduled';
                        //todo: do more with Service Appointment
                        InsertList.add(newRecord);
                    }
                }
            }
        }
        if (InsertList != null && !InsertList.isEmpty()) {
            insert InsertList;
        }
        if (UpdateList != null && !UpdateList .isEmpty()) {
            update UpdateList ;
        }
    }
}
