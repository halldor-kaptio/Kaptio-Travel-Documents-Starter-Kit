/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 15-11-2022
 * @last modified by  : Kaptio Developer
**/

global with sharing class KTD_ComponentPricingController  implements KaptioTravel.IComponentHandler {

    public Static KaptioTravel__Itinerary__c itinerary { get; set; }
    public String currencySymbol { get; set; }
    public String decimalPlacesString { get; set; }
    public List<KaptioTravel__ItinerarySubBreakdownGroup__c> breakdownGroups { get; set; }
    public List<KaptioTravel__ItinerarySubBreakdownGroup__c> optionalBreakdownGroups { get; set; }
    public Boolean showDeposit { get; set; }
    public Decimal daysBetweenTripStartAndCreation { get; set; }
    public Decimal depositPerPerson { get; set; }
    private Id itineraryId { get; set; }

    /**
    * @description - default constructor
    * @author Kaptio Developer | 09-11-2022 
    **/
    global KTD_ComponentPricingController(){
        breakdownGroups = new List<KaptioTravel__ItinerarySubBreakdownGroup__c>();
        optionalBreakdownGroups = new List<KaptioTravel__ItinerarySubBreakdownGroup__c>();

        if(ApexPages.CurrentPage() != null){
            this.itineraryId = ApexPages.CurrentPage().getParameters().get('id');

            if(Schema.KaptioTravel__Itinerary__c.SObjectType == this.itineraryId.getSobjectType()){
                init(this.itineraryId);
            }
        }
    }

    /**
    * @description - Build PDF/Page
    * @author Kaptio Developer | 09-11-2022 
    **/
    public void init(Id recordId){
        try {
            if(itinerary == null){
                // Set Itinerary Id
                this.itineraryId = recordId;
                // Get Itinerary
                itinerary = this.getItinerary();

                // Sort breakdowns into optional and non-optional
                for(KaptioTravel__ItinerarySubBreakdownGroup__c b: itinerary.KaptioTravel__ItinerarySubBreakdownGroups__r){
                    if(b.KaptioTravel__IsOptional__c){
                        this.optionalBreakdownGroups.add(b);
                    } else {
                        this.breakdownGroups.add(b);
                    }
                }

                // Get Currency Symbol
                this.currencySymbol = KTD_DocumentHelper.getCurrencySymbol(itinerary.CurrencyIsoCode);
                // Get Currency Type
                CurrencyType itineraryCurrencyType = this.getCurrencyType(itinerary.CurrencyIsoCode);

                // Number of Decimal places
                Integer decimalPlaces = itineraryCurrencyType != null ? itineraryCurrencyType.DecimalPlaces : 2;
                // Initalise decimalPlacesString
                decimalPlacesString = '.';
                // Set Decimal places 
                decimalPlacesString = decimalPlaces != null && decimalPlaces != 0 ? decimalPlacesString.rightPad((decimalPlaces + 1), '0') : '';

                // Group Size
                Decimal groupSize = itinerary.KaptioTravel__Group_Size__c != null ? itinerary.KaptioTravel__Group_Size__c : 0;
                // Days Between
                this.daysBetweenTripStartAndCreation = itinerary.CreatedDate.date().daysBetween(itinerary.KaptioTravel__Start_Date__c);

                // Deposit Information 
                // Deposit Amount 
                Decimal depositAmount = itinerary.KaptioTravel__DepositAmount__c != null ? itinerary.KaptioTravel__DepositAmount__c : 0;
                // Total Amount
                Decimal totalAmount = itinerary.KaptioTravel__Transaction_Amount__c != null ? itinerary.KaptioTravel__Transaction_Amount__c : 0;
                // Show Depost amount?
                this.showDeposit = depositAmount != 0 && totalAmount <= depositAmount ? true : false;

                if(showDeposit){
                    // Deposit per person
                    this.depositPerPerson = groupSize != 0 ? (depositAmount / groupSize) : 0;
                }
            }
        } catch (Exception exc) {
            System.debug('KTD_Pricing.page ERROR: ' + exc.getMessage() + '; Stack Trace: ' + exc.getStackTraceString());
        }
    }

    /**
    * @description - return page body
    * @author Kaptio Developer | 09-11-2022 
    * @return String 
    **/
    public String getBody(){
        PageReference pref = Page.KTD_ComponentPricing;
        pref.getParameters().put('id', itineraryId);
        Blob content = System.Test.isRunningTest() ? Blob.valueOf('Test') : pref.getContent();

        return content.toString();
    }

    public Boolean isEmpty(){
        return false;
    }

    /**
    * @description - query callout
    * @author Kaptio Developer | 09-11-2022 
    * @return KaptioTravel__Itinerary__c 
    **/
    private KaptioTravel__Itinerary__c getItinerary(){
        return 
            [SELECT 
                Id, 
                CurrencyIsoCode, 
                KaptioTravel__Amount_Per_Person__c, 
                KaptioTravel__Group_Size__c, 
                KaptioTravel__DepositAmount__c, 
                KaptioTravel__Itinerary_Amount__c, 
                KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name,
                KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c, 
                KaptioTravel__Primary_Contact__r.Account.BillingCountry,
                KaptioTravel__VersionNumber__c, 
                KaptioTravel__Channel__r.KaptioTravel__Brand__c, 
                KaptioTravel__Start_Date__c,
                KaptioTravel__Account__r.KaptioTravel__GrossInvoicing__c, 
                CreatedDate, 
                KaptioTravel__Transaction_Amount__c,
                KaptioTravel__Outstanding__c,
                KaptioTravel__ResellerCommissionTotal__c,
                (SELECT 
                    Id, 
                    KaptioTravel__RecordTypeName__c, 
                    KaptioTravel__FullExternalName__c, 
                    KaptioTravel__Total_Price__c, 
                    KaptioTravel__IsOptional__c,
                    KaptioTravel__FlightFromLocation__c, 
                    KaptioTravel__FlightFromLocation__r.RecordType.DeveloperName, 
                    KaptioTravel__FlightFromLocation__r.KaptioTravel__Location__c,
                    KaptioTravel__FlightToLocation__c, 
                    KaptioTravel__FlightToLocation__r.RecordType.DeveloperName, 
                    KaptioTravel__FlightToLocation__r.KaptioTravel__Location__c,
                    KaptioTravel__FlightBookingSource__c, 
                    KaptioTravel__DateFrom__c
                FROM 
                    KaptioTravel__Itinerary_Items__r
                WHERE 
                    KaptioTravel__Mode__c = 'Active'
                AND 
                    (KaptioTravel__IsOptional__c = true 
                    OR 
                    KaptioTravel__RecordTypeName__c = 'FlightPlaceholder' 
                    OR 
                    KaptioTravel__RecordTypeName__c = 'PNRFlight')),
                (SELECT 
                    Id, 
                    KaptioTravel__PassengerCount__c, 
                    KaptioTravel__IsOptional__c, 
                    KaptioTravel__FinalPriceOverride__c, 
                    KaptioTravel__SellPriceTotalOverride__c, 
                    Name 
                FROM 
                    KaptioTravel__ItinerarySubBreakdownGroups__r
                WHERE 
                    KaptioTravel__SellPriceTotalOverride__c > 0 
                AND 
                    KaptioTravel__PassengerCount__c > 0
                ORDER By Name ASC),
                (SELECT 
                    Id
                FROM 
                    KaptioTravel__Payment_Schedules__r
                WHERE 
                    KaptioTravel__Type__c = 'Deposit')
            FROM 
                KaptioTravel__Itinerary__c
            WHERE 
                Id = :this.itineraryId
            WITH SECURITY_ENFORCED];
    }

    /**
    * @description - query callout
    * @author Kaptio Developer | 09-11-2022 
    * @param String currencyIsoCode 
    * @return CurrencyType 
    **/
    private CurrencyType getCurrencyType(String currencyIsoCode){
        return 
            [SELECT 
                Id, 
                ISOCode, 
                ConversionRate, 
                DecimalPlaces, 
                IsActive 
            FROM 
                CurrencyType 
            WHERE 
                ISOCode = :currencyIsoCode
            AND 
                IsActive = true
            WITH SECURITY_ENFORCED];
    }
}