/**
 * @description       :
 * @author            : Kaptio Developer
 * @group             :
 * @last modified on  : 15-11-2022
 * @last modified by  : Kaptio Developer
 **/

public with sharing class KTD_DocumentPDFController {
  public transient KaptioTravel.CustomerOutputDto output { get; set; }
  public String frontPageBanner { get; private set; }
  public KTD_DocumentHelper.LogoDto logo { get; private set; }
  public KaptioTravel__Itinerary__c itinerary { get; set; }
  public String brandColor { get; set; }
  public String renderAs { get; set; }
  public KaptioDocumentSetting__mdt documentSetting { get; private set; }
  public Id paramId { get; private set; }
  public String colorScheme { get; private set; }

  public KTD_DocumentPDFController() {
    this.paramId = ApexPages.currentPage().getParameters().get('Id');

    String renderParam = ApexPages.currentPage()
      .getParameters()
      .get('renderAs');
    this.renderAs = (String.isNotBlank(renderParam))
      ? String.valueOf(renderParam)
      : 'pdf';

    this.output = new KaptioTravel.CustomerOutputDto(this.paramId, true);

    //get banner
    this.frontPageBanner = '';
    this.frontPageBanner = KTD_DocumentHelper.getContentBanner(
      this.output.content
    );

    if (!this.frontPageBanner.contains('https://')) {
      this.frontPageBanner =
        KTD_DocumentHelper.getKaptioSettings()
          .KaptioTravel__CustomerFacingURL__c + this.frontPageBanner;
    }

    if (this.frontPageBanner != null) {
      this.frontPageBanner = this.frontPageBanner.replace('(', '\\(');
      this.frontPageBanner = this.frontPageBanner.replace(')', '\\)');
    }

    this.itinerary = [
      SELECT
        Id,
        KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c,
        KaptioTravel__Account__r.Name
      FROM KaptioTravel__Itinerary__c
      WHERE Id = :this.output.itinerary.Id
      WITH SECURITY_ENFORCED
    ];

    String channelCode = this.itinerary.KaptioTravel__Channel__r.KaptioTravel__ChannelCode__c;
    documentSetting = KTD_DocumentHelper.getDocumentSettings(channelCode);

    logo = KTD_DocumentHelper.getContentLogo(documentSetting, 'pdf');
    colorScheme = KTD_DocumentHelper.getColorSchemeString(documentSetting);
    this.brandColor = '#5a7672';
  }
}