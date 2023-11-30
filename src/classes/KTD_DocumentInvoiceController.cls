/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 15-11-2022
 * @last modified by  : Kaptio Developer
**/

public with sharing class KTD_DocumentInvoiceController {

    public transient KaptioTravel.CustomerOutputDto output { get; set; }
    public KaptioTravel__Itinerary__c itinerary { get; private set; }
    public KaptioTravel__Channel__c channel {get; set;}
    public KaptioTravel__ItineraryContent__c document {get; set;}
    public KaptioTravel__Passenger__c leadPassenger {get;set;}
    public Boolean isB2B {get;set;}
    public Boolean isPersonAccount {get;set;}
    public String documentHeading {get; set;}
    public String documentPublishedDate {get; set;}
    
    private Id paramId { get; set; }


    public KTD_DocumentInvoiceController() {
        this.paramId = ApexPages.currentPage().getParameters().get('Id');	

        this.output = new KaptioTravel.CustomerOutputDto(this.paramId, true);

        this.itinerary = this.getItinerary();

        this.isPersonAccount = this.Itinerary.KaptioTravel__Primary_Contact__r.IsPersonAccount;
        
        this.document = this.getItineraryContent();

        this.documentHeading = document.KaptioTravel__StageType__c;
        this.channel = this.output.channel;
        this.isB2B = KTD_DocumentHelper.isB2B(this.channel);
        
        Map<String,KaptioDocumentDateFormat__mdt> dateFormatMap = KTD_DocumentHelper.getDateFormatByMasterLabel(new Set<String>{'ShortMonth'});
        Date formatDate = this.document.KaptioTravel__PublishedDate__c != null ? this.document.KaptioTravel__PublishedDate__c : Date.today();
        this.documentPublishedDate = KTD_DocumentHelper.formatDateByString(formatDate,dateFormatMap.get('ShortMonth').DateFirst__c);

    }

    private KaptioTravel__Itinerary__c getItinerary(){
        return
            [SELECT 
                Id, 
                Name, 
                CurrencyIsoCode, 
                KaptioTravel__Name_on_booking__c, 
                KaptioTravel__VersionNumber__c, 
                Owner.Name, 
                KaptioTravel__Group_Size__c,
                KaptioTravel__Amount_Per_Person__c, 
                KaptioTravel__Itinerary_Amount__c, 
                KaptioTravel__Transaction_Amount__c, 
                KaptioTravel__Outstanding__c,
                KaptioTravel__FinalPaymentExpectedDate__c, 
                KaptioTravel__BookingNumber__c, 
                KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name,KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c, 
                KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c, 
                KaptioTravel__Primary_Contact__r.IsPersonAccount,
                KaptioTravel__Primary_Contact__r.Account.BillingAddress,
                KaptioTravel__Primary_Contact__r.Account.BillingCountry, 
                KaptioTravel__Primary_Contact__r.Account.BillingState, 
                KaptioTravel__Primary_Contact__r.Account.BillingCity, 
                KaptioTravel__Primary_Contact__r.Account.BillingPostalCode, 
                KaptioTravel__Primary_Contact__r.Account.BillingStreet, 
                KaptioTravel__Primary_Contact__r.MailingAddress, 
                KaptioTravel__Primary_Contact__r.MailingCountry, 
                KaptioTravel__Primary_Contact__r.MailingState, 
                KaptioTravel__Primary_Contact__r.MailingCity, 
                KaptioTravel__Primary_Contact__r.MailingPostalCode, 
                KaptioTravel__Primary_Contact__r.MailingStreet, 
                KaptioTravel__Primary_Contact__r.FirstName, 
                KaptioTravel__Primary_Contact__r.LastName,
                KaptioTravel__Account__r.Name, 
                KaptioTravel__Account__r.ShippingStreet, 
                KaptioTravel__Account__r.ShippingCity, 
                KaptioTravel__Account__r.ShippingState,
                KaptioTravel__Account__r.ShippingPostalCode, 
                KaptioTravel__Account__r.ShippingCountry, 
                KaptioTravel__GrossInvoicing__c,
                KaptioTravel__Primary_Contact__r.Account.ShippingAddress,
                (SELECT 
                    Id, 
                    KaptioTravel__FirstName__c, 
                    KaptioTravel__LastName__c 
                FROM 
                    KaptioTravel__Passengers__r 
                WHERE 
                    KaptioTravel__LeadPassenger__c = true LIMIT 1)
            FROM 
                KaptioTravel__Itinerary__c
            WHERE 
                Id = :this.output.itinerary.Id
            WITH SECURITY_ENFORCED];
    }

    private KaptioTravel__ItineraryContent__c getItineraryContent(){
        return
            [SELECT 
                Id, 
                Name, 
                KaptioTravel__PublishedDate__c, 
                KaptioTravel__StageType__c, 
                KaptioTravel__DocumentTypeCategory__c
            FROM 
                KaptioTravel__ItineraryContent__c
            WHERE 
                Id =: this.output.content.Id
            WITH SECURITY_ENFORCED
            LIMIT 1];
    }
}