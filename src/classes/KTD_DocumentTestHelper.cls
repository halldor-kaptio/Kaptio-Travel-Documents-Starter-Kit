/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 10-12-2023
 * @last modified by  : Kaptio Developer
**/
public with sharing class KTD_DocumentTestHelper {
    public KaptioTravel__ItineraryContent__c content;
    public KaptioTravel__Itinerary__c itinerary;
    public KaptioTravel__Itinerary__c B2BItinerary;
    public Account customer, acc;
    public static final Integer START_DAY = 10;
    public static final Integer END_DAY = 15;
    public KaptioTravel__Brand__c brand;
    public KaptioTravel__Language__c language;

    public KTD_DocumentTestHelper(Boolean insertItineraryItem){

        KaptioTravel__AppSettings__c app = new KaptioTravel__AppSettings__c(
            KaptioTravel__Override_Itinerary_Date_Restrictions__c = false,
            KaptioTravel__LocationRecordTypeHierarchy__c = 'Country,Region,City',
            KaptioTravel__EnableLocations__c = true
        );
        insert app;

        Map<String,Schema.RecordTypeInfo> LocationRtMapByDevName = Schema.SObjectType.KaptioTravel__Location__c.getRecordTypeInfosByDeveloperName(); 
        KaptioTravel__Location__c location = new KaptioTravel__Location__c(
            RecordTypeId = LocationRtMapByDevName.get('City').getRecordTypeId(),
            Name = 'London'
        );
        insert location ;


        brand = new KaptioTravel__Brand__c(
            KaptioTravel__BrandAddress__c = 'Address \n Fun Address \r More fun',
            KaptioTravel__CreditInvoicePrefix__c = 'KTC',
            KaptioTravel__CreditInvoiceSequence__c = 1000,
            KaptioTravel__SalesInvoicePrefix__c = 'KTI',
            KaptioTravel__SalesInvoiceSequence__c = 1000,
            KaptioTravel__SupplierInvoicePrefix__c = 'KTS',
            KaptioTravel__AvailableCurrencies__c = UserInfo.getDefaultCurrency(),
            KaptioTravel__TaxHandling__c = 'Exclusive',
            KaptioTravel__ResellerStatementPrefix__c = 'VK',
            Name = 'KTUK'
            );
        insert brand;
        
        KaptioTravel__Group__c taxgroup = new KaptioTravel__Group__c(
                KaptioTravel__TypeId__c = '0',
                KaptioTravel__TypeName__c = 'TYPE_NAME'
            );
        insert taxgroup;
        

        KaptioTravel__TaxProfile__c taxProfile = new KaptioTravel__TaxProfile__c(
            Name = 'Test Tax Profile');
        insert taxProfile;
        
        customer = new Account(
            FirstName = 'Test',
            LastName = 'Customer', 
            KaptioTravel__ConfirmationMethod__c = 'Confirmation Not Needed',
            AccountSource='Word of Mouth', 
            KaptioTravel__TaxProfile__c = taxProfile.Id,
            PersonEmail = 'test@test.com',
            Phone = '123',
            KaptioTravel__Email__c = 'test@test.com'
            );
        insert customer;

        acc = new Account(
            Name = 'test',
            BillingCountry = 'United Kingdom'
        );
        insert acc;

        Account airline = new Account(
            Name = 'test',
            BillingCountry = 'United Kingdom',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Airline').getRecordTypeId()
        );
        insert airline;

        
        Contact cnt = new contact(
            LastName = 'Contact',
            FirstName = 'Test',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        insert cnt;

        language = new KaptioTravel__Language__c(
            Name = 'english',
            KaptioTravel__IsActive__c = true,
            KaptioTravel__IsoCode__c = 'en'
        );
        insert language;

        KaptioTravel__BookingNumberScheme__c bns = new KaptioTravel__BookingNumberScheme__c(
                KaptioTravel__BookingPrefix__c = 'KT',
                KaptioTravel__BookingNumberSequence__c = 0
        );
        insert bns;
        
        KaptioTravel__ChannelRoleConfiguration__c crc = new KaptioTravel__ChannelRoleConfiguration__c(
                Name = 'test channel role'
        );
        insert crc;                                                 
        
        KaptioTravel__Channel__c channel = new KaptioTravel__Channel__c(
                Name = 'UK B2C',
                KaptioTravel__Brand__c = brand.Id,
                KaptioTravel__Language__c = language.Id,
                KaptioTravel__ChannelCode__c = 'UKB2C',
                KaptioTravel__AvailableCurrencies__c = UserInfo.getDefaultCurrency(),
                KaptioTravel__BookingNumberScheme__c = bns.Id,
                KaptioTravel__ChannelRoleConfiguration__c = crc.Id,
                Kaptiotravel__ContentExpirationDays__c = 7,
                KaptioTravel__SOAEnabled__c = true);
        insert channel;

        KaptioTravel__Channel__c B2BChannel = new KaptioTravel__Channel__c(
                Name = 'UK B2B',
                KaptioTravel__Brand__c = brand.Id,
                KaptioTravel__Language__c = language.Id,
                KaptioTravel__ChannelCode__c = 'UKB2B',
                KaptioTravel__IsB2BChannel__c = true,
                KaptioTravel__AvailableCurrencies__c = UserInfo.getDefaultCurrency(),
                KaptioTravel__BookingNumberScheme__c = bns.Id,
                KaptioTravel__ChannelRoleConfiguration__c = crc.Id,
                Kaptiotravel__ContentExpirationDays__c = 7,
                KaptioTravel__SOAEnabled__c = true);
        insert B2BChannel;


        KaptioTravel__Trip__c trip = new KaptioTravel__Trip__c(
            Name = 'test trip',
            KaptioTravel__Channel__c = channel.Id, 
            KaptioTravel__Account__c = customer.Id,
            KaptioTravel__GroupSize__c = 2
        );
        insert trip;

        itinerary = new KaptioTravel__Itinerary__c(
            KaptioTravel__Start_Date__c = Date.today().addDays(START_DAY),
            KaptioTravel__End_Date__c = Date.today().addDays(END_DAY+3),
            KaptioTravel__Channel__c = channel.Id,
            KaptioTravel__CurrencyFactor__c = 1,
            CurrencyIsoCode = UserInfo.getDefaultCurrency(),
            OwnerId = UserInfo.getUserId(),
            KaptioTravel__Account__c = customer.Id,
            KaptioTravel__Primary_Contact__c = cnt.Id,
            KaptioTravel__Group_Size__c = 2,
            KaptioTravel__Trip__c = trip.Id,
            RecordTypeId = Schema.SObjectType.KaptioTravel__Itinerary__c.getRecordTypeInfosByDeveloperName().get('Quote').getRecordTypeId()
        );
        insert itinerary;

        B2BItinerary = new KaptioTravel__Itinerary__c(
            KaptioTravel__Start_Date__c = Date.today().addDays(START_DAY),
            KaptioTravel__End_Date__c = Date.today().addDays(END_DAY+3),
            KaptioTravel__Channel__c = B2BChannel.Id,
            KaptioTravel__CurrencyFactor__c = 1,
            CurrencyIsoCode = UserInfo.getDefaultCurrency(),
            OwnerId = UserInfo.getUserId(),
            KaptioTravel__Account__c = customer.Id,
            KaptioTravel__Primary_Contact__c = cnt.Id,
            KaptioTravel__Group_Size__c = 2,
            KaptioTravel__Trip__c = trip.Id,
            RecordTypeId = Schema.SObjectType.KaptioTravel__Itinerary__c.getRecordTypeInfosByDeveloperName().get('Quote').getRecordTypeId()
        );
        insert B2BItinerary;
        
        KaptioTravel__Passenger__c B2BPassenger = new KaptioTravel__Passenger__c(
            KaptioTravel__Itinerary__c = B2BItinerary.Id,
            KaptioTravel__FirstName__c = 'Sam',
            KaptioTravel__LastName__c = 'Traveller' 
        );
        Database.insert(B2BPassenger);


        // addItems(itinerary.Id, taxgroup.Id, airline.Id, acc.Id, location.Id, insertItineraryItem);
        addItemsLight(itinerary.Id, taxgroup.Id, airline.Id, acc.Id, location.Id, insertItineraryItem);

        KaptioTravel__Image__c image = new KaptioTravel__Image__c(
            KaptioTravel__S3_Url__c = 'http://example.com'
        );
        insert image;


        content = new KaptioTravel__ItineraryContent__c(
            KaptioTravel__ExpirationDate__c = Date.today().addDays(END_DAY),
            KaptioTravel__Itinerary__c = itinerary.Id,
            KaptioTravel__IsLocked__c = false,
            KaptioTravel__ItineraryJSON__c = JSON.serialize(getItinerary(itinerary.Id)),
            KaptioTravel__IsPublished__c = true,
            KaptioTravel__Status__c = 'Published',
            KaptioTravel__PublishURL__c = 'http://test.com',
            KaptioTravel__StageType__c = 'Quote',
            KaptioTravel__Content__c = '{}',
            KaptioTravel__ContentHtml__c = 'output',
            KaptioTravel__BannerImage__c = image.Id
            );
        insert content;

        KaptioTravel__ItineraryContent__c B2BContent = new KaptioTravel__ItineraryContent__c(
            KaptioTravel__ExpirationDate__c = Date.today().addDays(END_DAY),
            KaptioTravel__Itinerary__c = B2BItinerary.Id,
            KaptioTravel__IsLocked__c = false,
            KaptioTravel__ItineraryJSON__c = JSON.serialize(getItinerary(B2BItinerary.Id)),
            KaptioTravel__IsPublished__c = true,
            KaptioTravel__Status__c = 'Published',
            KaptioTravel__PublishURL__c = 'http://test.com',
            KaptioTravel__StageType__c = 'Quote',
            KaptioTravel__Content__c = '{}',
            KaptioTravel__ContentHtml__c = 'output',
            KaptioTravel__BannerImage__c = image.Id
            );
        insert B2BContent;
    }

    public KaptioTravel__Itinerary_Item__c newItineraryItem(Id itineraryId, Id accountId) {
        KaptioTravel__Itinerary_Item__c itineraryItem = new KaptioTravel__Itinerary_Item__c(
            KaptioTravel__Itinerary__c = itineraryId,
            KaptioTravel__Quantity__c = 1,
            KaptioTravel__Tax_Total__c = 0,
            KaptioTravel__Tax_Percent__c = 0,
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__DateFrom__c = Date.today().addDays(START_DAY),
            KaptioTravel__Unit_Price__c = 100,
            KaptioTravel__Total_Price__c = 100,
            CurrencyIsoCode = UserInfo.getDefaultCurrency(),
            KaptioTravel__SupplierCurrencyIsoCode__c = UserInfo.getDefaultCurrency(),
            KaptioTravel__SupplierUnitCost__c = 100,
            KaptioTravel__InvoiceTo__c = accountId
        );
        return itineraryItem;
    }

    public KaptioTravel__Group__c newGroup() {
        KaptioTravel__Group__c gr = new KaptioTravel__Group__c(
            KaptioTravel__TypeId__c = '0',
            KaptioTravel__TypeName__c = 'TYPE_NAME'
        );
        return gr;
    }

    public KaptioTravel__Item__c newItem(Id groupId) {
        KaptioTravel__Item__c item = new KaptioTravel__Item__c(
            KaptioTravel__TaxGroup__c = groupId,
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '11:00' 
        );
        return item;
    }

    public void addItemsLight(Id itineraryId, Id groupId, Id airlineId, Id accountId, Id locationId, Boolean addItineraryItems) {
        List<KaptioTravel__PriceCategoryType__c> priceCategoryTypes = new List<KaptioTravel__PriceCategoryType__c>();

        for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'KaptioTravel__Item__c' AND IsActive = true]) {
            priceCategoryTypes.add(new KaptioTravel__PriceCategoryType__c(
                CurrencyIsoCode = UserInfo.getDefaultCurrency(),
                KaptioTravel__Label__c ='Type',
                KaptioTravel__FieldSet__c = 'KaptioTravel__AccommodationPriceCategoryFields',
                KaptioTravel__RecordTypeKey__c = rt.DeveloperName,
                KaptioTravel__PluralLabel__c = 'Types',
                KaptioTravel__DefaultCheckOutTime__c = '14:00',
                KaptioTravel__DefaultCheckInTime__c = '11:00',
                KaptioTravel__JSONQuickAdd__c = '{"size":0,"records":[{"record":{"attributes":{"type":"KaptioTravel__Price_Category__c"},"KaptioTravel__TicketType__c":"adult","KaptioTravel__Allocation__c":"booking","KaptioTravel__IsActive__c":true,"KaptioTravel__Sort__c":1.0,"KaptioTravel__UOM__c":"person(s)","Name":"Adult"},"key":0,"isSelected":true},{"record":{"attributes":{"type":"KaptioTravel__Price_Category__c"},"KaptioTravel__TicketType__c":"child","KaptioTravel__Allocation__c":"booking","KaptioTravel__Min_Age__c":6.0,"KaptioTravel__IsActive__c":true,"KaptioTravel__Sort__c":2.0,"KaptioTravel__UOM__c":"person(s)","KaptioTravel__Max_Age__c":12.0,"Name":"Child"},"key":1,"isSelected":true}],"message":"No records were found.","isEmpty":true}',
                KaptioTravel__JSONPrePopulation__c = '{"attributes":{"type":"KaptioTravel__Price_Category__c"},"KaptioTravel__TicketType__c":"adult","KaptioTravel__Allocation__c":"booking","KaptioTravel__IsActive__c":true,"KaptioTravel__UOM__c":"person(s)"}',
                KaptioTravel__DefaultAllocationType__c = 'booking'));
        }
        Database.insert(priceCategoryTypes);

        Map<String,Schema.RecordTypeInfo> rtMapByDevName = Schema.SObjectType.KaptioTravel__Item__c.getRecordTypeInfosByDeveloperName();

        List<KaptioTravel__Item__c> itemList = new List<KaptioTravel__Item__c>();

        KaptioTravel__Item__c carRentalItem = new KaptioTravel__Item__c(
            Name = 'Car Rental',
            KaptioTravel__ExternalName__c = 'Car Rental',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Car_Rental').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(carRentalItem);

        KaptioTravel__Item__c accommodationItem = new KaptioTravel__Item__c(
            Name = 'Accommodation',
            KaptioTravel__ExternalName__c = 'Accommodation',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Accommodation').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(accommodationItem);

        KaptioTravel__Item__c flightItem = new KaptioTravel__Item__c(
            Name = 'Flight',
            KaptioTravel__ExternalName__c = 'Flight',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = airlineId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('FlightPlaceholder').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(flightItem);

        KaptioTravel__Item__c railItem = new KaptioTravel__Item__c(
            Name = 'Rail',
            KaptioTravel__ExternalName__c = 'Rail',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Rail').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(railItem);

        KaptioTravel__Item__c cruiseItem = new KaptioTravel__Item__c(
            Name = 'Cruise',
            KaptioTravel__ExternalName__c = 'Cruise',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Cruise').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(cruiseItem);

        KaptioTravel__Item__c transferItem = new KaptioTravel__Item__c(
            Name = 'Transfer',
            KaptioTravel__ExternalName__c = 'Transfer',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Transfer').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(transferItem);

        KaptioTravel__Item__c PNRflightItem = new KaptioTravel__Item__c(
            Name = 'PNR Flight',
            KaptioTravel__ExternalName__c = 'PNR Flight',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = airlineId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('PNRFlight').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(PNRflightItem);

        insert itemList;

        KaptioTravel__CarRentalLocation__c carRentalLocation = new KaptioTravel__CarRentalLocation__c(
            KaptioTravel__Address__c = 'test',
            KaptioTravel__ContactPhone__c = '123',
            KaptioTravel__ContactEmail__c = 'test@test.com',
            KaptioTravel__OpeningTimes__c = 'test',
            KaptioTravel__SpecialInstructions__c = 'test',
            KaptioTravel__Item__c = carRentalItem.Id,
            KaptioTravel__Location__c = locationId
        );
        insert carRentalLocation;

        List<KaptioTravel__Itinerary_Item__c> items = new List<KaptioTravel__Itinerary_Item__c>();

        KaptioTravel__Itinerary_Item__c carRental = newItineraryItem(itinerary.Id,  acc.Id);
        carRental.KaptioTravel__CarPickUpLocation__c = carRentalLocation.Id;
        carRental.KaptioTravel__CarDropOffLocation__c = carRentalLocation.Id;
        carRental.KaptioTravel__Voucher_Reference_No__c = '123';
        carRental.KaptioTravel__CustomerNotes__c = 'test';
        carRental.KaptioTravel__Item__c = carRentalItem.Id;
        carRental.KaptioTravel__ExternalItemName__c = 'Car Rental';
        carRental.KaptioTravel__DateTo__c = System.today().addDays(END_DAY+3);
        items.add(carRental);

        KaptioTravel__Itinerary_Item__c PNRflight = newItineraryItem(itinerary.Id,  acc.Id);
        PNRflight.KaptioTravel__Voucher_Reference_No__c = '123';
        PNRflight.KaptioTravel__CustomerNotes__c = 'test';
        PNRflight.KaptioTravel__Item__c = PNRflightItem.Id;
        PNRflight.KaptioTravel__ExternalItemName__c = 'PNR Flight';
        PNRflight.KaptioTravel__DateTo__c = System.today().addDays(1);
        items.add(PNRFlight);

        KaptioTravel__Itinerary_Item__c accommodation = newItineraryItem(itinerary.Id,  acc.Id);
        accommodation.KaptioTravel__Voucher_Reference_No__c = '123';
        accommodation.KaptioTravel__CustomerNotes__c = 'test';
        accommodation.KaptioTravel__Item__c = itemList.get(1).Id;
        accommodation.KaptioTravel__DateTo__c = System.today().addDays(END_DAY);
        accommodation.KaptioTravel__ExternalItemName__c = 'Accommodation';
        // accommodation.KaptioTravel__Price_Category__c = pc.Id;
        items.add(accommodation);

        KaptioTravel__Itinerary_Item__c flight = newItineraryItem(itinerary.Id,  acc.Id);
        flight.KaptioTravel__Voucher_Reference_No__c = '123';
        flight.KaptioTravel__CustomerNotes__c = 'test';
        flight.KaptioTravel__Item__c = itemList.get(2).Id;
        flight.KaptioTravel__ExternalItemName__c = 'Flight Placeholder';
        flight.KaptioTravel__DateTo__c = System.today().addDays(1);
        items.add(flight);

        // KaptioTravel__TrainStationLocation__c trainStationLocation = new KaptioTravel__TrainStationLocation__c(
        //     KaptioTravel__Address__c = 'test',
        //     KaptioTravel__Service__c = carRentalItem.Id,
        //     KaptioTravel__Location__c = locationId
        // );
        // insert trainStationLocation;


        KaptioTravel__ServiceLocationJunction__c ServiceLocationJunction = new KaptioTravel__ServiceLocationJunction__c(
            KaptioTravel__Service__c = railItem.Id,
            KaptioTravel__Location__c = locationId
        );

        KaptioTravel__Itinerary_Item__c rail = newItineraryItem(itinerary.Id,  acc.Id);
        rail.KaptioTravel__Voucher_Reference_No__c = '123';
        rail.KaptioTravel__CustomerNotes__c = 'test';
        rail.KaptioTravel__TrainStationStart__c = ServiceLocationJunction.Id;
        rail.KaptioTravel__TrainStationEnd__c = ServiceLocationJunction.Id;
        rail.KaptioTravel__Item__c = itemList.get(3).Id;
        rail.KaptioTravel__ExternalItemName__c = 'Rail';
        items.add(rail);

        KaptioTravel__ServiceDeparture__c serviceDeparture = new KaptioTravel__ServiceDeparture__c(
            Name = 'Cruise Departure',
            KaptioTravel__DepartureDate__c = System.today().addDays(START_DAY),
            KaptioTravel__IsActive__c = true,
            KaptioTravel__Length__c = 3,
            KaptioTravel__Service__c = cruiseItem.Id,
            KaptioTravel__Type__c = 'Cruise'                
        );
        insert serviceDeparture;

        KaptioTravel__Itinerary_Item__c cruise = newItineraryItem(itinerary.Id,  acc.Id);
        cruise.KaptioTravel__Voucher_Reference_No__c = '123';
        cruise.KaptioTravel__CustomerNotes__c = 'test';
        cruise.KaptioTravel__Item__c = itemList.get(4).Id;
        cruise.KaptioTravel__ExternalItemName__c = 'Cruise';
        cruise.KaptioTravel__DateTo__c = System.today().addDays(END_DAY);
        cruise.KaptioTravel__ServiceDeparture__c = serviceDeparture.Id;
        items.add(cruise);

        KaptioTravel__Itinerary_Item__c transfer = newItineraryItem(itinerary.Id,  acc.Id);
        transfer.KaptioTravel__Voucher_Reference_No__c = '123';
        transfer.KaptioTravel__CustomerNotes__c = 'test';
        transfer.KaptioTravel__Item__c = itemList.get(5).Id;
        transfer.KaptioTravel__ExternalItemName__c = 'Transfer';
        items.add(transfer);

        insert items;

        KaptioTravel__ItineraryFlightLeg__c flightLeg1 = new KaptioTravel__ItineraryFlightLeg__c(
            KaptioTravel__DepartureDate__c = date.today(),
            KaptioTravel__Airline__c = acc.Id,
            KaptioTravel__OperatedBy__c = airlineId,
            KaptioTravel__DepartureTime__c = '14:00',
            KaptioTravel__ArrivalTime__c = '18:00',
            KaptioTravel__ArrivalDate__c = date.today().addDays(START_DAY),
            KaptioTravel__ItineraryItem__c = items[1].Id,
            KaptioTravel__FlightNumber__c = '123'
        );
        insert flightLeg1;

        KaptioTravel__Addon__c addon = new KaptioTravel__Addon__c(
            KaptioTravel__Item__c = PNRflightItem.Id,
            KaptioTravel__Allocation__c = 'booking',
            KaptioTravel__UOM__c = 'Unit(s)'
        );
        insert addon;

        KaptioTravel__Price_Category__c priceCat = new KaptioTravel__Price_Category__c(
            Name = 'Test',
            KaptioTravel__Item__c = PNRflightItem.Id,
            KaptioTravel__MaxPeople__c = 2,
            KaptioTravel__MaxAdults__c = 2,
            KaptioTravel__MaxChildren__c = 0,
            KaptioTravel__MaxInfants__c = 0
        );
        Database.insert(priceCat);

        KaptioTravel__ConnectFlightSupplier__c cfs = new KaptioTravel__ConnectFlightSupplier__c(
            Name = 'Connect Flight Supplier'
        );
        insert cfs;

        KaptioTravel__ConnectFlightGateway__c cfg = new KaptioTravel__ConnectFlightGateway__c(
            Name = 'Connect Flight Gateway',
            KaptioTravel__InvoiceTo__c = acc.Id,
            KaptioTravel__IsActive__c = true,
            KaptioTravel__AddonId__c = addon.Id,
            KaptioTravel__FareId__c = priceCat.Id,
            KaptioTravel__ConnectFlightSupplier__c = cfs.Id
        );
        insert cfg;

        KaptioTravel__PNR__c pnr = new KaptioTravel__PNR__c(
            Name = 'My pnr',
            KaptioTravel__Itinerary__c = itinerary.Id,
            KaptioTravel__BusinessUnit__c = brand.Id,
            KaptioTravel__ConnectFlightGateway__c = cfg.Id
        );
        insert pnr;

        KaptioTravel__PNRFlightSegment__c PNRFlightSegment = new KaptioTravel__PNRFlightSegment__c(
            KaptioTravel__DepartureDate__c = date.today(),
            KaptioTravel__Airline__c = acc.Id,
            KaptioTravel__OperatedBy__c = airlineId,
            KaptioTravel__DepartureTime__c = Time.newInstance(20,0, 0, 0),
            KaptioTravel__ArrivalTime__c = Time.newInstance(23,0, 0, 0),
            KaptioTravel__ArrivalDate__c = date.today().addDays(START_DAY) + 1,
            KaptioTravel__ItineraryItem__c = items[1].Id,
            KaptioTravel__FlightNumber__c = '122' ,  
            KaptioTravel__DepartureTerminal__c = 'T2',
            KaptioTravel__ArrivalTerminal__c = 'T2',
            KaptioTravel__PNR__c = pnr.Id,
            KaptioTravel__ArrivalAirport__c = locationId,
            KaptioTravel__DepartureAirport__c = locationId,
            KaptioTravel__FlyingTime__c = '20:00'
        );
        insert PNRFlightSegment;

        KaptioTravel__ItineraryService__c itineraryService = new KaptioTravel__ItineraryService__c(
            KaptioTravel__ItineraryItem__c = items[1].Id
        );
        insert itineraryService;

        addContent('Item', 6);
    }

    public void addItems(Id itineraryId, Id groupId, Id airlineId, Id accountId, Id locationId, Boolean addItineraryItems){

        Map<String,Schema.RecordTypeInfo> rtMapByDevName = Schema.SObjectType.KaptioTravel__Item__c.getRecordTypeInfosByDeveloperName();

        List<KaptioTravel__PriceCategoryType__c> priceCategoryTypes = new List<KaptioTravel__PriceCategoryType__c>();
            for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'KaptioTravel__Item__c' AND IsActive = true]) {
               
                priceCategoryTypes.add(new KaptioTravel__PriceCategoryType__c(
                        CurrencyIsoCode = UserInfo.getDefaultCurrency(),
                        KaptioTravel__Label__c ='Type',
                        KaptioTravel__FieldSet__c = 'KaptioTravel__AccommodationPriceCategoryFields',
                        KaptioTravel__RecordTypeKey__c = rt.DeveloperName,
                        KaptioTravel__PluralLabel__c = 'Types',
                        KaptioTravel__DefaultCheckOutTime__c = '14:00',
                        KaptioTravel__DefaultCheckInTime__c = '11:00',
                        KaptioTravel__JSONQuickAdd__c = '{"size":0,"records":[{"record":{"attributes":{"type":"KaptioTravel__Price_Category__c"},"KaptioTravel__TicketType__c":"adult","KaptioTravel__Allocation__c":"booking","KaptioTravel__IsActive__c":true,"KaptioTravel__Sort__c":1.0,"KaptioTravel__UOM__c":"person(s)","Name":"Adult"},"key":0,"isSelected":true},{"record":{"attributes":{"type":"KaptioTravel__Price_Category__c"},"KaptioTravel__TicketType__c":"child","KaptioTravel__Allocation__c":"booking","KaptioTravel__Min_Age__c":6.0,"KaptioTravel__IsActive__c":true,"KaptioTravel__Sort__c":2.0,"KaptioTravel__UOM__c":"person(s)","KaptioTravel__Max_Age__c":12.0,"Name":"Child"},"key":1,"isSelected":true}],"message":"No records were found.","isEmpty":true}',
                        KaptioTravel__JSONPrePopulation__c = '{"attributes":{"type":"KaptioTravel__Price_Category__c"},"KaptioTravel__TicketType__c":"adult","KaptioTravel__Allocation__c":"booking","KaptioTravel__IsActive__c":true,"KaptioTravel__UOM__c":"person(s)"}',
                        KaptioTravel__DefaultAllocationType__c = 'booking'));
            }
            Database.insert(priceCategoryTypes);


        List<KaptioTravel__Item__c> itemList = new List<KaptioTravel__Item__c>();
        KaptioTravel__Item__c carRentalItem = new KaptioTravel__Item__c(
            Name = 'Car Rental',
            KaptioTravel__ExternalName__c = 'Car Rental',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Car_Rental').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(carRentalItem);
        KaptioTravel__Item__c accommodationItem = new KaptioTravel__Item__c(
            Name = 'Accommodation',
            KaptioTravel__ExternalName__c = 'Accommodation',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Accommodation').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(accommodationItem);
        KaptioTravel__Item__c flightItem = new KaptioTravel__Item__c(
            Name = 'Flight',
            KaptioTravel__ExternalName__c = 'Flight',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = airlineId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('FlightPlaceholder').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(flightItem);
        KaptioTravel__Item__c railItem = new KaptioTravel__Item__c(
            Name = 'Rail',
            KaptioTravel__ExternalName__c = 'Rail',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Rail').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(railItem);
        KaptioTravel__Item__c cruiseItem = new KaptioTravel__Item__c(
            Name = 'Cruise',
            KaptioTravel__ExternalName__c = 'Cruise',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Cruise').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(cruiseItem);
        KaptioTravel__Item__c transferItem = new KaptioTravel__Item__c(
            Name = 'Transfer',
            KaptioTravel__ExternalName__c = 'Transfer',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = accountId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('Transfer').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(transferItem);
        KaptioTravel__Item__c PNRflightItem = new KaptioTravel__Item__c(
            Name = 'PNR Flight',
            KaptioTravel__ExternalName__c = 'PNR Flight',
            KaptioTravel__AllocationType__c = 'night',
            KaptioTravel__Supplier__c = airlineId,
            KaptioTravel__TaxGroup__c = groupId,
            RecordTypeId = rtMapByDevName.get('PNRFlight').getRecordTypeId(),
            KaptioTravel__CheckInTime__c = '14:00',
            KaptioTravel__CheckOutTime__c = '12:00',
            KaptioTravel__Location__c = locationId,
            KaptioTravel__Address__c = 'test'
        );
        itemList.add(PNRflightItem);
        
        insert itemList;

        KaptioTravel__Price_Category__c pc = new KaptioTravel__Price_Category__c(
            Name = 'Double Room',
            KaptioTravel__Item__c = accommodationItem.Id,
            KaptioTravel__IsActive__c = true,
            KaptioTravel__Sort__c = 1,
            KaptioTravel__AccommodationType__c = 'Hotel',
            KaptioTravel__UOM__c = 'room(s)',
            KaptioTravel__MaxPeople__c = 2,
            KaptioTravel__MaxAdults__c = 2,
            KaptioTravel__MaxChildren__c = 0,
            KaptioTravel__MaxInfants__c = 0

        );
        //insert pc;

        List<KaptioTravel__Content__c> content = addContent('Item', 6);

        if(addItineraryItems){
            KaptioTravel__CarRentalLocation__c carRentalLocation = new KaptioTravel__CarRentalLocation__c(
                KaptioTravel__Address__c = 'test',
                KaptioTravel__ContactPhone__c = '123',
                KaptioTravel__ContactEmail__c = 'test@test.com',
                KaptioTravel__OpeningTimes__c = 'test',
                KaptioTravel__SpecialInstructions__c = 'test',
                KaptioTravel__Item__c = carRentalItem.Id,
                KaptioTravel__Location__c = locationId
            );
            insert carRentalLocation;
    
            // KaptioTravel__TrainStationLocation__c trainStationLocation = new KaptioTravel__TrainStationLocation__c(
            //     KaptioTravel__Address__c = 'test',
            //     KaptioTravel__Service__c = carRentalItem.Id,
            //     KaptioTravel__Location__c = locationId
            // );
            // insert trainStationLocation;

            KaptioTravel__ServiceLocationJunction__c ServiceLocationJunction = new KaptioTravel__ServiceLocationJunction__c(
                KaptioTravel__Service__c = railItem.Id,
                KaptioTravel__Location__c = locationId
            );
            
            KaptioTravel__ServiceDeparture__c serviceDeparture = new KaptioTravel__ServiceDeparture__c(
                Name = 'Cruise Departure',
                KaptioTravel__DepartureDate__c = System.today().addDays(START_DAY),
                KaptioTravel__IsActive__c = true,
                KaptioTravel__Length__c = 3,
                KaptioTravel__Service__c = cruiseItem.Id,
                KaptioTravel__Type__c = 'Cruise'                
            );
            insert serviceDeparture;

            List<KaptioTravel__ServiceDepartureLocation__c> sdl = new List<KaptioTravel__ServiceDepartureLocation__c>();
            KaptioTravel__ServiceDepartureLocation__c l1 = new KaptioTravel__ServiceDepartureLocation__c(
                KaptioTravel__Day__c = 1,
                KaptioTravel__StartLocation__c = locationId,
                KaptioTravel__EndLocation__c = locationId,
                KaptioTravel__ServiceDeparture__c = serviceDeparture.Id
            );
            sdl.add(l1);

            insert sdl;

            
            List<KaptioTravel__Itinerary_Item__c> itineraryItemList = new List<KaptioTravel__Itinerary_Item__c>();
            KaptioTravel__Itinerary_Item__c carRental = newItineraryItem(itineraryId,  accountId);
            carRental.KaptioTravel__CarPickUpLocation__c = carRentalLocation.Id;
            carRental.KaptioTravel__CarDropOffLocation__c = carRentalLocation.Id;
            carRental.KaptioTravel__Voucher_Reference_No__c = '123';
            carRental.KaptioTravel__CustomerNotes__c = 'test';
            carRental.KaptioTravel__Item__c = itemList.get(0).Id;
            carRental.KaptioTravel__ExternalItemName__c = 'Car Rental';
            carRental.KaptioTravel__DateTo__c = System.today().addDays(END_DAY+3);
            itineraryItemList.add(carRental);
    
            KaptioTravel__Itinerary_Item__c accommodation = newItineraryItem(itineraryId,  accountId);
            accommodation.KaptioTravel__Voucher_Reference_No__c = '123';
            accommodation.KaptioTravel__CustomerNotes__c = 'test';
            accommodation.KaptioTravel__Item__c = itemList.get(1).Id;
            accommodation.KaptioTravel__DateTo__c = System.today().addDays(END_DAY);
            accommodation.KaptioTravel__ExternalItemName__c = 'Accommodation';
            accommodation.KaptioTravel__Price_Category__c = pc.Id;
            itineraryItemList.add(accommodation);

            KaptioTravel__Itinerary_Item__c accommodation2 = newItineraryItem(itineraryId,  accountId);
            accommodation2.KaptioTravel__Voucher_Reference_No__c = '123';
            accommodation2.KaptioTravel__CustomerNotes__c = 'test';
            accommodation2.KaptioTravel__Item__c = itemList.get(1).Id;
            accommodation2.KaptioTravel__DateTo__c = System.today().addDays(END_DAY);
            accommodation2.KaptioTravel__ExternalItemName__c = 'Accommodation';
            accommodation2.KaptioTravel__Price_Category__c = pc.Id;
            itineraryItemList.add(accommodation2);
    
            KaptioTravel__Itinerary_Item__c flight = newItineraryItem(itineraryId,  accountId);
            flight.KaptioTravel__Voucher_Reference_No__c = '123';
            flight.KaptioTravel__CustomerNotes__c = 'test';
            flight.KaptioTravel__Item__c = itemList.get(2).Id;
            flight.KaptioTravel__ExternalItemName__c = 'Flight Placeholder';
            flight.KaptioTravel__DateTo__c = System.today().addDays(1);
            itineraryItemList.add(flight);

    
            KaptioTravel__Itinerary_Item__c rail = newItineraryItem(itineraryId,  accountId);
            rail.KaptioTravel__Voucher_Reference_No__c = '123';
            rail.KaptioTravel__CustomerNotes__c = 'test';
            rail.KaptioTravel__TrainStationStart__c = ServiceLocationJunction.Id;
            rail.KaptioTravel__TrainStationEnd__c = ServiceLocationJunction.Id;
            rail.KaptioTravel__Item__c = itemList.get(3).Id;
            rail.KaptioTravel__ExternalItemName__c = 'Rail';
            itineraryItemList.add(rail);
    
            KaptioTravel__Itinerary_Item__c cruise = newItineraryItem(itineraryId,  accountId);
            cruise.KaptioTravel__Voucher_Reference_No__c = '123';
            cruise.KaptioTravel__CustomerNotes__c = 'test';
            cruise.KaptioTravel__Item__c = itemList.get(4).Id;
            cruise.KaptioTravel__ExternalItemName__c = 'Cruise';
            cruise.KaptioTravel__DateTo__c = System.today().addDays(END_DAY);
            cruise.KaptioTravel__ServiceDeparture__c = serviceDeparture.Id;
            itineraryItemList.add(cruise);
    
            KaptioTravel__Itinerary_Item__c transfer = newItineraryItem(itineraryId,  accountId);
            transfer.KaptioTravel__Voucher_Reference_No__c = '123';
            transfer.KaptioTravel__CustomerNotes__c = 'test';
            transfer.KaptioTravel__Item__c = itemList.get(5).Id;
            transfer.KaptioTravel__ExternalItemName__c = 'Transfer';
            itineraryItemList.add(transfer);
    

            KaptioTravel__Itinerary_Item__c PNRflight = newItineraryItem(itineraryId,  accountId);
            PNRflight.KaptioTravel__Voucher_Reference_No__c = '123';
            PNRflight.KaptioTravel__CustomerNotes__c = 'test';
            PNRflight.KaptioTravel__Item__c = itemList.get(6).Id;
            PNRflight.KaptioTravel__ExternalItemName__c = 'PNR Flight';
            PNRflight.KaptioTravel__DateTo__c = System.today().addDays(1);
            itineraryItemList.add(PNRflight);

            insert itineraryItemList;
    

            KaptioTravel__ItineraryService__c itineraryService = new KaptioTravel__ItineraryService__c(
                KaptioTravel__ItineraryItem__c = itineraryItemList.get(0).Id
            );
            insert itineraryService;



            KaptioTravel__Passenger__c passenger = new KaptioTravel__Passenger__c(
                KaptioTravel__Itinerary__c = itineraryId,
                KaptioTravel__FirstName__c = 'Sam',
                KaptioTravel__LastName__c = 'Traveller' 
            );
            Database.insert(passenger);

            List<KaptioTravel__PassengerItineraryUnitAssignment__c> passengerAssignmentList = new List<KaptioTravel__PassengerItineraryUnitAssignment__c>();
            KaptioTravel__PassengerItineraryUnitAssignment__c passengersAssignment1 = new KaptioTravel__PassengerItineraryUnitAssignment__c(
                KaptioTravel__ItineraryItem__c = itineraryItemList.get(0).Id,
                KaptioTravel__Passenger__c = passenger.Id,
                KaptioTravel__Unit__c = 1
            );
            passengerAssignmentList.add(passengersAssignment1);
            KaptioTravel__PassengerItineraryUnitAssignment__c passengersAssignment2 = new KaptioTravel__PassengerItineraryUnitAssignment__c(
                KaptioTravel__ItineraryItem__c = itineraryItemList.get(0).Id,
                KaptioTravel__Passenger__c = passenger.Id,
                KaptioTravel__Unit__c = 1
            );
            passengerAssignmentList.add(passengersAssignment2);
            insert passengerAssignmentList;
    
            List<KaptioTravel__ItineraryFlightLeg__c> flightLegList = new List<KaptioTravel__ItineraryFlightLeg__c>();
            KaptioTravel__ItineraryFlightLeg__c flightLeg1 = new KaptioTravel__ItineraryFlightLeg__c(
                KaptioTravel__DepartureDate__c = date.today(),
                KaptioTravel__Airline__c = accountId,
                KaptioTravel__OperatedBy__c = airlineId,
                KaptioTravel__DepartureTime__c = '14:00',
                KaptioTravel__ArrivalTime__c = '18:00',
                KaptioTravel__ArrivalDate__c = date.today().addDays(START_DAY),
                KaptioTravel__ItineraryItem__c = itineraryItemList.get(2).Id,
                KaptioTravel__FlightNumber__c = '123'
            );
            flightLegList.add(flightLeg1);
            KaptioTravel__ItineraryFlightLeg__c flightLeg2 = new KaptioTravel__ItineraryFlightLeg__c(
                KaptioTravel__DepartureDate__c = date.today(),
                KaptioTravel__Airline__c = accountId,
                KaptioTravel__OperatedBy__c = airlineId,
                KaptioTravel__DepartureTime__c = '20:00',
                KaptioTravel__ArrivalTime__c = '23:00',
                KaptioTravel__ArrivalDate__c = date.today().addDays(START_DAY) + 1,
                KaptioTravel__ItineraryItem__c = itineraryItemList.get(2).Id,
                KaptioTravel__FlightNumber__c = '122'
            );
            flightLegList.add(flightLeg2);
            insert flightLegList;


            KaptioTravel__Addon__c addon = new KaptioTravel__Addon__c(
                KaptioTravel__Item__c = itemList.get(6).Id,
                KaptioTravel__Allocation__c = 'booking',
                KaptioTravel__UOM__c = 'Unit(s)'
            );
            insert addon;

            

            KaptioTravel__Price_Category__c priceCat = new KaptioTravel__Price_Category__c(
                Name = 'Test',
                KaptioTravel__Item__c = itemList.get(6).Id,
                KaptioTravel__MaxPeople__c = 2,
                KaptioTravel__MaxAdults__c = 2,
                KaptioTravel__MaxChildren__c = 0,
                KaptioTravel__MaxInfants__c = 0);
             Database.insert(priceCat);

            KaptioTravel__ConnectFlightSupplier__c cfs = new KaptioTravel__ConnectFlightSupplier__c(
                Name = 'Connect Flight Supplier'
            );
            insert cfs;

            KaptioTravel__ConnectFlightGateway__c cfg = new KaptioTravel__ConnectFlightGateway__c(
                Name = 'Connect Flight Gateway',
                KaptioTravel__InvoiceTo__c = accountId,
                KaptioTravel__IsActive__c = true,
                KaptioTravel__AddonId__c = addon.Id,
                KaptioTravel__FareId__c = priceCat.Id,
                KaptioTravel__ConnectFlightSupplier__c = cfs.Id
            );
            insert cfg;
            KaptioTravel__PNR__c pnr = new KaptioTravel__PNR__c(
                Name = 'My pnr',
                KaptioTravel__Itinerary__c = itineraryId,
                KaptioTravel__BusinessUnit__c = brand.Id,
                KaptioTravel__ConnectFlightGateway__c = cfg.Id
            );
            insert pnr;

            KaptioTravel__PNRFlightSegment__c PNRFlightSegment = new KaptioTravel__PNRFlightSegment__c(
                KaptioTravel__DepartureDate__c = date.today(),
                KaptioTravel__Airline__c = accountId,
                KaptioTravel__OperatedBy__c = airlineId,
                KaptioTravel__DepartureTime__c = Time.newInstance(20,0, 0, 0),
                KaptioTravel__ArrivalTime__c = Time.newInstance(23,0, 0, 0),
                KaptioTravel__ArrivalDate__c = date.today().addDays(START_DAY) + 1,
                KaptioTravel__ItineraryItem__c = itineraryItemList.get(6).Id,
                KaptioTravel__FlightNumber__c = '122' ,  
                KaptioTravel__DepartureTerminal__c = 'T2',
                KaptioTravel__ArrivalTerminal__c = 'T2',
                KaptioTravel__PNR__c = pnr.Id,
                KaptioTravel__ArrivalAirport__c = locationId,
                KaptioTravel__DepartureAirport__c = locationId,
                KaptioTravel__FlyingTime__c = '20:00'
            );
            insert PNRFlightSegment;

        }

 }

    public List<KaptioTravel__Content__c> addContent(String recordType, Integer noOfRecords){
        List<KaptioTravel__Content__c> results = new List<KaptioTravel__Content__c>();
        Integer i = 0;
        Map<String,Schema.RecordTypeInfo> RtMapByDevName = Schema.SObjectType.KaptioTravel__Content__c.getRecordTypeInfosByDeveloperName(); 
        while (i < noOfRecords) {
            KaptioTravel__Content__c c = new KaptioTravel__Content__c(
                Name = 'Content ' + (i+1),
                KaptioTravel__Body__c = '',
                recordTypeId = RtMapByDevName.get(recordType).getRecordTypeId(),
                KaptioTravel__Title__c = 'Content Title ' + (i+1),
                KaptioTravel__StageTypeCategories__c = 'Quote',
                KaptioTravel__Language__c = language.Id
            );
            results.add( c );
            i++;
        }

        if(!results.isEmpty()){

            insert results;
        }

        return results;
    }

    

    /**
  * @description retrieves itinerary for itinerary content json
  * @param itinId - id of itinerary
  * @return List<KaptioTravel__Itinerary__c>
  */
    public static KaptioTravel__Itinerary__c getItinerary(Id itinId) {
        return [SELECT KaptioTravel__Start_Date__c,
            KaptioTravel__End_Date__c,
            KaptioTravel__Channel__c,
            KaptioTravel__CurrencyFactor__c,
            CurrencyIsoCode,
            OwnerId,
            KaptioTravel__Account__c,
            KaptioTravel__Primary_Contact__c,
            KaptioTravel__Group_Size__c,
            KaptioTravel__Trip__c,
            RecordTypeId,
            KaptioTravel__TotalAmountNet__c,
        (SELECT Id, KaptioTravel__Amount__c, KaptioTravel__Itinerary__c, KaptioTravel__DateDue__c, KaptioTravel__DateType__c,
            KaptioTravel__Description__c, KaptioTravel__ExternalName__c, KaptioTravel__Status__c, KaptioTravel__Type__c
        FROM Kaptiotravel__Payment_Schedules__r)

        FROM KaptioTravel__Itinerary__c
        WHERE Id = :itinId
        LIMIT 1
        ];
    }
}