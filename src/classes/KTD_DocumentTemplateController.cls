/**
 * @description       : 
 * @author            : Kaptio Developer
 * @group             : 
 * @last modified on  : 11-13-2023
 * @last modified by  : Kaptio Developer
**/
public virtual with sharing class KTD_DocumentTemplateController {
    public User agent { get; private set; }
	public KaptioTravel__Itinerary__c itinerary { get; private set; }
	public String documentTitle { get; private set; }
	public KTD_DocumentHelper.LogoDto logo { get; private set; }
    public String colorScheme { get; private set; }
	public String banner { get; set; }
	public KaptioDocumentSetting__mdt documentSetting { get; private set; }

	public Id paramId { get; private set; }

	public KTD_DocumentTemplateController() {
		
		this.paramId = ApexPages.CurrentPage().getParameters().get('id');
		if (String.isNotBlank(paramId)) {
			System.debug('=== param Id not blank: ' + this.paramId);
			this.init();
		}
	}

	private void init() {
		
		KaptioTravel__ItineraryContent__c content;
		Id itineraryId;

		if (Schema.KaptioTravel__Itinerary__c.SObjectType == paramId.getSobjectType()) {
			itineraryId = paramId;
            
        } else if(Schema.KaptioTravel__ItineraryContent__c.SObjectType == paramId.getSobjectType()) {
			content = this.getItineraryContent();
			itineraryId = content.KaptioTravel__Itinerary__c;
        }

        this.itinerary = this.getItinerary(itineraryId);        
		this.documentTitle = this.itinerary.Name;

		if (content != null){
            this.documentTitle += ' | ' + content.KaptioTravel__StageType__c;
			this.banner = KTD_DocumentHelper.getContentBanner(content);
		}
        
		if (this.banner != null){
			this.banner = this.banner.replace('(', '\\(');
			this.banner = this.banner.replace(')', '\\)');
		}
		

		String channelCode = this.itinerary.KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c;
		documentSetting = KTD_DocumentHelper.getDocumentSettings(channelCode);
        
        colorScheme = KTD_DocumentHelper.getColorSchemeString(documentSetting);
        
       logo = KTD_DocumentHelper.getContentLogo(documentSetting,'web');
		
		this.agent = this.getUser();
	}

	private KaptioTravel__ItineraryContent__c getItineraryContent(){
		return
			[SELECT 
				Id,
                Name,
				KaptioTravel__StageType__c, 
				KaptioTravel__Itinerary__c, 
				KaptioTravel__Itinerary__r.Name, 
				KaptioTravel__BannerImage__r.KaptioTravel__S3_Url__c
			FROM 
				KaptioTravel__ItineraryContent__c
			WHERE 
				Id = :this.paramId
			WITH SECURITY_ENFORCED];
	}

	private KaptioTravel__Itinerary__c getItinerary(Id itineraryId){
		return
			[SELECT 
				Id, 
				Name, 
				KaptioTravel__Start_Date__c, 
				KaptioTravel__VersionNumber__c, 
				CurrencyIsoCode, 
				KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c, 
				OwnerId	
			FROM 
				KaptioTravel__Itinerary__c
			WHERE 
				Id = :itineraryId
			WITH SECURITY_ENFORCED];
	}

	private User getUser(){
		return 
			[SELECT 
				FirstName, 
				LastName, 
				Title, 
				Email, 
				Phone, 
				SmallPhotoUrl 
			FROM 
				User 
			WHERE 
				Id = :this.itinerary.OwnerId 
			WITH SECURITY_ENFORCED
			LIMIT 1];
	}
}