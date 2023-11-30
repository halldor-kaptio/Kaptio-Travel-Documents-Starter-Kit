/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 15-11-2022
 * @last modified by  : Kaptio Developer
**/

public with sharing class KTD_DocumentInvoiceTemplateController {

    public String renderAs { get; private set; }
    public KaptioTravel__Itinerary__c itinerary {get;set;}
    public KTD_DocumentHelper.LogoDto logo { get; private set; }
    public KaptioDocumentSetting__mdt documentSetting { get; private set; }
    public String colorScheme { get; private set; }

    public KTD_DocumentInvoiceTemplateController() {
        renderAs = 'pdf';

        Id paramId = ApexPages.currentPage().getParameters().get('Id');
        if(ApexPages.currentPage().getParameters().get('renderAs')!= null){
            renderAs = ApexPages.currentPage().getParameters().get('renderAs');
        }

        Id itineraryId;
        if (String.isNotBlank(paramId) && Schema.KaptioTravel__Itinerary__c.SObjectType == paramId.getSobjectType()) {
            itineraryId = paramId;

        }  else if(String.isNotBlank(paramId) && Schema.KaptioTravel__ItineraryContent__c.SObjectType == paramId.getSobjectType()) {
            itineraryId = [SELECT KaptioTravel__Itinerary__c FROM KaptioTravel__ItineraryContent__c WHERE Id = :paramId WITH SECURITY_ENFORCED].KaptioTravel__Itinerary__c;
        }

        itinerary = [
            SELECT Id, KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c, KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name, KaptioTravel__Account__r.Name 
            FROM KaptioTravel__Itinerary__c
            WHERE Id = :itineraryId
            WITH SECURITY_ENFORCED
        ];

		String channelCode = this.itinerary.KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c;
		documentSetting = KTD_DocumentHelper.getDocumentSettings(channelCode);
		logo = KTD_DocumentHelper.getContentLogo(documentSetting,'invoice');
        colorScheme = KTD_DocumentHelper.getColorSchemeString(documentSetting);
    }
}