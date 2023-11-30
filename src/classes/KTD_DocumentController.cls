/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 15-11-2022
 * @last modified by  : Kaptio Developer
**/

public with sharing class KTD_DocumentController {
    public transient KaptioTravel.CustomerOutputDto output { get; private set; }

	public User agent { get; private set; }
	public KaptioTravel__Itinerary__c itinerary { get; private set; }
	public String currencySymbol { get; private set; }
	public Id documentId { get; private set; }
	public String paId { get; private set; }
	public String banner { get; private set; }
	public Map<String, String> iconByItemType { get; private set; }
	public KaptioDocumentSetting__mdt documentSetting { get; private set; }
	
	public String agendaHeaderDateFormat { get; private set; }
	public String agendaShortDateFormat { get; private set; }

	public KTD_DocumentController() {
		this.documentId = ApexPages.CurrentPage().getParameters().get('id');
		this.paId = ApexPages.CurrentPage().getParameters().get('paId');
		this.output = new KaptioTravel.CustomerOutputDto(documentId, false);
		this.iconByItemType = KTD_DocumentHelper.getIconByItemType();

		this.init();
	}

	private void init() {
		this.currencySymbol = KTD_DocumentHelper.getCurrencySymbol(this.output.itinerary.CurrencyIsoCode);

		this.agent = this.getUser();
		
		this.itinerary = this.getItinerary();
		
		String channelCode = this.itinerary.KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c;
		documentSetting = KTD_DocumentHelper.getDocumentSettings(channelCode);

		Map<String,KaptioDocumentDateFormat__mdt> dateFormatMap = KTD_DocumentHelper.getDateFormatByMasterLabel(new Set<String>{'LongMonthDayOfWeek', 'Numeric'});

		if(this.itinerary.KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name == 'KTUS'){
			this.agendaHeaderDateFormat = dateFormatMap.get('LongMonthDayOfWeek').MonthFirst__c;
			this.agendaShortDateFormat = dateFormatMap.get('Numeric').MonthFirst__c;
		} else {
			this.agendaHeaderDateFormat = dateFormatMap.get('LongMonthDayOfWeek').DateFirst__c;
			this.agendaShortDateFormat = dateFormatMap.get('Numeric').DateFirst__c;
		}		
    }

	private User getUser(){
		return 
			[SELECT 
				FirstName, 
				LastName, 
				Title, 
				Email, 
				Phone, 
				SmallPhotoUrl,
				 MediumPhotoUrl
			FROM 
				User 
			WHERE 
				Id = :this.output.user.Id 
			WITH SECURITY_ENFORCED
			LIMIT 1];
	}

	private KaptioTravel__Itinerary__c getItinerary(){
        return 
			[SELECT 
				Id, 
				Name, 
				KaptioTravel__VersionNumber__c, 
				KaptioTravel__Channel__r.KaptioTravel__Brand__r.Name, 
				KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c
			FROM 
				KaptioTravel__Itinerary__c
			WHERE 
				Id = :this.output.itinerary.Id
			WITH SECURITY_ENFORCED];
	}
}