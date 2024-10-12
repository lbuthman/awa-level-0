public with sharing class EventHandler {

    public static void createOpeningEvents(List<Adventure_Park__c> newList, Map<Id, Adventure_Park__c> newmap, Map<Id, Adventure_Park__c> oldmap) {
        List<ServiceTerritory> InsertList = new List<ServiceTerritory>();
        List<ServiceTerritory> UpdateList = new List<ServiceTerritory>();
        Map<Id, ServiceTerritory> mapOfCsIdtoTerritory = new Map<Id, ServiceTerritory>();
        List<ServiceTerritoryWorkType> InsertListSWT = new List<ServiceTerritoryWorkType>();
        List<OperatingHours> op = [SELECT Id, Name FROM OperatingHours WHERE Name LIKE '%US Hours%'];
        List<WorkType> leadWorkTypes = [SELECT Id, Name FROM WorkType WHERE Type__c = :'Lead'];
        Set<Id> csIds = new Set<Id>();
        for (Adventure_Park__c each : newList) {
            Adventure_Park__c oldRecord;
            if (oldmap != null && !oldmap.isEmpty()) {
                oldRecord = oldmap.get(each.Id);
            }
            if (each.Is_Active__c && each.Open_Date__c >= Date.today() && Trigger.isInsert) {
                ServiceTerritory newRecord = new ServiceTerritory();
                if (op != null && !op.isEmpty()) {
                    newRecord.OperatingHoursId = op[0].Id;
                }
                newRecord.Name = each.Name;
                newRecord.IsActive = true;
                newRecord.PostalCode = each.Postal_Code__c;
                newRecord.StateCode = each.State__c;
                newRecord.CountryCode = 'US';
                newRecord.Street = each.Address_Line_1__c;
                newRecord.City = each.City__c;
                newRecord.Adventure_Park__c = each.Id;
                InsertList.add(newRecord);
            }

            if (oldRecord != null && (each.Active__c != oldRecord.Active__c || each.Walk_In_Form_Available__c != oldRecord.Walk_In_Form_Available__c)) {
                csIds.add(each.Id);

            }
        }
        System.debug('@@###' + mapOfCsIdtoTerritory);
        for (ServiceTerritory each : [SELECT Id, Adventure_Park__c, IsActive FROM ServiceTerritory WHERE Adventure_Park__c IN :csIds]) {
            mapOfCsIdtoTerritory.put(each.Adventure_Park__c, each);
        }
        for (Adventure_Park__c each : newList) {
            Adventure_Park__c oldRecord;
            if (oldmap != null && !oldmap.isEmpty()) {
                oldRecord = oldmap.get(each.Id);
                if (((!each.Active__c && oldRecord.Active__c) || (!each.Walk_In_Form_Available__c && oldRecord.Walk_In_Form_Available__c)) && mapOfCsIdtoTerritory != null && !mapOfCsIdtoTerritory.isEmpty() && mapOfCsIdtoTerritory.containsKey(each.Id)) {
                    ServiceTerritory updateRecord = mapOfCsIdtoTerritory.get(each.Id);
                    updateRecord.IsActive = false;
                    UpdateList.add(updateRecord);
                }
                if ((each.Active__c && !oldRecord.Active__c && each.Walk_In_Form_Available__c) || (each.Walk_In_Form_Available__c && !oldRecord.Walk_In_Form_Available__c && each.Active__c)) {
                    if (mapOfCsIdtoTerritory != null && !mapOfCsIdtoTerritory.isEmpty() && mapOfCsIdtoTerritory.containsKey(each.Id)) {
                        ServiceTerritory updateRecord = mapOfCsIdtoTerritory.get(each.Id);
                        updateRecord.IsActive = true;
                        UpdateList.add(updateRecord);
                    }
                    else {
                        ServiceTerritory newRecord = new ServiceTerritory();
                        if (op != null && !op.isEmpty()) {
                            newRecord.OperatingHoursId = op[0].Id;
                        }
                        newRecord.Name = each.Name;
                        newRecord.IsActive = true;
                        newRecord.PostalCode = each.Postal_Code__c;
                        newRecord.StateCode = each.State__c;
                        newRecord.CountryCode = 'US';
                        newRecord.Street = each.Address_Line_1__c;
                        newRecord.City = each.City__c;
                        newRecord.Adventure_Park__c = each.Id;
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

        for (ServiceTerritory each : InsertList) {
            for (WorkType wt : leadWorkTypes) {
                ServiceTerritoryWorkType swt = new ServiceTerritoryWorkType();
                swt.ServiceTerritoryId = each.Id;
                swt.WorkTypeId = wt.Id;
                InsertListSWT.add(swt);
            }
        }
        if (InsertListSWT != null && !InsertListSWT .isEmpty()) {
            insert InsertListSWT;
        }
    }
}
