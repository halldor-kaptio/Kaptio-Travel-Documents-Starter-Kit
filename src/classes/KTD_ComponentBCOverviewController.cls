/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 15-11-2022
 * @last modified by  : Kaptio Developer
**/

global with sharing class KTD_ComponentBCOverviewController implements KaptioTravel.IComponentHandler {

	public KaptioTravel__Itinerary__c itinerary { get; private set; }
	public String currencySymbol { get; private set; }
	public Decimal finalBalance { get; private set; }
	public Boolean hasBreakdownGroups { get; private set; }	
	public Boolean isB2B {get;set;}
	private Id itineraryId { get; set; }
    

    global KTD_ComponentBCOverviewController() {
		this.finalBalance = 0;

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

			this.itinerary = this.getItinerary();

            this.isB2B = KTD_DocumentHelper.isB2B( 
                new KaptioTravel__Channel__c( 
                    Id = this.Itinerary.KaptioTravel__Channel__r.Id, 
                    KaptioTravel__IsB2BChannel__c = this.Itinerary.KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c
                    )
                );           

	        for (KaptioTravel__PaymentSchedule__c sch : this.itinerary.KaptioTravel__Payment_Schedules__r) {
	        	if (sch.KaptioTravel__Type__c == 'FinalBalance') {
					if(this.finalBalance <= itinerary.KaptioTravel__Outstanding__c){
	        			this.finalBalance = sch.KaptioTravel__BalanceDue__c;
					} else {
						this.finalBalance = itinerary.KaptioTravel__Outstanding__c;
					}
	        	}
			}

			this.currencySymbol = KTD_DocumentHelper.getCurrencySymbol(this.itinerary.CurrencyIsoCode);	 
			hasBreakdownGroups = this.itinerary.KaptioTravel__ItinerarySubBreakdownGroups__r.size() > 0;


		} catch (Exception exc) {
			System.debug('KT_BCOverviewController ERROR: ' + exc.getMessage() + '; Stack Trace: ' + exc.getStackTraceString());
		}
    }

    public String getBody() {
        PageReference pref = Page.KTD_ComponentBCOverview;
        pref.getParameters().put('id', this.itineraryId);
        Blob content = System.Test.isRunningTest() ? Blob.valueOf('Test') : pref.getContent();

        return content.toString();
    }

    public Boolean isEmpty(){
        return false;
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
				KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name, 
				KaptioTravel__Channel__r.Id,
				KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c, 
				KaptioTravel__ResellerCommissionTotal__c, 
				KaptioTravel__ResellerCommissionTaxTotal__c,
				(SELECT 
					Id, 
					KaptioTravel__Salutation__c, 
					KaptioTravel__FirstName__c, 
					KaptioTravel__LastName__c, 
					KaptioTravel__MiddleName__c
				FROM 
					KaptioTravel__Passengers__r
				ORDER BY KaptioTravel__AllocationId__c ASC NULLS LAST, KaptioTravel__LeadPassenger__c DESC, KaptioTravel__FirstName__c ASC, KaptioTravel__LastName__c ASC),
				(SELECT 
					Id, 
					KaptioTravel__Amount__c, 
					KaptioTravel__DateDue__c, 
					KaptioTravel__Type__c, 
					KaptioTravel__BalanceDue__c
				FROM 
					KaptioTravel__Payment_Schedules__r),
				(SELECT 
					Id, 
					KaptioTravel__PassengerCount__c, 
					KaptioTravel__FinalPriceOverride__c, 
					KaptioTravel__ResellerCommissionTotal__c, 
					KaptioTravel__SellPriceTotalOverride__c, 
					Name, 
					KaptioTravel__IsOptional__c
				FROM 
					KaptioTravel__ItinerarySubBreakdownGroups__r
				WHERE 
					(KaptioTravel__SellPriceTotalOverride__c > 0)
				AND 
					KaptioTravel__IsOptional__c = false
				AND 
					KaptioTravel__PassengerCount__c > 0
				ORDER BY Name ASC)
			FROM 
				KaptioTravel__Itinerary__c
			WHERE 
				Id = :this.itineraryId
			WITH SECURITY_ENFORCED];
	}
}