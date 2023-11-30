/**
 * @description       : Custom Component for cancellation documents. Displays overview of refunds or outstanding amounts
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 11-23-2022
 * @last modified by  : Kaptio Developer
**/

global with sharing class KTD_ComponentCancellationController implements KaptioTravel.IComponentHandler{

    public KaptioTravel__Itinerary__c itinerary { get; private set; }
    private Id itineraryId { get; set; }
    public String currencySymbol { get; set; }
    public Decimal refundAmount { get; private set; }
    public Decimal refundAndCommissionAmount { get; private set; }
    public KaptioTravel__Passenger__c leadPassenger {get;set;}  
    public Boolean isB2B {get;set;}    
    global KTD_ComponentCancellationController(){
        
        if(ApexPages.currentPage() != null){
            this.itineraryId = ApexPages.currentPage().getParameters().get('id');
        
            if(Schema.KaptioTravel__Itinerary__c.SObjectType == this.itineraryId.getSobjectType()) {
                init(this.itineraryId);
            }
        }
    }

    public void init(Id p_id) {
        this.itineraryId = p_id;
    }

    /**
    * @description page action. Needed to translate labels. ALL labels which are used in apex should be here
     */
    public void pageAction() {
        
        this.itinerary = this.getItinerary();

        this.isB2B = KTD_DocumentHelper.isB2B( 
            new KaptioTravel__Channel__c( 
                Id = this.Itinerary.KaptioTravel__Channel__r.Id, 
                KaptioTravel__IsB2BChannel__c = this.Itinerary.KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c
                )
            );

        this.refundAmount = (this.itinerary.KaptioTravel__Outstanding__c < 0) ? (-1) * this.itinerary.KaptioTravel__Outstanding__c : this.itinerary.KaptioTravel__Outstanding__c;
        this.refundAndCommissionAmount = this.refundAmount - this.itinerary.KaptioTravel__ResellerCommissionTotal__c;

        this.currencySymbol = KTD_DocumentHelper.getCurrencySymbol(this.itinerary.CurrencyIsoCode);
        
        for (KaptioTravel__Passenger__c pax : itinerary.KaptioTravel__Passengers__r){
            if (pax.KaptioTravel__LeadPassenger__c){
                leadPassenger = pax;
                break;
            }
        }       
    }
    
    public String getBody() {
        PageReference pref = Page.KTD_ComponentCancellation;
        pref.getParameters().put('id', this.itineraryId);
        Blob content = System.Test.isRunningTest() ? Blob.valueOf('Test') : pref.getContent();

        return KTD_DocumentHelper.removeDeniedTagsFromContent(content.toString());
    }

    public Boolean isEmpty(){
        return false;
    }

	private KaptioTravel__Itinerary__c getItinerary(){
        return 
            [SELECT 
                Id, 
                Name,
                KaptioTravel__Transaction_Amount__c, 
                KaptioTravel__Outstanding__c, 
                KaptioTravel__FinalPaymentExpectedDate__c, 
                KaptioTravel__Channel__r.Id, 
                KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name, 
                KaptioTravel__Channel__r.KaptioTravel__IsB2BChannel__c,
                KaptioTravel__OriginalTotalPriceForCancelled__c, 
                KaptioTravel__Itinerary_Amount__c, 
                CurrencyIsoCode, 
                KaptioTravel__ResellerCommissionTotal__c,
                KaptioTravel__GrossInvoicing__c,
                KaptioTravel__Amount_Per_Person__c,
                KaptioTravel__ResellerCommissionTaxTotal__c, 
                KaptioTravel__TotalAmountNet__c, 
                (SELECT 
                    Id, 
                    KaptioTravel__Salutation__c, 
                    KaptioTravel__FirstName__c, 
                    KaptioTravel__LastName__c, 
                    KaptioTravel__LeadPassenger__c
                FROM
                    KaptioTravel__Passengers__r
                ORDER BY KaptioTravel__AllocationId__c ASC NULLS LAST, KaptioTravel__LeadPassenger__c DESC, KaptioTravel__FirstName__c ASC, KaptioTravel__LastName__c ASC)
            FROM 
                KaptioTravel__Itinerary__c
            WHERE 
                Id = :this.itineraryId
            WITH SECURITY_ENFORCED];
    }
}