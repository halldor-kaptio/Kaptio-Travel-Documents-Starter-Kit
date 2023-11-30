/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 10-11-2023
 * @last modified by  : Kaptio Developer
**/

global with sharing class CustomKTAgendaHandler extends KaptioTravel.AbstractContentComponentHandler{
    private static String longDateFormat;
    private static String shortDateFormat;
    private static final String LONG_DATE_FORMAT_TYPE = 'LongMonthDayOfWeek';
    private static final String SHORT_DATE_FORMAT_TYPE = 'Numeric';
    private static Integer firstComponentIndex;
    private static final List<String> accommodationRecordTypes = new List<String>{'Accommodation'};
    private static final List<String> flightRecordTypes = new List<String>{'FlightPlaceholder', 'PNRFlight'};

    global CustomKTAgendaHandler() {}

    public override Map<String, Object> doAction(String p_action, Map<String, Object> p_parameters) {
        Map<String, Object> response = new Map<String, Object>();

        switch on p_action {
            when 'KTAgenda.getEvaluated' {
                response.put('agendaOutputBlocksByIndex', getCustomKtAgendaOutput(p_parameters));
            }
            when else {
                response = super.doAction(p_action, p_parameters);
            }
        }
        return response;
    }

    public static Map<Integer, List<String>> getCustomKtAgendaOutput(Map<String, Object> p_parameters) {

        Map<Integer, List<String>> agendaOutputDevMode = new Map<Integer, List<String>>();
        Map<String, String> iconByItemType = KTD_DocumentHelper.getIconByItemTypePDF();
        
        try {
            String iconsResourceUrl = PageReference.forResource('KaptioDocuments').getUrl().substringBefore('?');

            Map<Integer, Object> agendaDaysByIndex = (Map<Integer, Object>)p_parameters.get('agendaDaysByIndex');
            Map<Integer, Object> agendaDataByIndex = (Map<Integer, Object>)p_parameters.get('agendaDataByIndex');

            for(Integer index : agendaDaysByIndex.keySet()) {   
                if (firstComponentIndex == null) { firstComponentIndex = index; }

                KtAgendaDTO ktAgendaDto = (KtAgendaDTO)JSON.deserialize(JSON.serialize(agendaDataByIndex.get(index)), KtAgendaDTO.class);

                if ((ktAgendaDto.listings != null) && (ktAgendaDto.listings.size() > 0)){

                    if ( (String.isBlank(longDateFormat) || String.isBlank(shortDateFormat)) && ktAgendaDto.listings != null && !ktAgendaDto.listings.isEmpty()) {
                        getDateFormats(ktAgendaDto.listings.get(0).itinItemId);
                    }

                    Boolean isAccommodationsContactsComponent = verifyExclusiveRecordType(ktAgendaDto, accommodationRecordTypes);
                    isAccommodationsContactsComponent = (isAccommodationsContactsComponent && index != firstComponentIndex);

                    System.debug('CustomKTAgendaHandler isAccommodationsContactsComponent: ' + isAccommodationsContactsComponent);

                    Boolean isFlightsComponent = verifyExclusiveRecordType(ktAgendaDto, flightRecordTypes);
                    FlightInfoDTO flightInfo = getFlightInfo(ktAgendaDto);

                    List<KtAgendaDayDto> ktAgendaDays = (List<KtAgendaDayDto>)JSON.deserialize(JSON.serialize(agendaDaysByIndex.get(index)), List<KtAgendaDayDto>.class);
                    List<String> outputList = new List<String>{'<div class="kt-agenda-content">'};
                    
                    outputList.add(getHeader(ktAgendaDto, index));
                    
                    if ((isFlightsComponent) && (flightInfo.datesWithFlights != null) && (flightInfo.datesWithFlights.size() != 0)){
                        outputList.add('<div class="kt-agenda-listview-block item-block-wrapper">');
                        outputList.add(     '<div class="kt-item-header">');
                        if ((iconsResourceUrl != null) && (iconByItemType.containsKey('FlightPlaceholder')))
                            outputList.add(     '<img src="' + iconsResourceUrl + '' + iconByItemType.get('FlightPlaceholder') + '"/>');
                        if (flightInfo.bookingSource == 'Client')
                            outputList.add('<h3 class="item-block-title"">Flights you have arranged yourself (not included in your quotation)</h3>');
                        else
                            outputList.add('<h3 class="item-block-title"">Flights arranged by us</h3>');
                        outputList.add(     '</div>');
                        outputList.add(     '</div>');
                    }


                    Set<Id> uniqueItemContentIds = new Set<Id>();
                    for(KtAgendaDayDto day : ktAgendaDays) {
                        if (day.listings != null) {

                            day.checkDuplicateItems(day.listings);

                            outputList.add('<div class="kt-agenda-day-container">');
                            if (( ! isAccommodationsContactsComponent) && 
                            ((!isFlightsComponent) || ((isFlightsComponent) && (flightInfo.datesWithFlights != null) && (flightInfo.datesWithFlights.contains(day.dayDate))))){
                                if ((day.dayNumber != null) && (getFormattedDateString(day.dayDate, longDateFormat) != null))
                                    outputList.add('<div class="kt-agenda-day-header"><h2>Day ' + day.dayNumber + ': ' + getFormattedDateString(day.dayDate, longDateFormat) + '</h2></div>');
                            }
                            
                            //Boolean isEmptyDay = true;
                            
                            for(ListingDto listing : day.listings) {
                                System.debug('listing.recordTypeName: ' + listing.recordTypeName); 
                                System.debug('listing.externalItemName: ' + listing.itineraryItem.KaptioTravel__ExternalItemName__c); 
                                System.debug('listing.itemContentId: ' + listing.itemContentId);

                                if ( ! checkServiceVisibylity(listing, day.dayDate, ktAgendaDto.endDate, isAccommodationsContactsComponent) || 
                                (uniqueItemContentIds.contains(listing.itemContentId) && listing.recordTypeName != 'Accommodation' && listing.recordTypeName != 'FlightPlaceholder' && listing.recordTypeName != 'PNRFlight' && listing.recordTypeName != 'Car_Rental')) {
                                    continue;
                                } 
                                //isEmptyDay = false;
                                outputList.add('<div class="kt-agenda-listview-block item-block-wrapper">');
                                if (!isFlightsComponent) {
                                    outputList.add(     '<div class="kt-item-header">');
                                    if (
                                        String.isNotBlank(listing.recordTypeName) && 
                                        iconByItemType.containsKey(listing.recordTypeName) && 
                                        iconsResourceUrl != null && 
                                            (
                                                iconByItemType.get(listing.recordTypeName) != 'no icon' || iconByItemType.get(listing.recordTypeName) != null
                                            )
                                        ) {
                                        outputList.add(     '<img src="' + iconsResourceUrl + '' + iconByItemType.get(listing.recordTypeName) + '"/>');
                                    }
                                    outputList.add('<h3 class="item-block-title">' + getListingTitle(listing, day.dayDate) + '</h3>');
                                    outputList.add('</div>');
                                    if (
                                        !isAccommodationsContactsComponent && 
                                        listing.subtitle != null && 
                                        listing.dateFrom == day.dayDate && 
                                        listing.recordTypeName != 'FlightPlaceholder' && 
                                        listing.recordTypeName != 'PNRFlight' && 
                                        listing.recordTypeName != 'Car_Rental' 
                                    ) {
                                        outputList.add('<p class="at-agenda-listview-listing-subtitle">' + listing.subtitle + '</p>');
                                    }
                                }

                                outputList.add(     '<div class="item-block-container">');

                                if (isAccommodationsContactsComponent) {
                                    outputList.addAll(      getServiceInfoBlock(listing, null, day.priceCategoryItemId));
                                } else {
                                    outputList.addAll(      getServiceInfoBlock(listing, day.dayDate, day.priceCategoryItemId));
                                }

                                if (!isAccommodationsContactsComponent && listing.content != null && listing.dateFrom == day.dayDate && 
                                    ((listing.recordTypeName != 'FlightPlaceholder' && listing.recordTypeName != 'PNRFlight' && listing.recordTypeName != 'Accommodation') ||
                                    (!uniqueItemContentIds.contains(listing.itemContentId) && listing.recordTypeName == 'Accommodation')) ) {

                                    outputList.add(     '<div class="item-content-html">');
                                    outputList.add(         '<div class="item-content-html-full">' + listing.content + '</div>');
                                    outputList.add(     '</div>');

                                    if (listing.mediaList != null) {
                                        outputList.add(     '<div class="video-images-gallery hide-in-finalDocs">');

                                        Integer imageCounter = 0;
                                        for (MediaDTO image : listing.mediaList) {
                                            if (image.type != 'image') {
                                                continue;
                                            }
                                            if (imageCounter == 3) { break; }

                                            outputList.add(     '<div class="item-image">');
                                            if (image.url != null)
                                                outputList.add(         '<img src="https://res.cloudinary.com/kaptio/image/fetch/w_232,h_232,c_fill,g_face,f_auto/' + image.url + '"/>');
                                            outputList.add(     '</div>');

                                            imageCounter ++;
                                        }
                                        outputList.add(     '</div>');
                                    }
                                }

                                outputList.add(     '</div>');//item-block-container end
                                outputList.add('</div>');//kt-agenda-listview-block end

                                if (listing.itemContentId != null && !uniqueItemContentIds.contains(listing.itemContentId)) {
                                    uniqueItemContentIds.add(listing.itemContentId);
                                }
                            }

                            /*if (isEmptyDay) {
                                outputList.remove(outputList.size() - 1);
                                outputList.remove(outputList.size() - 1);
                            } else {*/
                                outputList.add('</div>');//kt-agenda-day-container
                            //} 
                        }
                    }

                    outputList.add('</div>');//kt-agenda-content
                    agendaOutputDevMode.put(index, outputList);

                }
            }
        } catch (Exception exc) {
            System.debug('CustomKTAgendaHandler ERROR: ' + exc.getMessage() + '; Stack Trace: ' + exc.getStackTraceString());
        }

        return agendaOutputDevMode;
    }

    private static void getDateFormats(Id p_itinItemId) {
        KaptioTravel__Itinerary__c itinerary = [
            SELECT Id, KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name 
            FROM KaptioTravel__Itinerary__c 
            WHERE Id IN (SELECT KaptioTravel__Itinerary__c FROM KaptioTravel__Itinerary_Item__c WHERE Id = :p_itinItemId)
            WITH SECURITY_ENFORCED
        ];

        List<KaptioDocumentDateFormat__mdt> dateFormatSettings = [
            SELECT Id, MasterLabel, DateFirst__c, MonthFirst__c 
            FROM KaptioDocumentDateFormat__mdt 
            WHERE MasterLabel IN (:LONG_DATE_FORMAT_TYPE, :SHORT_DATE_FORMAT_TYPE)
            WITH SECURITY_ENFORCED
        ];
        for (KaptioDocumentDateFormat__mdt dfSettings : dateFormatSettings) {
            if (dfSettings.MasterLabel.equals(LONG_DATE_FORMAT_TYPE)){
                longDateFormat = (itinerary.KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name == 'KTUK') ? 
                    dfSettings.DateFirst__c : dfSettings.MonthFirst__c;
            } else {
                shortDateFormat = (itinerary.KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name == 'KTUK') ? 
                    dfSettings.DateFirst__c : dfSettings.MonthFirst__c;
            }
        }
    }

    private static String getFormattedDateString(Date p_date, String p_dateFormat) {
        if ((p_date != null) && (p_dateFormat != null)){
            DateTime dateObj = Datetime.newInstance(p_date.year(), p_date.month(), p_date.day());
            return dateObj.format(p_dateFormat);
        }
        return null;
    }

    private static String getListingTitle(ListingDTO p_listing, Date p_dayDate) {
        System.debug('=== Listing title: ' + p_listing.title);
        System.debug(p_listing.itineraryItem.KaptioTravel__ExternalItemName__c);
        if (String.isBlank(p_listing.recordTypeName)) {
                return p_listing.title;
        }

        String title = '';
        if (p_listing.recordTypeName == 'Car_Rental') {
            if (p_listing.dateFrom == p_dayDate) {
                title += 'Vehicle Hire Pick-up '; 
            } else if (p_listing.dateTo == p_dayDate) {
                title += 'Vehicle Hire Drop-off ';
            }
            title += p_listing.itineraryItem.KaptioTravel__ExternalItemName__c;

        } else if ((p_listing.recordTypeName == 'FlightPlaceholder') || (p_listing.recordTypeName == 'PNRFlight'))  {
            title = 'Flights';
            if (p_listing.itineraryItem.KaptioTravel__FlightBookingSource__c == 'Client') {
                title = 'Flights you have arranged yourself (not included in your quotation)';
            } else if (p_listing.itineraryItem.KaptioTravel__FlightBookingSource__c == 'Ground Agent') {
                title = 'Flights arranged by our local agents';
            } 

        } else {            
            title = p_listing.itineraryItem.KaptioTravel__ExternalItemName__c;
            title = title != null ? title : p_listing.title;
            System.debug('== title' + title);
        }
        return title;
    }

    private static List<String> getServiceInfoBlock(ListingDTO p_listing, Date p_dayDate, Map<Id, List<String>> p_priceCategoryItemId) {
        List<String> outputList = new List<String>();
        
        switch on p_listing.recordTypeName {
            when 'FlightPlaceholder', 'PNRFlight'  {    
                outputList.add('<div class="at-agenda-listview-listing-item-info">');
                    List<FlightLegDto> flightLegs = getFlightLegs(p_listing);
                    List<KaptioTravel__PassengerItineraryUnitAssignment__c> passengerAssignments;
                    if ((p_listing.childSobjects != null) && (p_listing.childSobjects.containsKey('KaptioTravel__PassengerItineraryUnitAssignments__r')))
                        passengerAssignments = (List<KaptioTravel__PassengerItineraryUnitAssignment__c>)p_listing.childSobjects.get('KaptioTravel__PassengerItineraryUnitAssignments__r');
                    
                    List<passengerAssignmentDto> assignmentDtoList = new List<passengerAssignmentDto>();
                    if (passengerAssignments != null){
                        for (KaptioTravel__PassengerItineraryUnitAssignment__c paxAssignment : passengerAssignments)
                            assignmentDtoList.add(new passengerAssignmentDto(paxAssignment));
                    }
                    assignmentDtoList.sort();
                    List<String> passengers = new List<String>();
                    for (passengerAssignmentDto assignmentDto : assignmentDtoList){
                        String paxString = '';
                        if (assignmentDto.assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c != null)
                            paxString += assignmentDto.assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c + ' ';
                        if (assignmentDto.assignment.KaptioTravel__Passenger__r.KaptioTravel__MiddleName__c != null)
                            paxString += assignmentDto.assignment.KaptioTravel__Passenger__r.KaptioTravel__MiddleName__c + ' ';
                        if (assignmentDto.assignment.KaptioTravel__Passenger__r.KaptioTravel__LastName__c != null)
                            paxString += assignmentDto.assignment.KaptioTravel__Passenger__r.KaptioTravel__LastName__c + ' ';
                        passengers.add(paxString);
                    }

                    String passengersString = String.join(passengers, ', ');
                    
                    for (FlightLegDto flightLeg : flightLegs) {
                        if (flightLeg.departureDate == p_dayDate) {
                            outputList.add('<div class="dtd-flight-info">');
                            if ((String.isNotBlank(flightLeg.departureAirportName)) && (String.isNotBlank(flightLeg.arrivalAirportName)))
                                outputList.add('<div class="at-agenda-item-info-row first"><div class="bold-label">' + flightLeg.departureAirportName+ ' ' + Label.KTD_Text_To + ' ' + flightLeg.arrivalAirportName + '</div></div>');
                    
                            if (String.isNotBlank(flightLeg.flightNumber))
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Flight number: </div><div class="table-value">' + flightLeg.flightNumber + '</div></div>');
                            if (String.isNotBlank(flightLeg.airlineName))
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">' + Label.KTD_Label_Airline + ': </div><div class="table-value">' + flightLeg.airlineName + '</div></div>');
                            if (String.isNotBlank(flightLeg.operatedbyName))
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Operated by: </div><div class="table-value">' + flightLeg.operatedByName + '</div></div>');
                            
                            if (String.isNotBlank(flightLeg.departureTime))
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">' + Label.KTD_Label_Dep + ': </div><div class="table-value">' + flightLeg.departureTime+ '</div></div>');
                            
                            if (String.isNotBlank(flightLeg.arrivalTime)) {
                                String arrivalInfo = '<div class="at-agenda-item-info-row"><div class="bold-label table">' + Label.KTD_Label_Arr + ': </div><div class="table-value">' + flightLeg.arrivalTime;
                                if ((flightLeg.departureDate != null) && (flightLeg.arrivalDate != null) && (flightLeg.departureDate < flightLeg.arrivalDate)) {
                                    arrivalInfo += ' ' + Label.KTD_Text_NextDay;
                                }
                                arrivalInfo += '</div></div>';
                                outputList.add(arrivalInfo);
                            }
                            
                            if (flightLeg.travelClass != null)
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">' + Label.KTD_Label_Class + ': </div><div class="table-value">' + flightLeg.travelClass + '</div></div>');
                                
                            if (!String.isBlank(passengersString))
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Passengers: </div><div class="table-value">' + passengersString + '</div></div>');
                            /*if (flightLegs.size() == 1) {
                                outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label">' + Label.Content_Text_NonStopFlight + '</div></div>');
                            }*/
                            
                            outputList.add('</div>');
                        }
                    }
                outputList.add('</div>');
            }   
            when 'Car_Rental' { 
                outputList.add('<div class="at-agenda-listview-listing-item-info">');
                    outputList.add('<div class="dtd-flight-info">');
                    if (p_listing.dateFrom == p_dayDate) {
                        outputList.add('<div class="at-agenda-item-info-row first"><div class="bold-label table">Vehicle type: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__ExternalName__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__ExampleCarModel__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Example car model: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__ExampleCarModel__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__PassengerCapactity__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Max Unit Occupants: </div><div class="table-value">' + Integer.valueOf(p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__PassengerCapactity__c) + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__LuggageCapacity__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Luggage Capacity: </div><div class="table-value">' + Integer.valueOf(p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__LuggageCapacity__c) + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__MinDriverAge__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Min Driver Age: </div><div class="table-value">' + Integer.valueOf(p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__MinDriverAge__c) + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__DoorCount__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Door Count: </div><div class="table-value">' + Integer.valueOf(p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__DoorCount__c) + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__TransmissionType__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Transmission type: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__TransmissionType__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__FuelType__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Fuel type: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__FuelType__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Price_Category__r.KaptioTravel__AirConditioning__c) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Air Conditioning: </div><div class="table-value">Included</div></div>');
                        else
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Air Conditioning: </div><div class="table-value">Not Included</div></div>');
                        if ((getFormattedDateString(p_listing.dateFrom, shortDateFormat) != null) && (getFormattedDateString(p_listing.dateTo, shortDateFormat) != null))
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Duration of hire: </div><div class="table-value">' + getFormattedDateString(p_listing.dateFrom, shortDateFormat) + ' - ' + getFormattedDateString(p_listing.dateTo, shortDateFormat) + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__c != null) 
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Pick-up point: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.Name + '</div></div>');
                        if (p_listing.timeFrom != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Pick-up time: </div><div class="table-value">' + p_listing.timeFrom + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__Address__c != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Pick-up address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__Address__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__ContactPhone__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Tel (day): </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__ContactPhone__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__ContactEmail__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Email address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__ContactEmail__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__OpeningTimes__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Opening times: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__OpeningTimes__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__SpecialInstructions__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Special instructions: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarPickUpLocation__r.KaptioTravel__SpecialInstructions__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Voucher_Reference_No__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Booking reference: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Voucher_Reference_No__c + '</div></div>');

                        //addons
                        List<KaptioTravel__ItineraryService__c> addons = new List<KaptioTravel__ItineraryService__c>();
                        if ((p_listing.childSobjects != null) && (p_listing.childSobjects.containsKey('KaptioTravel__ItineraryServices__r')))
                            addons = (List<KaptioTravel__ItineraryService__c>)p_listing.childSobjects.get('KaptioTravel__ItineraryServices__r');
                        String addonsString = '';
                        for (KaptioTravel__ItineraryService__c addon : addons) {
                            if (addon.KaptioTravel__Addon__c != null) {
                                if (String.isNotBlank(addonsString)) { addonsString += ', '; }
                                addonsString += addon.KaptioTravel__Addon__r.Name;
                            }
                        }
                        if (String.isNotBlank(addonsString)) {
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Included: </div><div class="table-value">' + addonsString + '</div></div>');
                        }

                        
                        
                        /*if (p_listing.itineraryItem.KaptioTravel__CustomerNotes__c != null) {
                            outputList.add('<div class="agent-notes"><h3>Notes</h3><div>' + p_listing.itineraryItem.KaptioTravel__CustomerNotes__c + '</div></div>');
                        }*/
                    }
                    
                    if (p_listing.dateTo == p_dayDate) {
                        if (p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__c != null)
                            outputList.add('<div class="at-agenda-item-info-row first"><div class="bold-label table">Drop-off point: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.Name + '</div></div>');
                        if (p_listing.timeTo != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Drop-off time: </div><div class="table-value">' + p_listing.timeTo + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__Address__c != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Drop-off address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__Address__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__ContactPhone__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Tel (day): </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__ContactPhone__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__ContactEmail__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Email address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__ContactEmail__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__OpeningTimes__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Opening times: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__OpeningTimes__c + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__SpecialInstructions__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Special instructions: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__CarDropOffLocation__r.KaptioTravel__SpecialInstructions__c + '</div></div>');
                    }
                    outputList.add('</div>');  
                outputList.add('</div>'); 
            }
            when 'Rail', 'ManualRail' {       
                outputList.add('<div class="at-agenda-listview-listing-item-info">');
                    outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label">' + p_listing.itineraryItem.KaptioTravel__ExternalName__c + '</div></div>');
                    if (p_listing.dateFrom == p_dayDate) {
                        if (p_listing.itineraryItem.KaptioTravel__TrainStationStart__c != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Board: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__TrainStationStart__r.KaptioTravel__Location__r.Name + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__TrainStationStart__r.KaptioTravel__Location__r.KaptioTravel__Address__c != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__TrainStationStart__r.KaptioTravel__Location__r.KaptioTravel__Address__c + '</div></div>');
                        if (p_listing.timeFrom != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Time: </div><div class="table-value">' + p_listing.timeFrom + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Voucher_Reference_No__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Booking reference: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Voucher_Reference_No__c + '</div></div>');
                    }
                    if (p_listing.dateTo == p_dayDate) {
                        if (p_listing.itineraryItem.KaptioTravel__TrainStationEnd__c != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Alight: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__TrainStationEnd__r.KaptioTravel__Location__r.Name + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__TrainStationEnd__r.KaptioTravel__Location__r.KaptioTravel__Address__c != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__TrainStationStart__r.KaptioTravel__Location__r.KaptioTravel__Address__c + '</div></div>');
                        if (p_listing.timeTo != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Time: </div><div class="table-value">' + p_listing.timeTo + '</div></div>');
                    }
                outputList.add('</div>'); 
            }
            when 'Accommodation' {
                outputList.add('<div class="at-agenda-listview-listing-item-info">');
                    if (p_listing.dateFrom == p_dayDate || p_dayDate == null) {
                        //only for Final Doc
                        if (p_listing.itineraryItem.KaptioTravel__Item__r.KaptioTravel__Address__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Item__r.KaptioTravel__Address__c + '</div></div>');
                       // if (p_listing.itineraryItem.KaptioTravel__Item__r.TelephoneNumber__c != null)
                        //    outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Telephone number(s): </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Item__r.TelephoneNumber__c + '</div></div>');
                        //if (p_listing.itineraryItem.KaptioTravel__Item__r.Email__c != null)
                        //    outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Email address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Item__r.Email__c + '</div></div>');

                        if (getFormattedDateString(p_listing.dateFrom, shortDateFormat) != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Check-in date: </div><div class="table-value">' + getFormattedDateString(p_listing.dateFrom, shortDateFormat) + '</div></div>');
                        if (getFormattedDateString(p_listing.dateTo, shortDateFormat) != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Check-out date: </div><div class="table-value">' + getFormattedDateString(p_listing.dateTo, shortDateFormat) + '</div></div>');
                    }

                    if (p_dayDate != null) {
                        if ((p_listing.itineraryItem.KaptioTravel__ExternalName__c != null)) {
                            Integer qnty = (p_listing.itineraryItem.KaptioTravel__Quantity__c != null) ? (Integer)p_listing.itineraryItem.KaptioTravel__Quantity__c : 0;
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Your room booking: </div><div class="table-value">' + 
                                qnty + 'x ' + p_listing.itineraryItem.KaptioTravel__ExternalName__c + '</div></div>');
                        }
                        
                        //if (p_priceCategoryItemId.containsKey(p_listing.itemId)){
                        //  outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Your room booking: </div><div class="table-value">');
                        //  for (String priceCategory : p_priceCategoryItemId.get(p_listing.itemId)) {
                        //      outputList.add(priceCategory + '<br/>');
                        //  }
                        //  outputList.add('</div></div>');
                        //}
                        
                        List<KaptioTravel__ItineraryService__c> addons = new List<KaptioTravel__ItineraryService__c>();
                        if ((p_listing.childSobjects != null) && (p_listing.childSobjects.containsKey('KaptioTravel__ItineraryServices__r')))
                            addons = (List<KaptioTravel__ItineraryService__c>)p_listing.childSobjects.get('KaptioTravel__ItineraryServices__r');
                        String addonsString = '';
                        for (KaptioTravel__ItineraryService__c addon : addons) {
                            if (addon.KaptioTravel__Addon__c != null) {
                                if (String.isNotBlank(addonsString)) { addonsString += ', '; }
                                addonsString += addon.KaptioTravel__Addon__r.Name;
                            }
                        }
                        if (String.isNotBlank(addonsString)) {
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Included: </div><div class="table-value">' + addonsString + '</div></div>');
                        }
                        
                        // if (String.isNotBlank(p_listing.itineraryItem.KaptioTravel__Item__r.Internal_Rating__c) && p_listing.dateFrom == p_dayDate) {
                        //     outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Our rating: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Item__r.Internal_Rating__c + '</div></div>');
                        // }

                        /*if (String.isNotBlank(p_listing.itineraryItem.KaptioTravel__CustomerNotes__c) && p_listing.dateFrom == p_dayDate) {
                            outputList.add('<div class="agent-notes"><h3>Notes</h3><div>' + p_listing.itineraryItem.KaptioTravel__CustomerNotes__c + '</div></div>');
                        }*/
                    }
                outputList.add('</div>'); 
            }
            when 'Cruise', 'MultidayRail' {
                outputList.add('<div class="at-agenda-listview-listing-item-info">');
                    if (p_listing.dateFrom == p_dayDate) {
                        //only for Final Doc
                        if (p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingAddress != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Address: </div><div class="table-value">' + 
                                (p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingStreet != null ? p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingStreet + ' ' : '') +
                                (p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingCity != null ? p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingCity + ' ' : '') + 
                                (p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingState != null ? p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingState + ' ' : '') + 
                                (p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingPostalCode != null ? p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingPostalCode + ' ' : '') + 
                                (p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingCountry != null ? p_listing.itineraryItem.KaptioTravel__Supplier__r.BillingCountry : '') + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Supplier__r.Phone != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Telephone number(s): </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Supplier__r.Phone + '</div></div>');
                        if (p_listing.itineraryItem.KaptioTravel__Supplier__r.KaptioTravel__Email__c != null)
                            outputList.add('<div class="at-agenda-item-info-row hide-in-quote"><div class="bold-label table">Email address: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__Supplier__r.KaptioTravel__Email__c + '</div></div>');

                        if (getFormattedDateString(p_listing.dateFrom, shortDateFormat) != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">' + (p_listing.recordTypeName == 'Cruise' ? 'Embark' : 'Board') + ': </div><div class="table-value">' + getFormattedDateString(p_listing.dateFrom, shortDateFormat) + '</div></div>');
                        if (getFormattedDateString(p_listing.dateTo, shortDateFormat) != null)
                            outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">' + (p_listing.recordTypeName == 'Cruise' ? 'Disembark' : 'Alight') + ': </div><div class="table-value">' + getFormattedDateString(p_listing.dateTo, shortDateFormat) + '</div></div>');
                    }

                    if (p_listing.itineraryItem.KaptioTravel__ExternalName__c != null)
                        outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Cabin type: </div><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__ExternalName__c + '</div></div>');
                    
                    List<KaptioTravel__ItineraryService__c> addons = new List<KaptioTravel__ItineraryService__c>();
                    if ((p_listing.childSobjects != null) && (p_listing.childSobjects.containsKey('KaptioTravel__ItineraryServices__r')))
                        addons = (List<KaptioTravel__ItineraryService__c>)p_listing.childSobjects.get('KaptioTravel__ItineraryServices__r');
                    String addonsString = '';
                    for (KaptioTravel__ItineraryService__c addon : addons) {
                        if (addon.KaptioTravel__Addon__c != null) {
                            if (String.isNotBlank(addonsString)) { addonsString += ', '; }
                            addonsString += addon.KaptioTravel__Addon__r.Name;
                        }
                    }
                    if (String.isNotBlank(addonsString)) {
                        outputList.add('<div class="at-agenda-item-info-row"><div class="bold-label table">Included: </div><div class="table-value">' + addonsString + '</div></div>');
                    }

                    /*if (p_listing.dateFrom == p_dayDate) {
                        if (String.isNotBlank(p_listing.itineraryItem.KaptioTravel__CustomerNotes__c) && p_listing.dateFrom == p_dayDate) {
                            outputList.add('<div class="agent-notes"><h3>Notes</h3><div>' + p_listing.itineraryItem.KaptioTravel__CustomerNotes__c + '</div></div>');
                        }
                    }*/
                outputList.add('</div>'); 
            }
            when 'Transfer', 'Activity' {
                if (p_listing.itineraryItem.KaptioTravel__ExternalName__c != null)
                    outputList.add('<div class="at-agenda-item-info-row"><div class="table-value">' + p_listing.itineraryItem.KaptioTravel__ExternalName__c + '</div></div>');
            }
            when else {
                // outputList.add('<div class="at-agenda-item-info-row"><div class="table-value">' + p_listing.title + '</div></div>');
            }
        }

        if (String.isNotBlank(p_listing.itineraryItem.KaptioTravel__CustomerNotes__c) && p_listing.dateFrom == p_dayDate) {
            outputList.add('<div class="agent-notes"><h3>Notes</h3><div>' + p_listing.itineraryItem.KaptioTravel__CustomerNotes__c + '</div></div>');
        }
        
        return outputList;
    }

    private static Boolean checkServiceVisibylity(ListingDTO p_listing, Date p_dayDate, Date p_tripEndDate, Boolean p_isAccommContactsComponent) {
        Boolean isVisible = true;
        
        if ( (p_listing.recordTypeName == 'Car_Rental' && p_listing.dateFrom != p_dayDate && p_listing.dateTo != p_dayDate) ||
             (p_listing.recordTypeName == 'Accommodation' && p_listing.dateFrom != p_dayDate && p_isAccommContactsComponent) ||
             (p_listing.recordTypeName == 'Accommodation' && p_listing.dateTo == p_dayDate) ||
             ((p_listing.recordTypeName == 'Cruise' || p_listing.recordTypeName == 'MultidayRail' || p_listing.lineType == 'iiShipLine') && p_listing.dateFrom != p_dayDate) ||
               p_listing.lineType == 'iiCabinTypeLine' ){
            isVisible = false;

        }
        if ((p_listing.recordTypeName == 'FlightPlaceholder') || (p_listing.recordTypeName == 'PNRFlight')) {
            isVisible = false;
            List<FlightLegDto> flightLegs = getFlightLegs(p_listing);
            for (FlightLegDto flightLeg : flightLegs) {
                if (flightLeg.departureDate == p_dayDate) {
                    isVisible = true;
                }
            }        
        }

        System.debug('isVisible: ' + isVisible);
        return isVisible;
    }

    private static Boolean verifyExclusiveRecordType(KtAgendaDTO p_ktAgendaDto, List<String> recordTypes) {
        for (ListingDTO listing : p_ktAgendaDto.listings) {
            if (!recordTypes.contains(listing.recordTypeName)) {
                return false;
            }
        }
        return true;
      }

    private static FlightInfoDTO getFlightInfo(KtAgendaDTO p_ktAgendaDto){
        String bookingSource;
        Set<Date> datesWithFlights = new Set<Date>();

        for (ListingDTO listing : p_ktAgendaDto.listings){
            if ((listing.recordTypeName == 'FlightPlaceholder') || (listing.recordTypeName == 'PNRFlight')){
                if (bookingSource == null)
                    bookingSource = listing.itineraryItem.KaptioTravel__FlightBookingSource__c;
                List<FlightLegDto> flightLegs = getFlightLegs(listing);
                for (FlightLegDto flightLeg : flightLegs) 
                    datesWithFlights.add(flightLeg.departureDate);
            }
            
        }
        return new FlightInfoDTO(p_ktAgendaDto, bookingSource, datesWithFlights);
    }

    private static String getHeader(KtAgendaDTO p_ktAgendaDto, Integer p_componentIndex) {
        String header = '<div class="kt-tab-custom"><h2>Detailed itinerary</h2></div>';

        if (verifyExclusiveRecordType(p_ktAgendaDto, accommodationRecordTypes) && p_componentIndex != firstComponentIndex)
            header = '<div class="kt-tab-custom"><h2>Accommodation contact information</h2></div>';
        else if (verifyExclusiveRecordType(p_ktAgendaDto, flightRecordTypes)){
            header = '<div class="kt-tab-custom"><h2>Flight Information</h2></div>';
        }

        return header;  
    }

    private static List<FlightLegDto> getFlightLegs(ListingDto listing){
        List<FlightLegDto> flightlegDtoList = new List<FlightLegDto>();
        if (listing.recordTypeName == 'FlightPlaceholder'){
            if ((listing.childSobjects != null) && (listing.childSobjects.containsKey('KaptioTravel__Itinerary_Flight_Legs__r'))){
                for (KaptioTravel__ItineraryFlightLeg__c flightLeg : (List<KaptioTravel__ItineraryFlightLeg__c>)listing.childSobjects.get('KaptioTravel__Itinerary_Flight_Legs__r'))
                    flightlegDtoList.add(new FlightLegDto(flightLeg.KaptioTravel__FlightNumber__c, flightLeg.KaptioTravel__DepartureAirportName__c, flightLeg.KaptioTravel__ArrivalAirportName__c,
                                        flightLeg.KaptioTravel__Airline__r.Name, flightLeg.KaptioTravel__OperatedBy__r.Name, flightLeg.KaptioTravel__DepartureDate__c, 
                                        flightLeg.KaptioTravel__DepartureTime__c, flightLeg.KaptioTravel__ArrivalDate__c, flightLeg.KaptioTravel__ArrivalTime__c, flightLeg.KaptioTravel__TravelClass__c));
            }
        }
        else if (listing.recordTypeName == 'PNRFlight'){
            if ((listing.childSobjects != null) && (listing.childSobjects.containsKey('KaptioTravel__PNRFlightSegments__r'))){
                for (KaptioTravel__PNRFlightSegment__c flightLeg : (List<KaptioTravel__PNRFlightSegment__c>)listing.childSobjects.get('KaptioTravel__PNRFlightSegments__r')){
                    String departureTimeString, arrivalTimeString;
                    if (flightLeg.KaptioTravel__DepartureTime__c != null)
                        departureTimeString = String.valueOf(flightLeg.KaptioTravel__DepartureTime__c).left(5);
                    if (flightLeg.KaptioTravel__ArrivalTime__c != null)
                        arrivalTimeString = String.valueOf(flightLeg.KaptioTravel__ArrivalTime__c).left(5);
                    flightlegDtoList.add(new FlightLegDto(flightLeg.KaptioTravel__FlightNumber__c, flightLeg.KaptioTravel__DepartureAirport__r.Name, flightLeg.KaptioTravel__ArrivalAirport__r.Name,
                                        flightLeg.KaptioTravel__Airline__r.Name, flightLeg.KaptioTravel__OperatedBy__r.Name, flightLeg.KaptioTravel__DepartureDate__c, 
                                        departureTimeString, flightLeg.KaptioTravel__ArrivalDate__c, arrivalTimeString, flightLeg.KaptioTravel__TravelClass__c));
                }
            }
        }

        flightLegDtoList.sort();

        return flightLegDtoList;
            
    }

    // -------- DTOs ------------
    /**
     * @description Dto for KtAgenda
    **/
    public class KtAgendaDTO {
        public Map<Integer, String> dayHeadingMap { get; set;}
        public List<ListingDTO> listings { get; set; }
        public Date startDate { get; set; }
        public Date endDate { get; set; }
        public String channelDateFormat { get; set; }
        public List<Map<String, String>> groupsMeta { get; set; }
        public Boolean isShowAccommodationLast { get; set; }
        public Boolean isDeveloperMode { get; set; }
    }

    public class KtAgendaDayDto {
        public Integer dayNumber;
        public Date dayDate;
        public String dateFormatted;
        public List<ListingDTO> listings;

        public Map<Id, List<String>> priceCategoryItemId;

        public void checkDuplicateItems(List<ListingDTO> p_listings) {
            this.priceCategoryItemId = new Map<Id, List<String>>();
            Set<String> uniqueNames = new Set<String>();

            for (Integer i = 0; i < p_listings.size(); i++) {
                System.debug('checkDuplicateItems - external name:' + p_listings.get(i).itineraryItem.KaptioTravel__ExternalItemName__c);

                if ((p_listings.get(i).recordTypeName != 'FlightPlaceholder') && (p_listings.get(i).recordTypeName != 'PNRFlight') && 
                    p_listings.get(i).recordTypeName != 'Accommodation') {

                    if ( ! uniqueNames.contains(p_listings.get(i).itineraryItem.KaptioTravel__ExternalItemName__c)) {
                        uniqueNames.add(p_listings.get(i).itineraryItem.KaptioTravel__ExternalItemName__c);
                        priceCategoryItemId.put(p_listings.get(i).itemId, new List<String>{p_listings.get(i).itineraryItem.KaptioTravel__ExternalName__c});
                    } else {
                        if ((priceCategoryItemId.containsKey(p_listings.get(i).itemId)) && (!priceCategoryItemId.get(p_listings.get(i).itemId).contains(p_listings.get(i).itineraryItem.KaptioTravel__ExternalName__c)))
                            priceCategoryItemId.get(p_listings.get(i).itemId).add(p_listings.get(i).itineraryItem.KaptioTravel__ExternalName__c);
                        p_listings.remove(i);
                        i --;
                    }
                }
            }

            this.listings = p_listings;
        }
    }

    /**
     * @description Dto for KtAgenda listing
    **/
    public class ListingDTO {
        public KaptioTravel__ItineraryBooking__c booking; //still used due to customization.
        public KaptioTravel__Itinerary_Item__c itineraryItem; //contains requested fields only(in dev mode)
        public Map<String, List<Sobject>> childSobjects; //contains requested objects only(in dev mode)
        public List<DynamicFieldDTO> dynamicListingFields; // ItineraryItem merged Fields
        public String title;
        public String subtitle;
        public String content;
        public String shortContent;
        public String contentNote;
        public Date dateFrom;
        public Date dateTo;
        public String timeFrom;
        public String timeTo;
        public Id imageId;
        public String imageUrl;
        public Double latitude;
        public Double longitude;
        public Set<Id> groups;
        public Id itemContentId;
        public Boolean displayBookingSummary;
        public Integer order;
        public String address;
        public String allocation;
        public Id priceCategoryId;
        public String priceCategoryName;
        public List<MediaDTO> mediaList;
        public Id itinItemId;
        public Id itemId;
        public Id contentLineId;
        public Boolean hideDate = false;
        public Boolean hideTime = false;
        public String recordTypeName = '';
        public Id parentItinItemId;
        public String lineType; // ship, cabin type, service dep location
        public Id parentId;// ship, cabin type, service dep location
        public Integer orderInType; //order of lines with the same lineType
    }

    /**
     * @description Dto for media objects. Video__c and Image__c supports
    **/
    public class MediaDTO {
        public String Id;
        public String type;
        public String url;
        public Boolean isFeatured;
        public Integer order;
        public String thumbnail;
    }

    /**
     * @description Dto for dynamic fields
    **/
    public class DynamicFieldDTO {
        public String fieldValue;
        public String fieldType;
        public String fieldLabel;
        public String fieldPath;
        public List<String> mergedFieldValues;
    }

    public class FlightInfoDTO{
        public KtAgendaDTO ktAgenda;
        public String bookingSource;
        public Set<Date> datesWithFlights;

        public FlightInfoDTO(KtAgendaDTO ktAgenda, String bookingSource,  Set<Date> datesWithFlights){
            this.ktAgenda = ktAgenda;
            this.bookingSource = bookingSource;
            this.datesWithFlights = datesWithFlights;
        }
    }

    public class FlightLegDto implements Comparable{
        String flightNumber;
        String departureAirportName;
        String arrivalAirportName;
        String airlineName;
        String operatedByName;
        Date departureDate;
        String departureTime;
        Date arrivalDate;
        String arrivalTime;
        String travelClass;

        public FlightLegDto(String flightNumber, String departureAirportName, String arrivalAirportName, String airlineName, String operatedByName, Date departureDate,
                            String departureTime, Date arrivalDate, String arrivalTime, String travelClass){
               this.flightNumber = flightNumber;
               this.departureAirportName = departureAirportName;
               this.arrivalAirportName = arrivalAirportName;
               this.airlineName = airlineName;
               this.operatedByName = operatedByName;
               this.departureDate = departureDate;
               this.departureTime = departureTime;
               this.arrivalDate = arrivalDate;
               this.arrivalTime = arrivalTime;
               this.travelClass = travelClass;

        }

        public Integer compareTo(Object compareTo) {
            FlightLegDto compareToEmp = (FlightLegDto)compareTo;
            if (departureDate == compareToEmp.departureDate){
                if (departureTime == compareToEmp.departureTime) return 0;
                    
                if (departureTime > compareToEmp.departureTime) return 1;

                return -1;
            }
            if (departureDate > compareToEmp.departureDate) return 1;
            
            return -1;        
        }
    }

    public class passengerAssignmentDto implements Comparable{

        public KaptioTravel__PassengerItineraryUnitAssignment__c assignment;

        public passengerAssignmentDto(KaptioTravel__PassengerItineraryUnitAssignment__c  assignment){
            this.assignment = assignment;
        }

        public Integer compareTo(Object compareTo) {

            passengerAssignmentDto compareItem = (passengerAssignmentDto)compareTo;

            if ((assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c != null) && (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c != null) &&
                (assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c < compareitem.assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c))
                return -1;
            else if ((assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c != null) && (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c != null) &&
                    (assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c > compareitem.assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c))
                return 1;
            else if ((assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c != null) && (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c == null))
                return -1;
            else if ((assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c == null) && (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__AllocationId__c != null))
                return 1;
            else if (assignment.KaptioTravel__Passenger__r.KaptioTravel__LeadPassenger__c)
                return -1;
            else if (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__LeadPassenger__c)
                return 1;
            else if ((assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c != null) && (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c != null) && 
                    (assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c < compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c))
                return -1;
            else if ((assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c != null) && (compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c != null) &&
                    (assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c > compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__FirstName__c))
                return 1;
            else if (assignment.KaptioTravel__Passenger__r.KaptioTravel__LastName__c < compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__LastName__c)
                return -1;
            else if (assignment.KaptioTravel__Passenger__r.KaptioTravel__LastName__c > compareItem.assignment.KaptioTravel__Passenger__r.KaptioTravel__LastName__c)
                return 1;
            return 0;

        }
    }
}