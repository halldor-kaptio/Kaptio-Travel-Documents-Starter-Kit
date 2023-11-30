/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 10-12-2023
 * @last modified by  : Kaptio Developer
**/

global with sharing class KTD_ComponentItinerarySummaryController implements KaptioTravel.IComponentHandler {

public Static KaptioTravel__Itinerary__c itinerary { get; private set; }
public List<DaySummaryDto> output { get; private set; }

public Map<String, String> iconByItemType { get; private set; }
public Map<String, String> iconByItemTypePDF { get; private set; }
public String dateFormatWeb { get; private set; }
public String dateFormatPdf { get; private set; }
public Boolean hasAccommodationOnLastDay {get;set;}

protected Id itineraryId { get; set; }
private static final String DATE_FORMAT_TYPE_WEB = 'LongMonthDayOfWeek';
private static final String DATE_FORMAT_TYPE_PDF = 'ShortMonthDayOfWeek';

public static Map<Id, List<String>> cruiseAndMdRailLocationsBySvcDep { get; set; }

global KTD_ComponentItinerarySummaryController(){
    this.output = new List<DaySummaryDto>();
    this.iconByItemType = KTD_DocumentHelper.getIconByItemType();
    this.iconByItemTypePDF = KTD_DocumentHelper.getIconByItemTypePDF();

    this.dateFormatWeb = 'EEEE d MMMM yyyy';
    this.dateFormatPdf = 'EEE d MMM yyyy';

    if(ApexPages.currentPage() != null){
        this.itineraryId = ApexPages.currentPage().getParameters().get('id');   

        if(Schema.KaptioTravel__Itinerary__c.SObjectType == this.itineraryId.getSobjectType()) {
            init(this.itineraryId);
        }
    }
}

public void init(Id p_id) {
    try {
        this.itineraryId = p_id;

        if (itinerary == null){

            itinerary = this.getItinerary();

            List<KaptioTravel__Itinerary_Item__c> itineraryItems = this.getItineraryLines();

            cruiseAndMdRailLocationsBySvcDep = getCruiseAndMultidayRailLocations(itineraryItems);

            //get days output
            this.getDaysOutput(itineraryItems);
            //get date format
            this.getDateFormat(itinerary.KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name);

        }
        

    } catch (Exception exc) {
        System.debug('ITIN SUM ERROR: ' + exc.getMessage() + '; Stack Trace: ' + exc.getStackTraceString());
    }
}

private void getDaysOutput(List<KaptioTravel__Itinerary_Item__c> p_itineraryItems) {
    Map<Date, List<KaptioTravel__Itinerary_Item__c>> itemsByDay = new Map<Date, List<KaptioTravel__Itinerary_Item__c>>();// all day's items except accommodations grouped by day
    Map<Date, List<KaptioTravel__Itinerary_Item__c>> accommodationsByDay = new Map<Date, List<KaptioTravel__Itinerary_Item__c>>();

    //set all trip dates
    for (Integer i = 0; i <= itinerary.KaptioTravel__Start_Date__c.daysBetween(itinerary.KaptioTravel__End_Date__c); i ++) {
        itemsByDay.put(itinerary.KaptioTravel__Start_Date__c.addDays(i), new List<KaptioTravel__Itinerary_Item__c>());
        accommodationsByDay.put(itinerary.KaptioTravel__Start_Date__c.addDays(i), new List<KaptioTravel__Itinerary_Item__c>());
    }

    hasAccommodationOnLastDay = false;
    for (KaptioTravel__Itinerary_Item__c itineraryItem : p_itineraryItems) {
        //group items by date
        if (itineraryItem.KaptioTravel__RecordTypeName__c != 'Accommodation') {
            itemsByDay.get(itineraryItem.KaptioTravel__DateFrom__c).add(itineraryItem);
        } else {
            accommodationsByDay.get(itineraryItem.KaptioTravel__DateFrom__c).add(itineraryItem);
            hasAccommodationOnLastDay = true;
        }
        

        //collect multi-day items
        if (itineraryItem.KaptioTravel__DateTo__c > itineraryItem.KaptioTravel__DateFrom__c) {

            for (Integer i = 1; i <= itineraryItem.KaptioTravel__DateFrom__c.daysBetween(itineraryItem.KaptioTravel__DateTo__c); i ++) {
                Date tempDate = itineraryItem.KaptioTravel__DateFrom__c.addDays(i);
                
                if (itineraryItem.KaptioTravel__RecordTypeName__c != 'Accommodation') { 
                    itemsByDay.get(tempDate).add(itineraryItem);
                }
                if (itineraryItem.KaptioTravel__RecordTypeName__c == 'Accommodation' && (itineraryItem.KaptioTravel__DateTo__c != tempDate || itineraryItem.KaptioTravel__DateTo__c == itinerary.KaptioTravel__End_Date__c) ) {
                    accommodationsByDay.get(tempDate).add(itineraryItem);
                }
            }
        }

    }

    for (Date day : itemsByDay.keySet()) {
        List<KaptioTravel__Itinerary_Item__c> dayItems = itemsByDay.get(day);
        //put accommodations at the end of day's items list
        dayItems.addAll(accommodationsByDay.get(day));

        this.output.add( new DaySummaryDto(
            (itinerary.KaptioTravel__Start_Date__c.daysBetween(day) + 1), day, dayItems) 
        );

    }
}

private void getDateFormat(String p_brandName) {
    List<KaptioDocumentDateFormat__mdt> dateFormatSettings = this.getKaptioDocumentDateFormat();
    
    for (KaptioDocumentDateFormat__mdt dfSettings : dateFormatSettings) {
        if (dfSettings.MasterLabel.equals(DATE_FORMAT_TYPE_WEB)){
            this.dateFormatWeb = (p_brandName == 'KTUK') ? dfSettings.DateFirst__c : dfSettings.MonthFirst__c;
        } else {
            this.dateFormatPdf = (p_brandName == 'KTUK') ? dfSettings.DateFirst__c : dfSettings.MonthFirst__c;
        }
    }
}

private static Map<Id, List<String>> getCruiseAndMultidayRailLocations(List<KaptioTravel__Itinerary_Item__c> p_itineraryItems) {
    Map<Id, List<String>> result = new Map<Id, List<String>>();

    Map<Id, String> locationTypeByLocationId = new Map<Id, String>();
    Set<Id> serviceDeparturesIds = new Set<Id>();
    Map<Id, Integer> serviceDurationByServiceDepartureId = new Map<Id, Integer>();
    for (KaptioTravel__Itinerary_Item__c service : p_itineraryItems) {
        if ( (service.KaptioTravel__RecordTypeName__c == 'Cruise' || service.KaptioTravel__RecordTypeName__c == 'MultidayRail') && service.KaptioTravel__ServiceDeparture__c != null) {
            serviceDeparturesIds.add(service.KaptioTravel__ServiceDeparture__c);
            serviceDurationByServiceDepartureId.put(service.KaptioTravel__ServiceDeparture__c, service.KaptioTravel__DateFrom__c.daysBetween(service.KaptioTravel__DateTo__c) + 1);
        }
    }

    if (serviceDeparturesIds.size() != 0){
        
        List<KaptioTravel__ServiceDepartureLocation__c> sdLocations = getServiceDepartureLocation(serviceDeparturesIds);

        for (KaptioTravel__ServiceDepartureLocation__c sdLocation : sdLocations) {
            locationTypeByLocationId.put(sdLocation.KaptioTravel__EndLocation__c, sdLocation.KaptioTravel__EndLocation__r.KaptioTravel__RecordTypeDeveloperName__c);
        }

        Map<Id, Id> cityIdByChildLocation = KTD_DocumentHelper.getLocations(locationTypeByLocationId, 'City');
        Map<Id, KaptioTravel__Location__c> cityById = new Map<Id, KaptioTravel__Location__c>(getLocation(cityIdByChildLocation.values()));

        for (KaptioTravel__ServiceDepartureLocation__c sdLocation : sdLocations) {
            if (result.get(sdLocation.KaptioTravel__ServiceDeparture__c) == null) {
                result.put(sdLocation.KaptioTravel__ServiceDeparture__c, new String[serviceDurationByServiceDepartureId.get(sdLocation.KaptioTravel__ServiceDeparture__c)]);
            } 
            result.get(sdLocation.KaptioTravel__ServiceDeparture__c).add((Integer)(sdLocation.KaptioTravel__Day__c - 1), cityById.get(cityIdByChildLocation.get(sdLocation.KaptioTravel__EndLocation__c)).Name);
        }
    }
    
    return result;
}


public String getBody() {
    PageReference pref = Page.KTD_ComponentItinerarySummary;
    pref.getParameters().put('id', itineraryId);
    Blob content = System.Test.isRunningTest() ? Blob.valueOf('Test') : pref.getContent();

    return  content.toString();
}

public Boolean isEmpty(){
    return false;
}

private KaptioTravel__Itinerary__c getItinerary(){
    return 
        [SELECT 
            Id, 
            OwnerId, 
            KaptioTravel__Start_Date__c, 
            KaptioTravel__End_Date__c, 
            KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name
        FROM 
            KaptioTravel__Itinerary__c
        WHERE 
            Id = :this.itineraryId
        WITH SECURITY_ENFORCED];
}

private List<KaptioTravel__Itinerary_Item__c> getItineraryLines(){
    return
        [SELECT 
            Id, 
            KaptioTravel__DateFrom__c, 
            KaptioTravel__DateTo__c, 
            KaptioTravel__ExternalItemName__c, 
            KaptioTravel__ExternalName__c,
            KaptioTravel__RecordTypeName__c, 
            KaptioTravel__Item__r.KaptioTravel__Location__r.Name, 
            KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__Location__r.Name, 
            KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.Name,
            KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__RecordTypeDeveloperName__c,
            KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__RecordTypeDeveloperName__c, 
            KaptioTravel__ServiceDeparture__r.KaptioTravel__Ship__r.Name, KaptioTravel__ServiceDeparture__c, 
            KaptioTravel__Item__c, 
            KaptioTravel__CarDropOffLocation__c, 
            KaptioTravel__CarDropOffLocation__r.KaptioTravel__Location__c, 
            KaptioTravel__CarDropOffLocation__r.KaptioTravel__Location__r.RecordType.DeveloperName, 
            KaptioTravel__Quantity__c,
            KaptioTravel__Price_Category__c,
            (SELECT 
                Id, 
                KaptioTravel__DepartureDate__c, 
                KaptioTravel__AirlineFSCode__c, 
                KaptioTravel__FlightNumber__c, 
                KaptioTravel__DepartureAirportName__c, 
                KaptioTravel__ArrivalAirportName__c,
                KaptioTravel__Airline__r.Name, 
                KaptioTravel__OperatedBy__c, 
                KaptioTravel__OperatedBy__r.Name, 
                KaptioTravel__DepartureTime__c, 
                KaptioTravel__ArrivalDate__c, 
                KaptioTravel__ArrivalTime__c,
                KaptioTravel__TravelClass__c, 
                KaptioTravel__PNR__c, 
                KaptioTravel__ArrivalAirport__r.RecordType.DeveloperName, 
                KaptioTravel__ArrivalAirport__c, 
                KaptioTravel__ItineraryItem__c
            FROM 
                KaptioTravel__Itinerary_Flight_Legs__r
            ORDER BY KaptioTravel__DepartureDate__c, KaptioTravel__DepartureTime__c),
            (SELECT 
                Id, 
                KaptioTravel__DepartureDate__c, 
                KaptioTravel__FlightNumber__c, 
                KaptioTravel__DepartureAirport__r.Name, 
                KaptioTravel__ArrivalAirport__r.Name,
                KaptioTravel__Airline__r.Name, 
                KaptioTravel__OperatedBy__c, 
                KaptioTravel__OperatedBy__r.Name, 
                KaptioTravel__DepartureTime__c, 
                KaptioTravel__ArrivalDate__c, 
                KaptioTravel__ArrivalTime__c,
                KaptioTravel__TravelClass__c, 
                KaptioTravel__VendorLocator__c, 
                KaptioTravel__ArrivalAirport__r.RecordType.DeveloperName, 
                KaptioTravel__ArrivalAirport__c, 
                KaptioTravel__ItineraryItem__c,
                KaptioTravel__ArrivalTerminal__c, 
                KaptioTravel__DepartureTerminal__c
            FROM 
                KaptioTravel__PNRFlightSegments__r
            ORDER BY KaptioTravel__DepartureDate__c, KaptioTravel__DepartureTime__c)
        FROM 
            KaptioTravel__Itinerary_Item__c
        WHERE 
            KaptioTravel__Mode__c = 'Active'
        AND 
            KaptioTravel__IsVisible__c = true
        AND 
            KaptioTravel__Itinerary__c = :this.itineraryId
        WITH SECURITY_ENFORCED
        ORDER BY KaptioTravel__DateFrom__c, KaptioTravel__Order__c, KaptioTravel__TimeFrom__c ASC NULLS last, Name];
}

private List<KaptioDocumentDateFormat__mdt> getKaptioDocumentDateFormat(){
    return
        [SELECT 
            Id, 
            MasterLabel, 
            DateFirst__c, 
            MonthFirst__c 
        FROM 
            KaptioDocumentDateFormat__mdt 
        WHERE 
            MasterLabel IN (:DATE_FORMAT_TYPE_WEB, :DATE_FORMAT_TYPE_PDF) 
        WITH SECURITY_ENFORCED];
}

private static List<KaptioTravel__ServiceDepartureLocation__c> getServiceDepartureLocation(Set<Id> serviceDeparturesIds){
    return
        [SELECT 
            KaptioTravel__Day__c, 
            KaptioTravel__ServiceDeparture__c,
            KaptioTravel__EndLocation__r.Name,  
            KaptioTravel__EndLocation__c, 
            KaptioTravel__EndLocation__r.KaptioTravel__RecordTypeDeveloperName__c 
        FROM 
            KaptioTravel__ServiceDepartureLocation__c 
        WHERE  
            KaptioTravel__ServiceDeparture__c IN :serviceDeparturesIds 
        WITH SECURITY_ENFORCED
        ORDER BY KaptioTravel__Day__c ASC ];
}

private static List<KaptioTravel__Location__c> getLocation(List<id> locationIds){
    return 
        [SELECT 
            Id, 
            Name 
        FROM 
            KaptioTravel__Location__c
        WHERE 
            Id IN :locationIds
        WITH SECURITY_ENFORCED];
}

public class DaySummaryDto {
    public Integer dayNumber { get; set; }
    public Date currentDate { get; set; }
    public String locationOutput { get; set; }
    public String allocationOutput { get; set; }
    public List<KaptioTravel__Itinerary_Item__c> dayItems { get; set; }
    public Boolean startsOnLastDay {get;set;}
    public Map<Id, List<KTD_DocumentHelper.FlightLegDto>> flightLegMap {get;set;}

    public Map<String, List<String>> priceCategoriesByItem { get; set; }
    public Map<String, Decimal> qntyByPriceCategory { get; set; }
    public Map<Id, Integer> dateDiffByFlightLegId { get; set; }

    public DaySummaryDto(Integer p_dayNumber, Date p_day, List<KaptioTravel__Itinerary_Item__c> p_dayItems) {
        this.dayNumber = p_dayNumber;
        this.currentDate = p_day;
        this.dayItems = p_dayItems;

        this.locationOutput = '';
        this.allocationOutput = '';

        //remove duplicates
        this.priceCategoriesByItem = new Map<String, List<String>>();
        this.qntyByPriceCategory = new Map<String, Decimal>();
        this.dayItems = checkDuplicateItems(this.dayItems);

        //collect items by record type
        Map<String, List<KaptioTravel__Itinerary_Item__c>> itemsByRecordType = new Map<String, List<KaptioTravel__Itinerary_Item__c>>();
        this.startsOnLastDay = false;
        for (KaptioTravel__Itinerary_Item__c item : this.dayItems) {
            if (!itemsByRecordType.containsKey(item.KaptioTravel__RecordTypeName__c)) {
                itemsByRecordType.put(item.KaptioTravel__RecordTypeName__c, new List<KaptioTravel__Itinerary_Item__c>());
            }
            itemsByRecordType.get(item.KaptioTravel__RecordTypeName__c).add(item);

            if (p_day == itinerary.KaptioTravel__End_Date__c){

                if  ((item.KaptioTravel__DateFrom__c == itinerary.KaptioTravel__End_Date__c) || (item.KaptioTravel__RecordTypeName__c == 'Car_Rental') || 
                     (item.KaptioTravel__RecordTypeName__c == 'Cruise') || (item.KaptioTravel__RecordTypeName__c == 'MultidayRail') ||
                     (item.KaptioTravel__RecordTypeName__c == 'FlightPlaceholder') || (item.KaptioTravel__RecordTypeName__c == 'PNRFlight'))
                    startsOnLastDay = true;
            }
        }

        Boolean flightOnLastTwoDays = false;
        Boolean flightOnLastDay = false;
        for (Integer i = 0; i < this.dayItems.size(); i++) {
            KaptioTravel__Itinerary_Item__c item = this.dayItems.get(i);
            if ((item.KaptioTravel__RecordTypeName__c == 'FlightPlaceholder') || (item.KaptioTravel__RecordTypeName__c == 'PNRFlight')){
                List<KTD_DocumentHelper.FlightLegDto> flightLegList = KTD_DocumentHelper.getFlightLegs(item);
                if ((p_day == (itinerary.KaptioTravel__End_Date__c - 1)) &&
                    (flightLegList.size() != 0) && 
                    (flightLegList.get(0).departureDate == (itinerary.KaptioTravel__End_Date__c - 1)) &&
                    (flightLegList.get(flightLegList.size() - 1).arrivalDate == itinerary.KaptioTravel__End_Date__c))
                    flightOnLastTwoDays = true;
                else if ((p_day == itinerary.KaptioTravel__End_Date__c) &&
                        (flightLegList.size() != 0) && 
                        (flightLegList.get(0).departureDate == itinerary.KaptioTravel__End_Date__c) &&
                        (flightLegList.get(flightLegList.size() - 1).arrivalDate == itinerary.KaptioTravel__End_Date__c))
                        flightOnLastDay = true;
            }
        }

        //get location output
        this.getLocationOutput(itemsByRecordType, currentDate, flightOnLastTwoDays);
        //get allocation output
        this.getAllocationOutput(itemsByRecordType, currentDate);
        
        this.dateDiffByFlightLegId = new Map<Id, Integer>();
        this.flightLegMap = new Map<Id, List<KTD_DocumentHelper.FlightLegDto>>();
        for (Integer i = 0; i < this.dayItems.size(); i++) {
            KaptioTravel__Itinerary_Item__c item = this.dayItems.get(i);

            if ((item.KaptioTravel__RecordTypeName__c == 'FlightPlaceholder') || (item.KaptioTravel__RecordTypeName__c == 'PNRFlight')) {
                List<KTD_DocumentHelper.FlightLegDto> flightLegList = KTD_DocumentHelper.getFlightLegs(item);
                this.flightLegMap.put(item.Id, flightLegList);
                for (KTD_DocumentHelper.FlightLegDto flightLeg : flightLegList) {
                    if (!String.isEmpty(flightLeg.arrivalTerminal))
                        flightLeg.arrivalTerminal = 'Terminal ' + flightLeg.arrivalTerminal;
                    if (!String.isEmpty(flightLeg.departureTerminal))
                        flightLeg.departureTerminal = 'Terminal ' + flightLeg.departureTerminal;
                    if (flightLeg.arrivalDate != null)
                        this.dateDiffByFlightLegId.put(flightLeg.Id, flightLeg.departureDate.daysBetween(flightLeg.arrivalDate));
                    else
                        this.dateDiffByFlightLegId.put(flightLeg.Id, 0);
                }
            }
            
            if ( (item.KaptioTravel__RecordTypeName__c == 'Accommodation' || 
                 ((item.KaptioTravel__RecordTypeName__c == 'Cruise' || item.KaptioTravel__RecordTypeName__c == 'MultidayRail') && 
                  (p_day != itinerary.KaptioTravel__End_Date__c) /*|| (!flightOnLastDay))*/ && 
                  ((p_day != (itinerary.KaptioTravel__End_Date__c - 1)) || (!flightOnLastTwoDays)))) && 
                item.KaptioTravel__DateTo__c == p_day) {
                //remove Accommodation/Cruise/MultidayRail from check-out day
                this.dayItems.remove(i);
                i --;
            }
        }
    }

    public List<KaptioTravel__Itinerary_Item__c> checkDuplicateItems(List<KaptioTravel__Itinerary_Item__c> p_dayItems) {
        for (Integer i = 0; i < p_dayItems.size(); i++) {
            KaptioTravel__Itinerary_Item__c dayItem = p_dayItems.get(i);

            if (dayItem.KaptioTravel__RecordTypeName__c == 'FlightPlaceholder' || dayItem.KaptioTravel__RecordTypeName__c == 'PNRFlight') {
                continue;
            }

            String key1 = dayItem.KaptioTravel__Item__c + '_' + dayItem.KaptioTravel__ExternalItemName__c;  
            String key2 = dayItem.KaptioTravel__Item__c + '_' + dayItem.KaptioTravel__ExternalName__c;  

            if ( ! priceCategoriesByItem.containsKey(key1)) {
                this.priceCategoriesByItem.put(key1, new List<String>{dayItem.KaptioTravel__ExternalName__c});
                this.qntyByPriceCategory.put(key2, dayItem.KaptioTravel__Quantity__c);
            } else {
                if (!this.priceCategoriesByItem.get(key1).contains(dayItem.KaptioTravel__ExternalName__c)) {
                    this.priceCategoriesByItem.get(key1).add(dayItem.KaptioTravel__ExternalName__c);
                    this.qntyByPriceCategory.put(key2, dayItem.KaptioTravel__Quantity__c);
                } else {
                    this.qntyByPriceCategory.put(key2, this.qntyByPriceCategory.get(key2) + dayItem.KaptioTravel__Quantity__c);
                }

                p_dayItems.remove(i);
                i --;
            }
        }

        return p_dayItems;
    }

    public void getLocationOutput(Map<String, List<KaptioTravel__Itinerary_Item__c>> p_itemsByRecordType, Date crDate, Boolean flightOnLastTwoDays) {
        

        if (crDate == itinerary.KaptioTravel__End_Date__c){

            if ((!p_itemsByRecordType.containsKey('FlightPlaceholder')) && (!p_itemsByRecordType.containsKey('PNRFlight'))){

                if (p_itemsByRecordType.containsKey('Cruise') || p_itemsByRecordType.containsKey('MultidayRail')) {
                    KaptioTravel__Itinerary_Item__c service = (p_itemsByRecordType.containsKey('Cruise')) ? 
                        p_itemsByRecordType.get('Cruise').get(0) : p_itemsByRecordType.get('MultidayRail').get(0);
                    
                    List<String> serviceLocations = cruiseAndMdRailLocationsBySvcDep.get(service.KaptioTravel__ServiceDeparture__c);                    
                    if (serviceLocations != null && !serviceLocations.isEmpty()) {
                        Integer dayNumber = service.KaptioTravel__DateFrom__c.daysBetween(crDate);
                        this.locationOutput = serviceLocations.get(dayNumber);
                    }
                }

                else if (p_itemsByRecordType.containsKey('Car_Rental')){
                    List<KaptioTravel__Itinerary_Item__c> items = p_itemsByRecordType.get('Car_Rental');
                    Id carHireLocationId;
                    String carHireLocationRecordType;
                    for (KaptioTravel__Itinerary_Item__c item : items) {
                        if ((item.KaptioTravel__CarDropOffLocation__c != null) && (item.KaptioTravel__CarDropOffLocation__r.KaptioTravel__Location__c != null)){
                            carHireLocationId = item.KaptioTravel__CarDropOffLocation__r.KaptioTravel__Location__c;
                            carHireLocationRecordType = item.KaptioTravel__CarDropOffLocation__r.KaptioTravel__Location__r.RecordType.DeveloperName;
                            break;
                        }
                    }

                    if (carHireLocationId != null)
                        this.locationOutput = getLocationName(carHireLocationId, carHireLocationRecordType, 'City');
                }
            }
        }
        else{
             if ((crDate != (itinerary.KaptioTravel__End_Date__c - 1)) || (!flightOnLastTwoDays)){

                if (p_itemsByRecordType.containsKey('Cruise') || p_itemsByRecordType.containsKey('MultidayRail')) {
                    KaptioTravel__Itinerary_Item__c service = (p_itemsByRecordType.containsKey('Cruise')) ? 
                        p_itemsByRecordType.get('Cruise').get(0) : p_itemsByRecordType.get('MultidayRail').get(0);
                    
                    List<String> serviceLocations = cruiseAndMdRailLocationsBySvcDep.get(service.KaptioTravel__ServiceDeparture__c);                    
                    if (serviceLocations != null && !serviceLocations.isEmpty()) {
                        Integer dayNumber = service.KaptioTravel__DateFrom__c.daysBetween(crDate);
                        this.locationOutput = serviceLocations.get(dayNumber);

                        //this.locationOutput = serviceLocations.get(0);
                        //serviceLocations.remove(0);
                        //cruiseAndMdRailLocationsBySvcDep.put(service.KaptioTravel__ServiceDeparture__c, serviceLocations);
                    }
                }
                
                else if (p_itemsByRecordType.containsKey('Accommodation')) {
                        List<KaptioTravel__Itinerary_Item__c> items = p_itemsByRecordType.get('Accommodation');
                        for (KaptioTravel__Itinerary_Item__c item : items) {
                            if (/*!item.Stopover__c &&*/ item.KaptioTravel__Item__r.KaptioTravel__Location__c != null) {

                                String locationName = '';
                                if (item.KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__RecordTypeDeveloperName__c == 'Area' ||
                                    item.KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__RecordTypeDeveloperName__c == 'Transport_Hub') {

                                    if (item.KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__RecordTypeDeveloperName__c == 'Area') {
                                        locationName = item.KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.Name;
                                    } else {
                                        locationName = item.KaptioTravel__Item__r.KaptioTravel__Location__r.KaptioTravel__Location__r.Name; 
                                    }

                                } else {
                                    locationName = item.KaptioTravel__Item__r.KaptioTravel__Location__r.Name;
                                }

                                if (!this.locationOutput.contains(locationName)) {
                                    if (String.isNotBlank(this.locationOutput)) {
                                        this.locationOutput += ', ';
                                    }
                                
                                    this.locationOutput += locationName;
                                }
                            }
                        }
                }
            }
        }
    }

    public void getAllocationOutput(Map<String, List<KaptioTravel__Itinerary_Item__c>> p_itemsByRecordType, Date crDate) {

        List<KaptioTravel__Itinerary_Item__c> flightList = new List<KaptioTravel__Itinerary_Item__c>();
        if (p_itemsByRecordType.containsKey('FlightPlaceholder'))
            flightList.addAll(p_itemsByRecordType.get('FlightPlaceholder'));
        if (p_itemsByRecordType.containsKey('PNRFlight'))
            flightList.addAll(p_itemsByRecordType.get('PNRFlight'));

        if ((!p_itemsByRecordType.containsKey('Accommodation')) && (crDate != itinerary.KaptioTravel__End_Date__c)) {
            this.allocationOutput = System.Label.KTD_Text_AccommodationUnderOwnArrangements;

            Boolean isMultiDayException = false;
            if ((crDate == (itinerary.KaptioTravel__End_Date__c - 1)) && ((p_itemsByRecordType.containsKey('Cruise')) || (p_itemsByRecordType.containsKey('MultidayRail'))) &&
                ((p_itemsByRecordType.containsKey('FlightPlaceholder')) || (p_itemsByRecordType.containsKey('PNRFlight')))){
                for (KaptioTravel__Itinerary_Item__c flight : flightList){
                    List<KTD_DocumentHelper.FlightLegDto> flightLegList = KTD_DocumentHelper.getFlightLegs(flight);
                    if ((flightLegList.size() != 0) && 
                       (flightLegList.get(0).departureDate == (itinerary.KaptioTravel__End_Date__c - 1)) &&
                       (flightLegList.get(flightList.size() - 1).arrivalDate == itinerary.KaptioTravel__End_Date__c))
                       isMultiDayException = true;
                }
            }
            
            if (isMultiDayException)
                this.allocationOutput = System.Label.KTD_Text_OnFlight;
            else if (p_itemsByRecordType.containsKey('Cruise')) {
                this.allocationOutput = (p_itemsByRecordType.get('Cruise').get(0).KaptioTravel__ServiceDeparture__r.KaptioTravel__Ship__r.Name != null) ? 
                    'On board ' + p_itemsByRecordType.get('Cruise').get(0).KaptioTravel__ServiceDeparture__r.KaptioTravel__Ship__r.Name : 'On board ship';

            } else if (
                    p_itemsByRecordType.containsKey('MultidayRail') 
                || ( !p_itemsByRecordType.containsKey('Accommodation') && p_itemsByRecordType.containsKey('Rail') )
                || ( !p_itemsByRecordType.containsKey('Accommodation') && p_itemsByRecordType.containsKey('ManualRail') )
                ) {
                this.allocationOutput = 'On board train';
            } else if ((p_itemsByRecordType.containsKey('FlightPlaceholder')) || (p_itemsByRecordType.containsKey('PNRFlight'))) {
                this.allocationOutput = System.Label.KTD_Text_OnFlight;
            } else {
                this.allocationOutput = System.Label.KTD_Text_UnderOwnArrangement;
            }
        }
        else if (crDate == itinerary.KaptioTravel__End_Date__c){
            if ((p_itemsByRecordType.containsKey('FlightPlaceholder')) || (p_itemsByRecordType.containsKey('PNRFlight'))){
                DateTime arrivalDate;
                Id arrivalAirportId;
                String arrivalAirportRecordType;
                for (KaptioTravel__Itinerary_Item__c flight : flightList){
                    List<KTD_DocumentHelper.FlightLegDto> flightLegList = KTD_DocumentHelper.getFlightLegs(flight);
                    for (KTD_DocumentHelper.FlightLegDto flightLeg : flightLegList){
                        Time arrivalTime  = flightLeg.arrivalTime != null ? Time.newInstance(Integer.valueOf(flightLeg.arrivalTime.split(':').get(0)), Integer.valueOf(flightLeg.arrivalTime.split(':').get(1)), 0, 0) : Time.newInstance(0,0,0,0);
                        
                        DateTime flightLegArrival;
                        if (flightLeg.arrivalDate != null)
                            flightLegArrival = DateTime.newInstance(flightLeg.arrivalDate, arrivalTime);
                        
                        if ((arrivalDate != null) && (flightLegArrival > arrivalDate)){
                            arrivalDate = flightLegArrival;
                            arrivalAirportId = flightLeg.arrivalAirport;
                            arrivalAirportRecordType = flightLeg.arrivalAirportRecordType;
                        }
                    }
                }

                if (arrivalAirportId != null)
                    this.allocationOutput = 'Arrive ' + getLocationName(arrivalAirportId, arrivalAirportRecordType, 'City');
            }
                

        }
    }

    public String getLocationName(Id locationId, String locationRecordType, String locationType){
        Map<Id, Id> locationIdByChildLocation = KTD_DocumentHelper.getLocations(new Map<Id, String>{locationId => locationRecordType}, locationType);
        Map<Id, KaptioTravel__Location__c> locationById = new Map<Id, KaptioTravel__Location__c>([
            SELECT Id, Name
            FROM KaptioTravel__Location__c
            WHERE Id IN :locationIdByChildLocation.values()
            WITH SECURITY_ENFORCED
        ]);
                
        return locationById.get(locationIdByChildLocation.get(locationId)).Name;
    }
}
}