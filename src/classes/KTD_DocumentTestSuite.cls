/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 11-22-2022
 * @last modified by  : Kaptio Developer
**/
@isTest
public with sharing class KTD_DocumentTestSuite {

    @TestSetup
    static void setupData(){
        
        KTD_DocumentTestHelper t = new KTD_DocumentTestHelper(true);
        t.itinerary.KaptioTravel__DepositAmount__c = 1000;
        update t.itinerary;

        test.startTest();
        KaptioTravel__Itinerary_Item__c itineraryItem = [SELECT Id, KaptioTravel__IsOptional__c FROM KaptioTravel__Itinerary_Item__c LIMIT 1];
        itineraryItem.KaptioTravel__IsOptional__c = true;
        update itineraryItem;
        test.stopTest();
    }

    @IsTest
    static void testDocumentHelper(){

        KaptioTravel__ItineraryFlightleg__c fl = [SELECT Id, KaptioTravel__DepartureDate__c, KaptioTravel__AirlineFSCode__c, KaptioTravel__FlightNumber__c, KaptioTravel__DepartureAirportName__c, KaptioTravel__ArrivalAirportName__c,
        KaptioTravel__Airline__r.Name, KaptioTravel__OperatedBy__c, KaptioTravel__OperatedBy__r.Name, KaptioTravel__DepartureTime__c, KaptioTravel__ArrivalDate__c, KaptioTravel__ArrivalTime__c,
        KaptioTravel__TravelClass__c, KaptioTravel__PNR__c, KaptioTravel__ArrivalAirport__r.RecordType.DeveloperName, KaptioTravel__ArrivalAirport__c, KaptioTravel__ItineraryItem__c 
        FROM KaptioTravel__ItineraryFlightLeg__c LIMIT 1];

        KaptioTravel__PNRFlightSegment__c pnr = [SELECT Id, KaptioTravel__DepartureDate__c, KaptioTravel__FlightNumber__c, KaptioTravel__DepartureAirport__r.Name, KaptioTravel__ArrivalAirport__r.Name,
        KaptioTravel__Airline__r.Name, KaptioTravel__OperatedBy__c, KaptioTravel__OperatedBy__r.Name, KaptioTravel__DepartureTime__c, KaptioTravel__ArrivalDate__c, KaptioTravel__ArrivalTime__c,
        KaptioTravel__TravelClass__c, KaptioTravel__VendorLocator__c, KaptioTravel__ArrivalAirport__r.RecordType.DeveloperName, KaptioTravel__ArrivalAirport__c, KaptioTravel__ItineraryItem__c,
        KaptioTravel__ArrivalTerminal__c, KaptioTravel__DepartureTerminal__c
        FROM KaptioTravel__PNRFlightSegment__c LIMIT 1 ];

        test.startTest();
            KTD_DocumentHelper.FlightLegDto fdto = new KTD_DocumentHelper.FlightLegDto(fl); 
            KTD_DocumentHelper.FlightLegDto pnrDTO = new KTD_DocumentHelper.FlightLegDto(pnr); 
        test.stopTest();
    }   

    /* KTD_DOCUMENT */
    @IsTest
    static void testDocumentController(){

        
        
        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];

        KaptioTravel__ItineraryContent__c document = [SELECT Id FROM KaptioTravel__ItineraryContent__c WHERE KaptioTravel__Itinerary__c =: itinerary.Id LIMIT 1];

        PageReference proposalPage = Page.KTD_Document;
        Test.setCurrentPage(proposalPage);
        ApexPages.currentPage().getParameters().put('id', document.Id);

        test.startTest();
        KTD_DocumentController ctrl = new KTD_DocumentController();
        test.stopTest();

        System.AssertEquals(ctrl.itinerary.Id, itinerary.Id);
    }

    /* KTD_DocumentPDF */
    @isTest
	private static void DocumentPDFControllerTest() {

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];

        KaptioTravel__ItineraryContent__c document = [SELECT Id FROM KaptioTravel__ItineraryContent__c WHERE KaptioTravel__Itinerary__c =: itinerary.Id LIMIT 1];

		Pagereference testPage = Page.KTD_DocumentPDF;
		System.Test.setCurrentPage(testPage);
		ApexPages.currentPage().getParameters().put('id', document.Id);

		System.Test.startTest();
			KTD_DocumentPDFController ctrl = new KTD_DocumentPDFController();
            		
		System.Test.stopTest();
	}

    
    /* KTD_DOCUMENTTemplate */
    @IsTest
    static void testDocumentTemplateController(){

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];

        KaptioTravel__ItineraryContent__c document = [SELECT Id FROM KaptioTravel__ItineraryContent__c WHERE KaptioTravel__Itinerary__c =: itinerary.Id LIMIT 1];

        PageReference proposalPage = Page.KTD_DocumentTemplate;
        Test.setCurrentPage(proposalPage);
        ApexPages.currentPage().getParameters().put('id', document.Id);

        test.startTest();
        KTD_DocumentTemplateController ctrl = new KTD_DocumentTemplateController();
        test.stopTest();

        System.AssertEquals(ctrl.itinerary.Id, itinerary.Id);
    }    


    /* KTD_DocumentInvoice */
    @isTest
	private static void DocumentInvoiceControllerTest() {

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];

        KaptioTravel__ItineraryContent__c document = [SELECT Id FROM KaptioTravel__ItineraryContent__c WHERE KaptioTravel__Itinerary__c =: itinerary.Id LIMIT 1];

		Pagereference testPage = Page.KTD_DocumentInvoice;
		System.Test.setCurrentPage(testPage);
		ApexPages.currentPage().getParameters().put('id', document.Id);

		System.Test.startTest();
			KTD_DocumentInvoiceController ctrl = new KTD_DocumentInvoiceController();
            		
		System.Test.stopTest();
	}

    @isTest
	private static void DocumentInvoiceControllerB2BTest() {
        
        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = true LIMIT 1];

        KaptioTravel__ItineraryContent__c document = [SELECT Id FROM KaptioTravel__ItineraryContent__c WHERE KaptioTravel__Itinerary__c =: itinerary.Id LIMIT 1];

		Pagereference testPage = Page.KTD_DocumentInvoice;
		System.Test.setCurrentPage(testPage);
		ApexPages.currentPage().getParameters().put('id', document.Id);

		System.Test.startTest();
			KTD_DocumentInvoiceController ctrl = new KTD_DocumentInvoiceController();            		
		System.Test.stopTest();
	}

    /* KTD_DocumentInvoiceTemplate */
    @isTest
	private static void DocumentInvoiceTemplateControllerTest() {
		KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];

        KaptioTravel__ItineraryContent__c document = [SELECT Id FROM KaptioTravel__ItineraryContent__c WHERE KaptioTravel__Itinerary__c =: itinerary.Id LIMIT 1];
        
        Pagereference testPage = Page.KTD_DocumentInvoice;
		System.Test.setCurrentPage(testPage);
		ApexPages.currentPage().getParameters().put('id', document.Id);

		System.Test.startTest();
			KTD_DocumentInvoiceTemplateController ctrl = new KTD_DocumentInvoiceTemplateController();            		
		System.Test.stopTest();
	}    


    /* KTD_ComponentItinerarySummary */
    @IsTest
    static void testComponentItinerarySummary(){

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];

        PageReference page = Page.KTD_ComponentItinerarySummary;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', itinerary.Id);

        test.startTest();
            KTD_ComponentItinerarySummaryController ctrl = new KTD_ComponentItinerarySummaryController();
            
            String body = ctrl.getBody();  
            System.assert(!ctrl.isEmpty());
            
        test.stopTest();
    }


    /* KTD_ComponentPricing */
    @IsTest
    static void testComponentPricing(){

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];
        
        PageReference page = Page.KTD_ComponentPricing;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', itinerary.Id);

        test.startTest();
        KTD_ComponentPricingController ctrl = new KTD_ComponentPricingController();
        String body = ctrl.getBody();
        test.stopTest();
    }

    /* KTD_ComponentBCOverview */
    @IsTest
    static void testComponentBCOverview(){

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];
        
        PageReference page = Page.KTD_ComponentBCOverview;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', itinerary.Id);

        test.startTest();
        KTD_ComponentBCOverviewController ctrl = new KTD_ComponentBCOverviewController();
        String body = ctrl.getBody();
        test.stopTest();
    }


        /* KTD_ComponentCancellation */
        @IsTest
        static void testComponentCancellation(){
    
            KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];
            
            PageReference page = Page.KTD_ComponentCancellation;
            Test.setCurrentPage(page);
            ApexPages.currentPage().getParameters().put('id', itinerary.Id);
    
            test.startTest();
            KTD_ComponentCancellationController ctrl = new KTD_ComponentCancellationController();
            
            ctrl.pageAction();
            String body = ctrl.getBody();
            Boolean isEmpty = ctrl.isEmpty();
            test.stopTest();
        }
    
    @IsTest
    static void testPricingWithItinerary(){

        KaptioTravel__Itinerary__c itinerary = [SELECT Id, KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c FROM KaptioTravel__Itinerary__c WHERE KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c = false LIMIT 1];
        
        PageReference pricingPage = Page.KTD_ComponentPricing;
        Test.setCurrentPage(pricingPage);
        ApexPages.currentPage().getParameters().put('id', itinerary.Id);

        test.startTest();
        KTD_ComponentPricingController pricingController = new KTD_ComponentPricingController();
        String body = pricingController.getBody();
        test.stopTest();
    }

    /* KTD_KTAgenda */
    @isTest
    private static void testCustomKTAgendaHandlerOutput() {

        KaptioTravel__ItineraryService__c itineraryService = [SELECT Id FROM KaptioTravel__ItineraryService__c LIMIT 1];
        List<KaptioTravel__ItineraryFlightLeg__c> flightLegs = [SELECT Id, KaptioTravel__DepartureDate__c, KaptioTravel__Airline__c, KaptioTravel__OperatedBy__c,
                                                        KaptioTravel__DepartureTime__c, KaptioTravel__ArrivalTime__c, KaptioTravel__ArrivalDate__c, 
                                                        KaptioTravel__ItineraryItem__c, KaptioTravel__FlightNumber__c, KaptioTravel__OperatedBy__r.Name,
                                                        KaptioTravel__Airline__r.Name
                                                        FROM KaptioTravel__ItineraryFlightLeg__c];
        List<KaptioTravel__Itinerary_Item__c> itineraryItems = [SELECT Id, KaptioTravel__CarPickUpLocation__c, KaptioTravel__CarPickUpLocation__r.KaptioTravel__Address__c,
                                                        KaptioTravel__CarPickUpLocation__r.KaptioTravel__ContactPhone__c, 
                                                        KaptioTravel__CarPickUpLocation__r.KaptioTravel__ContactEmail__c, 
                                                        KaptioTravel__CarPickUpLocation__r.KaptioTravel__OpeningTimes__c, 
                                                        KaptioTravel__CarPickUpLocation__r.KaptioTravel__SpecialInstructions__c, KaptioTravel__Voucher_Reference_No__c,
                                                        KaptioTravel__CarDropOffLocation__c, KaptioTravel__CarDropOffLocation__r.KaptioTravel__Address__c,
                                                        KaptioTravel__CarDropOffLocation__r.KaptioTravel__ContactPhone__c, 
                                                        KaptioTravel__CarDropOffLocation__r.KaptioTravel__ContactEmail__c, 
                                                        KaptioTravel__CarDropOffLocation__r.KaptioTravel__OpeningTimes__c, 
                                                        KaptioTravel__CarDropOffLocation__r.KaptioTravel__SpecialInstructions__c, KaptioTravel__CustomerNotes__c,
                                                        KaptioTravel__TrainStationStartLocation__c, KaptioTravel__TrainStationEndLocation__c, KaptioTravel__Item__c,
                                                        KaptioTravel__Item__r.KaptioTravel__Address__c,
                                                        KaptioTravel__TrainStationStartLocation__r.KaptioTravel__Address__c,
                                                        KaptioTravel__TrainStationEndLocation__r.KaptioTravel__Address__c, KaptioTravel__Supplier__r.BillingAddress,
                                                        KaptioTravel__Supplier__r.BillingStreet, KaptioTravel__Supplier__r.BillingCity, 
                                                        KaptioTravel__Supplier__r.BillingState, KaptioTravel__Supplier__r.BillingPostalCode, 
                                                        KaptioTravel__Supplier__r.BillingCountry, KaptioTravel__Item__r.RecordType.DeveloperName, KaptioTravel__ExternalItemName__c
                                                        FROM KaptioTravel__Itinerary_Item__c];
        Map<String, KaptioTravel__Itinerary_Item__c> itineraryItemByRecordType = new Map<String, KaptioTravel__Itinerary_Item__c>();
        for (KaptioTravel__Itinerary_Item__c itineraryItem : itineraryItems){
            itineraryItemByRecordType.put(itineraryItem.KaptioTravel__Item__r.RecordType.DeveloperName, itineraryItem);
        }
        List<KaptioTravel__Content__c> contentList = [SELECT Id FROM KaptioTravel__Content__c];
        List<KaptioTravel__PassengerItineraryUnitAssignment__c> assignmentList = [SELECT Id FROM KaptioTravel__PassengerItineraryUnitAssignment__c];

        Map<String, List<Sobject>> itineraryServiceMap = new Map<String, List<Sobject>>{'KaptioTravel__ItineraryServices__r' => new List<Sobject>{itineraryService}};


        CustomKTAgendaHandler handler = new CustomKTAgendaHandler();

        CustomKTAgendaHandler.MediaDTO media = new CustomKTAgendaHandler.MediaDTO();
        media.type = 'image';

        List<CustomKTAgendaHandler.ListingDTO> listingList = new List<CustomKTAgendaHandler.ListingDTO>();
        CustomKTAgendaHandler.ListingDTO carRentalListing = new CustomKTAgendaHandler.ListingDTO();
        carRentalListing.recordTypeName = 'Car_Rental';
        carRentalListing.childSobjects = itineraryServiceMap;
        carRentalListing.dateFrom = date.today();
        carRentalListing.dateTo = date.today();
        carRentalListing.itineraryItem = itineraryItemByRecordType.get('Car_Rental');
        carRentalListing.itinItemId = itineraryItemByRecordType.get('Car_Rental').Id;
        carRentalListing.itemContentId = contentList.get(0).Id;
        listingList.add(carRentalListing);
        CustomKTAgendaHandler.ListingDTO accommodationListing = new CustomKTAgendaHandler.ListingDTO();
        accommodationListing.recordTypeName = 'Accommodation';
        accommodationListing.childSobjects = itineraryServiceMap;
        accommodationListing.dateFrom = date.today();
        accommodationListing.dateTo = date.today() + 1;
        accommodationListing.itineraryItem = itineraryItemByRecordType.get('Accommodation');
        accommodationListing.itinItemId = itineraryItemByRecordType.get('Accommodation').Id;
        accommodationListing.content = 'test';
        accommodationListing.itemContentId = contentList.get(1).Id;
        accommodationListing.mediaList = new List<CustomKTAgendaHandler.MediaDTO>{media};
        listingList.add(accommodationListing);
        CustomKTAgendaHandler.ListingDTO flightListing = new CustomKTAgendaHandler.ListingDTO();
        flightListing.recordTypeName = 'FlightPlaceholder';
        flightListing.dateFrom = date.today();
        flightListing.dateTo = date.today();
        flightListing.itineraryItem = itineraryItemByRecordType.get('FlightPlaceholder');
        flightListing.itinItemId = itineraryItemByRecordType.get('FlightPlaceholder').Id;
        flightListing.itemContentId = contentList.get(2).Id;
        flightListing.childSobjects = new Map<String, List<SObject>>{'KaptioTravel__PassengerItineraryUnitAssignments__r' => assignmentList, 'KaptioTravel__Itinerary_Flight_Legs__r' => flightLegs};
        listingList.add(flightListing);
        CustomKTAgendaHandler.ListingDTO railListing = new CustomKTAgendaHandler.ListingDTO();
        railListing.recordTypeName = 'Rail';
        railListing.childSobjects = itineraryServiceMap;
        railListing.dateFrom = date.today();
        railListing.dateTo = date.today();
        railListing.itineraryItem = itineraryItemByRecordType.get('Rail');
        railListing.itinItemId = itineraryItemByRecordType.get('Rail').Id;
        railListing.content = 'test';
        railListing.itemContentId = contentList.get(3).Id;
        listingList.add(railListing);
        CustomKTAgendaHandler.ListingDTO cruiseListing = new CustomKTAgendaHandler.ListingDTO();
        cruiseListing.recordTypeName = 'Cruise';
        cruiseListing.childSobjects = itineraryServiceMap;
        cruiseListing.dateFrom = date.today();
        cruiseListing.dateTo = date.today();
        cruiseListing.itineraryItem = itineraryItemByRecordType.get('Cruise');
        cruiseListing.itinItemId = itineraryItemByRecordType.get('Cruise').Id;
        cruiseListing.itemContentId = contentList.get(4).Id;
        listingList.add(cruiseListing);
        CustomKTAgendaHandler.ListingDTO transferListing = new CustomKTAgendaHandler.ListingDTO();
        transferListing.recordTypeName = 'Transfer';
        transferListing.childSobjects = itineraryServiceMap;
        transferListing.dateFrom = date.today();
        transferListing.dateTo = date.today();
        transferListing.itineraryItem = itineraryItemByRecordType.get('Transfer');
        transferListing.itinItemId = itineraryItemByRecordType.get('Transfer').Id;
        transferListing.itemContentId = contentList.get(5).Id;
        listingList.add(transferListing);

        CustomKTAgendaHandler.KtAgendaDTO agenda = new CustomKTAgendaHandler.KtAgendaDTO();
        agenda.listings = new List<CustomKTAgendaHandler.ListingDTO>(listingList);
        CustomKTAgendaHandler.KtAgendaDayDto agendaDay = new CustomKTAgendaHandler.KtAgendaDayDto();
        agendaDay.listings = new List<CustomKTAgendaHandler.ListingDTO>(listingList);
        agendaDay.dayDate = date.today();

        Map<String, Object> response = handler.doAction('KTAgenda.getEvaluated', new Map<String, Object>{'agendaDaysByIndex' => new Map<Integer, Object>{1 => new List<CustomKTAgendaHandler.KtAgendaDayDto>{agendaDay}}, 'agendaDataByIndex' => new Map<Integer, Object>{1 => agenda}});
        Map<Integer, List<String>> responseMap = (Map<Integer, List<String>>)response.get('agendaOutputBlocksByIndex');
        String carRentalAddress, accommodationDate;
        for (String s : responseMap.get(1)){
            if (s.contains('Pick-up address:'))
                carRentalAddress = s;
            if (s.contains('Check-in date:'))
                accommodationDate= s;
        }

        System.assertEquals(carRentalAddress, '<div class="at-agenda-item-info-row"><div class="bold-label table">Pick-up address: </div><div class="table-value">test</div></div>');
    }
}