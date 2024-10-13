//=================================================================================================
// Company: Apex Backwoods Adventure
//  Author: Levi Logger
// Created: 05/09/2016
// Comment: Park Tour Trigger Helper Class
//=================================================================================================
//          Date            Purpose
// Changes: 05/09/2016      Levi Logger Created
//          06/06/2016      Levi Logger added method for Return Visitors
//=================================================================================================

public without sharing class ParkTourTrigger_Helper {

    public static void getPOIrating(List<Park_Tour__c> tours){
        Set<Id> leadConIds = new Set<Id>();
        Set<Id> parkIds = new Set<Id>();

        for(Park_Tour__c pt : tours){
            if(pt.Lead__c != null){
                leadConIds.add(pt.Lead__c);
            }
            if(pt.Contact__c != null){
                leadConIds.add(pt.Contact__c);
            }
            if(pt.Adventure_Park__c != null){
                parkIds.add(pt.Adventure_Park__c);
            }
        }

        List<Park_Of_Interest__c> pois = new List<Park_Of_Interest__c> ();
        if(leadConIds != null && !leadConIds.isEmpty() && parkIds != null && !parkIds.isEmpty()){ //Added null check as per STDN-199 by Sarah - 02-04-20
            pois = [SELECT Id, Rating__c, Lead__c, Contact__c, Adventure_Park__c
                 FROM Park_Of_Interest__c WHERE
                (Lead__c IN :leadConIds OR Contact__c IN : leadConIds)
                AND Adventure_Park__c IN :parkIds ORDER BY CreatedDate DESC];
        }

        for(Park_Tour__c pt : tours){

            if(pt.Lead__c != null){
                for(Park_Of_Interest__c poi : pois){
                    if(pt.Lead__c == poi.Lead__c && pt.Adventure_Park__c == poi.Adventure_Park__c){
                        if(poi.Rating__c != null){
                            pt.Park_Interest_Rating__c = poi.Rating__c;
                        }
                        pt.POI_Synced_On_Insert__c = true;
                        break;
                    }
                }
            }

            if(pt.Contact__c != null){
                for(Park_Of_Interest__c poi : pois){
                    if(pt.Contact__c == poi.Contact__c && pt.Adventure_Park__c == poi.Adventure_Park__c){
                        if(poi.Rating__c != null){
                            pt.Park_Interest_Rating__c = poi.Rating__c;
                        }
                        pt.POI_Synced_On_Insert__c = true;
                        break;
                    }
                }
            }
        }
    }

    public static List<Park_Of_Interest__c> updatPOIRating(/*Set<Id> ptIds*/ List<Park_Tour__c> tours){//Passed park tour list to save one query - STDN-317 - Sarah - 09-07-20
        /*List<Park_Tour__c> tours = [Select Id, Lead__c, Adventure_Park__c, Contact__c,
                                      Park_Interest_Rating__c
                                      from Park_Tour__c where Id in :ptIds];*/

        Set<Id> communityIds = new Set<Id>();
        Set<Id> leadConIds = new Set<Id>();

        for(Park_Tour__c pt : tours){
            if(pt.Adventure_Park__c != null){
                communityIds.add(pt.Adventure_Park__c);
            }
            if(pt.Lead__c != null){
                leadConIds.add(pt.Lead__c);
            }
            if(pt.Contact__c != null){
                leadConIds.add(pt.Contact__c);
            }
        }
        List<Park_Of_Interest__c> pois = new List<Park_Of_Interest__c>();
        if(leadConIds != null && !leadConIds.isEmpty()){ //Added null check as per STDN-199 by Sarah - 02-04-20
            pois = [Select Id, Rating__c, Lead__c, Contact__c
            from Park_Of_Interest__c where Lead__c in :leadConIds OR Contact__c in :leadConIds];
        }

        List<Park_Of_Interest__c> poisForUpdate = new List<Park_Of_Interest__c>();

        for(Park_Tour__c pt : tours){
            if(pt.Lead__c != null){
                for(Park_Of_Interest__c poi : pois){
                    if(poi.Lead__c != null && poi.Lead__c == pt.Lead__c){
                        if(pt.Park_Interest_Rating__c != poi.Rating__c ){
                            poi.Rating__c = pt.Park_Interest_Rating__c;
                            poisForUpdate.add(poi);
                            break;
                        }
                    }
                }
            }

            if(pt.Contact__c != null){
                for(Park_Of_Interest__c poi : pois){
                    if(poi.Contact__c != null && poi.Contact__c == pt.Contact__c){
                        if(pt.Park_Interest_Rating__c != poi.Rating__c){
                            poi.Rating__c = pt.Park_Interest_Rating__c;
                            poisForUpdate.add(poi);
                            break;
                        }
                    }
                }
            }
        }
        return poisForUpdate;
    }

    public static void checkNewVisitor(List<Park_Tour__c> newtours){
        Set<Id> conIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();

        for(Park_Tour__c pt : newtours){
            if(pt.Lead__c != null){
                leadIds.add(pt.Lead__c);
            }
            if(pt.Contact__c != null){
                conIds.add(pt.Contact__c);
            }
        }

        if(leadIds.size() > 0){
            List<Lead> leads = [SELECT Id, (SELECT Id, Adventure_Park__c FROM Park_Tour__r) FROM Lead WHERE Id IN :leadIds];

            for(Park_Tour__c pt : newtours){
                if(pt.Lead__c != null){
                    for(Lead l : leads){
                        if(l.Id == pt.Lead__c){
                            if(l.Park_Tour__r.size() == 0){
                                break;
                            }else{
                                for(Park_Tour__c exTour : l.Park_Tour__r){
                                    if(exTour.Adventure_Park__c == pt.Adventure_Park__c){
                                        pt.Return_Visitor__c = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if(conIds.size() > 0){
            List<Contact> cons = [SELECT Id, AccountId, (SELECT Id, Adventure_Park__c FROM Park_Tour__r) FROM Contact WHERE Id IN :conIds];

            for(Park_Tour__c pt : newtours){
                if(pt.Contact__c != null){
                    for(Contact c : cons){
                        if(c.Id == pt.Contact__c){
                            //<Addition> - Flora - 31 July 2019
                            //<Reason> Added accountId in Site visit record when any user manually creates site visit record </Reason>
                            if(c.AccountId != null){
                                pt.Account__c = c.AccountId;
                            }
                            //</Addition> - Flora - 31 July 2019
                            if(c.Park_Tour__r.size() == 0){
                                break;
                            }else{
                                for(Park_Tour__c exTour : c.Park_Tour__r){
                                    if(exTour.Adventure_Park__c == pt.Adventure_Park__c){
                                        pt.Return_Visitor__c = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
