/**
 * @description       :
 * @author            : Kaptio Developer
 * @group             :
 * @last modified on  : 11-13-2023
 * @last modified by  : Kaptio Developer
 **/

public with sharing class KTD_DocumentHelper {
  /**
   * @description - Get Kaptio App Settings
   * @author Kaptio Developer | 01-11-2022
   * @return KaptioTravel__AppSettings__c
   **/
  public static KaptioTravel__AppSettings__c getKaptioSettings() {
    return KaptioTravel__AppSettings__c.getOrgDefaults();
  }

  /**
   * @description - Get Kaptio Document Settings
   * @author Kaptio Developer | 01-11-2022
   * @param String p_ChannelCode
   * @return KaptioDocumentSetting__mdt
   **/
  public static KaptioDocumentSetting__mdt getDocumentSettings(
    String p_ChannelCode
  ) {
    // Document Setting based on Channel
    KaptioDocumentSetting__mdt documentSetting;
    // Default Setting
    KaptioDocumentSetting__mdt defaultSetting;
    // Get Kaptio Settings
    List<KaptioDocumentSetting__mdt> settings = getDocumentSettings();

    for (KaptioDocumentSetting__mdt ds : settings) {
      // Extract Channels
      String channels = ds.Channels__c;
      // Default (Kaptio Document Setting
      if (ds.DeveloperName == 'Default') {
        defaultSetting = ds;
      }
      // Get Document Setting based on Channel
      if (String.isNotBlank(channels) && channels.contains(p_ChannelCode)) {
        documentSetting = ds;
      }
    }

    return documentSetting != null ? documentSetting : defaultSetting;
  }

  /**
   * @description - Get Content Banner
   * @author Kaptio Developer | 01-11-2022
   * @param KaptioTravel__ItineraryContent__c p_content
   * @return String
   **/
  public static String getContentBanner(
    KaptioTravel__ItineraryContent__c p_content
  ) {
    String banner = '';
    if (
      String.isNotBlank(
        p_content.KaptioTravel__BannerImage__r.KaptioTravel__S3_Url__c
      )
    ) {
      banner = p_content.KaptioTravel__BannerImage__r.KaptioTravel__S3_Url__c;
    } else {
      String resource = PageReference.forResource('KaptioDocuments').getUrl();
      if (resource != '') {
        resource = resource.subString(0, resource.indexOf('?'));
        banner = resource + '/images/defaults/KT_DefaultBannerQuote.jpeg';
      }
    }
    return banner;
  }

  /**
   * @description - Get Logo details
   * @author Kaptio Developer | 01-11-2022
   * @param KaptioDocumentSetting__mdt p_settings
   * @param String p_type
   * @return LogoDto
   **/
  public static LogoDto getContentLogo(
    KaptioDocumentSetting__mdt p_settings,
    String p_type
  ) {
    // Logo Width and Height Settings
    LogoDto logoSettings = new LogoDto();
    String resource = PageReference.forResource('KaptioDocuments').getUrl();
    resource = resource.contains('?')
      ? resource.subString(0, resource.indexOf('?'))
      : resource;

    if (p_type == 'web') {
      // Logo URL
      logoSettings.logoUrl = String.isBlank(p_settings.LogoURL__c)
        ? resource + '/images/defaults/ContentMainLogo.png'
        : p_settings.LogoURL__c;
      // Log Width
      logoSettings.logoWidth = p_settings.LogoWidth__c != null
        ? String.valueOf(p_settings.LogoWidth__c) + 'px'
        : 'Auto';
      // Log Height
      logoSettings.logoHeight = p_settings.LogoHeight__c != null
        ? String.valueOf(p_settings.LogoHeight__c) + 'px'
        : 'Auto';
    }

    if (p_type == 'pdf') {
      // Logo URL
      logoSettings.logoUrl = String.isBlank(p_settings.LogoURL__c)
        ? resource + '/images/defaults/ContentPDFLogo.png'
        : p_settings.LogoPDFURL__c;
      // Log Width
      logoSettings.logoWidth = p_settings.LogoPDFWidth__c != null
        ? String.valueOf(p_settings.LogoPDFWidth__c) + 'px'
        : 'Auto';
      // Log Height
      logoSettings.logoHeight = p_settings.LogoPDFHeight__c != null
        ? String.valueOf(p_settings.LogoPDFHeight__c) + 'px'
        : 'Auto';
    }
    if (p_type == 'invoice') {
      // Logo URL
      logoSettings.logoUrl = String.isBlank(p_settings.LogoURL__c)
        ? resource + '/images/defaults/ContentPDFLogo.png'
        : p_settings.LogoInvoiceURL__c;
      // Log Width
      logoSettings.logoWidth = p_settings.LogoInvoiceWidth__c != null
        ? String.valueOf(p_settings.LogoInvoiceWidth__c) + 'px'
        : 'Auto';
      // Log Height
      logoSettings.logoHeight = p_settings.LogoInvoiceHeight__c != null
        ? String.valueOf(p_settings.LogoInvoiceHeight__c) + 'px'
        : 'Auto';
    }

    return logoSettings;
  }

  /**
   * @description - Currency Symbol
   * @author Kaptio Developer | 01-11-2022
   * @param String currencyIsoCode
   * @return String
   **/
  public static String getCurrencySymbol(String currencyIsoCode) {
    Map<String, String> currencyCodeToSymbol = new Map<String, String>{
      //'CAD' => '$',
      'AUD' => '$',
      'USD' => '$',
      'EUR' => '€',
      'GBP' => '£',
      'JPY' => '¥',
      'KRW' => '₩',
      'CNY' => '元'
    };

    return currencyCodeToSymbol.containsKey(currencyIsoCode)
      ? currencyCodeToSymbol.get(currencyIsoCode)
      : currencyIsoCode;
  }

  public static string formatDateByString(Date p_date, String p_format) {
    String result = '';
    System.debug('p_date: ' + p_date);
    System.debug('p_format: ' + p_format);
    DateTime d = Date.newInstance(p_date.year(), p_date.month(), p_date.day());

    result = d.format(p_format);

    return result;
  }

  /**
   * @description - Date Format
   * @author Kaptio Developer | 01-11-2022
   * @param Set<String> p_masterLabels
   * @return Map<String, KaptioDocumentDateFormat__mdt>
   **/
  public static Map<String, KaptioDocumentDateFormat__mdt> getDateFormatByMasterLabel(
    Set<String> p_masterLabels
  ) {
    Map<String, KaptioDocumentDateFormat__mdt> dateFormatMap = new Map<String, KaptioDocumentDateFormat__mdt>();

    for (
      KaptioDocumentDateFormat__mdt dfs : getDocumentDateFormats(p_masterLabels)
    ) {
      dateFormatMap.put(dfs.MasterLabel, dfs);
    }

    return dateFormatMap;
  }

  /**
   * @description - Date Format by Channel
   * @author Kaptio Developer | 01-11-2022
   * @param String p_masterLabel
   * @param String p_channelName
   * @return String
   **/
  public static String getDateFormatByMasterLabel(
    String p_masterLabel,
    String p_channelCode
  ) {
    String dateFormat = '';
    // Default Setting
    KaptioDocumentDateFormat__mdt dateFormatSetting = new KaptioDocumentDateFormat__mdt();
    // Document Setting based on Channel
    KaptioDocumentDateFormat__mdt channelFormat = new KaptioDocumentDateFormat__mdt();

    for (
      KaptioDocumentDateFormat__mdt df : getDateFormatByMasterLabel(
          new Set<String>{ p_masterLabel }
        )
        .values()
    ) {
      if (String.isBlank(df.Channels__c)) {
        dateFormatSetting = df;
      }
      if (df.Channels__c.contains(p_channelCode)) {
        channelFormat = df;
      }
    }
    // Update Date Format Setting
    dateFormatSetting = channelFormat.Id != null
      ? channelFormat
      : dateFormatSetting;

    // Found one? Update Date Format and return
    if (dateFormatSetting.Id != null) {
      dateFormat = (p_channelCode == 'KTUK')
        ? dateFormatSetting.DateFirst__c
        : dateFormatSetting.MonthFirst__c;
    }

    return dateFormat;
  }

  /**
   * @description
   * @author Kaptio Developer | 01-11-2022
   * @return Map<String, String>
   **/
  public static Map<String, String> getIconByItemType() {
    return new Map<String, String>{
      'Location' => '/images/icons/place_outline.svg',
      'Accommodation' => '/images/icons/accom_outline.svg',
      'Excursion' => '/images/icons/tour_outline.svg',
      'Transfer' => '/images/icons/transfer_outline.svg',
      'Flight' => '/images/icons/plane_outline.svg',
      'FlightPlaceholder' => '/images/icons/plane_outline.svg',
      'PNRFlight' => '/images/icons/plane_outline.svg',
      'Car_Rental' => '/images/icons/car_outlines.svg',
      'Cruise' => '/images/icons/cruise_outline.svg',
      'Rail' => '/images/icons/rail.png',
      'Rail_PTP' => '/images/icons/rail.png',
      'Rail_Accommodation' => '/images/icons/rail.png',
      'MultidayRail' => '/images/icons/rail.png',
      'ManualRail' => '/images/icons/rail.png',
      'Activity' => '/images/icons/activity_outlines.svg',
      'MultiDayItem' => '/images/icons/calendar_outline.svg',
      'Package_Item' => '/images/icons/tour_outline.svg',
      'Restaurant' => '/images/icons/collapse_outlines.svg', //no icon
      'Extra' => '/images/icons/collapse_outlines.svg', //no icon
      'Misc' => '/images/icons/collapse_outlines.svg', //no icon
      'Custom Item' => '/images/icons/collapse_outlines.svg' //no icon
    };
  }

  /**
   * @description
   * @author Kaptio Developer | 01-11-2022
   * @return Map<String, String>
   **/
  public static Map<String, String> getIconByItemTypePDF() {
    return new Map<String, String>{
      'Accommodation' => '/images/icons/accommodation.png',
      'Excursion' => '/images/icons/activity.png',
      'Transfer' => '/images/icons/transfer.png',
      'Flight' => '/images/icons/flight.png',
      'FlightPlaceholder' => '/images/icons/flight.png',
      'PNRFlight' => '/images/icons/flight.png',
      'Car_Rental' => '/images/icons/car_rental.png',
      'Cruise' => '/images/icons/cruise.png',
      'Rail' => '/images/icons/rail.png',
      'Rail_PTP' => '/images/icons/rail.png',
      'Rail_Accommodation' => '/images/icons/rail.png',
      'MultidayRail' => '/images/icons/rail.png',
      'ManualRail' => '/images/icons/rail.png',
      'Activity' => '/images/icons/activity.png',
      'Package_Item' => '/images/icons/tour_outline.png',
      'MultiDayItem' => 'no icon',
      'Restaurant' => 'no icon', //no icon
      'Extra' => 'no icon', //no icon
      'Misc' => 'no icon', //no icon
      'Custom Item' => 'no icon' //no icon
    };
  }

  /**
   * @description
   * @author Kaptio Developer | 01-11-2022
   * @param Map<Id String> firstLocationMap
   * @param String recordType
   * @return Map<Id, Id>
   **/
  public static Map<Id, Id> getLocations(
    Map<Id, String> firstLocationMap,
    String recordType
  ) {
    KaptioTravel__AppSettings__c appSettings = KaptioTravel__AppSettings__c.getOrgDefaults();

    //get location record types
    List<String> recordTypeList = firstLocationMap.values();
    Set<String> recordTypeSet = new Set<String>();
    for (String s : recordTypeList) {
      if (s != null)
        recordTypeSet.add(s);
    }

    Map<Id, Id> returnMap = new Map<Id, Id>();
    if (recordTypeSet.size() != 0) {
      //get record type hierarchy from App Settings
      List<String> recordTypeHierarchy = new List<String>();
      recordTypeHierarchy = appSettings.KaptioTravel__LocationRecordTypeHierarchy__c.split(
        ','
      );

      //get the position of the lowest record type in the hierarchy
      Integer baseRecordTypePosition;
      for (Integer i = recordTypeHierarchy.size() - 1; i >= 0; i--) {
        if (recordTypeSet.contains(recordTypeHierarchy.get(i).trim()))
          baseRecordTypePosition = i;
      }

      //determine number of quries needed
      Integer hierarchyLevels = baseRecordTypePosition + 1;
      Integer noOfQueries = (hierarchyLevels / 4) + 1;

      //initialize parent to child map: used to link the first and last level in a queary loop,
      //in the situation where a second loop is needed
      Map<Id, Id> parentToChildMap = new Map<Id, Id>();
      Set<Id> locationSet = new Set<Id>();
      locationSet.addAll(firstLocationMap.keySet());
      for (Id i : locationSet)
        parentToChildMap.put(i, i);

      for (Integer i = 1; i <= noOfQueries; i++) {
        if (locationSet.size() != 0) {
          Set<Id> intermediateLocationSet = new Set<Id>();
          for (KaptioTravel__Location__c location : [
            SELECT
              Id,
              RecordType.DeveloperName,
              KaptioTravel__Location__c,
              KaptioTravel__Location__r.RecordType.DeveloperName,
              KaptioTravel__Location__r.KaptioTravel__Location__c,
              KaptioTravel__Location__r.KaptioTravel__Location__r.RecordType.DeveloperName,
              KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c,
              KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.RecordType.DeveloperName,
              KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c,
              KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.RecordType.DeveloperName
            FROM KaptioTravel__Location__c
            WHERE Id IN :locationSet
            WITH SECURITY_ENFORCED
          ]) {
            //find targeted location
            if (parentToChildMap.containsKey(location.Id)) {
              if (location.RecordType.DeveloperName == recordType)
                returnMap.put(parentToChildMap.get(location.Id), location.Id);
              else if (
                location.KaptioTravel__Location__r.RecordType.DeveloperName ==
                recordType
              )
                returnMap.put(
                  parentToChildMap.get(location.Id),
                  location.KaptioTravel__Location__c
                );
              else if (
                location.KaptioTravel__Location__r.KaptioTravel__Location__r.RecordType.DeveloperName ==
                recordType
              )
                returnMap.put(
                  parentToChildMap.get(location.Id),
                  location.KaptioTravel__Location__r.KaptioTravel__Location__c
                );
              else if (
                location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.RecordType.DeveloperName ==
                recordType
              )
                returnMap.put(
                  parentToChildMap.get(location.Id),
                  location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c
                );
              else if (
                location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.RecordType.DeveloperName ==
                recordType
              )
                returnMap.put(
                  parentToChildMap.get(location.Id),
                  location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c
                );
              else if (
                location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c !=
                null
              ) {
                intermediateLocationSet.add(
                  location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c
                );
                parentTochildMap.put(
                  location.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__r.KaptioTravel__Location__c,
                  parentToChildMap.get(location.Id)
                );
              }
              //if targeted location is not found in the hierarchy
              else {
                //special bhaviour for Transport Hub and Area: show parent
                if (location.RecordType.DeveloperName == 'Transport_Hub') {
                  if (location.KaptioTravel__Location__c != null) {
                    if (
                      location.KaptioTravel__Location__r.RecordType.DeveloperName ==
                      'Area'
                    ) {
                      if (
                        location.KaptioTravel__Location__r.KaptioTravel__Location__c !=
                        null
                      )
                        returnMap.put(
                          location.Id,
                          location.KaptioTravel__Location__r.KaptioTravel__Location__c
                        );
                    } else
                      returnMap.put(
                        location.Id,
                        location.KaptioTravel__Location__c
                      );
                  } else
                    returnMap.put(location.Id, location.Id);
                } else
                  returnMap.put(location.Id, location.Id);
              }
            }
          }

          locationSet.clear();
          locationSet.addAll(intermediateLocationSet);
        }
      }
    }

    return returnMap;
  }

  /**
   * @description
   * @author Kaptio Developer | 01-11-2022
   * @param KaptioTravel__Channel__c p_channel
   * @return Boolean
   **/
  public static Boolean isB2B(KaptioTravel__Channel__c p_channel) {
    if (p_channel.Id != null) {
      return p_channel.KaptioTravel__IsB2BChannel__c;
    }
    return false;
  }

  /**
   * @description
   * @author Kaptio Developer | 01-11-2022
   * @param KaptioTravel__Itinerary_Item__c flight
   * @return List<FlightLegDto>
   **/
  public static List<FlightLegDto> getFlightLegs(
    KaptioTravel__Itinerary_Item__c flight
  ) {
    List<FlightLegDto> flightlegDtoList = new List<FlightLegDto>();
    if (flight.KaptioTravel__RecordTypeName__c == 'FlightPlaceholder') {
      for (
        KaptioTravel__ItineraryFlightLeg__c flightLeg : flight.KaptioTravel__Itinerary_Flight_Legs__r
      )
        flightlegDtoList.add(new FlightLegDto(flightleg));
    } else if (flight.KaptioTravel__RecordTypeName__c == 'PNRFlight') {
      for (
        KaptioTravel__PNRFlightSegment__c flightLeg : flight.KaptioTravel__PNRFlightSegments__r
      ) {
        flightlegDtoList.add(new FlightLegDto(flightleg));
      }
    }
    return flightLegDtoList;
  }

  /**
   * @description - Query KaptioDocumentDateFormat__mdt
   * @author Kaptio Developer | 01-11-2022
   * @param Set<String> p_masterLabels
   * @return List<KaptioDocumentDateFormat__mdt>
   **/
  private static List<KaptioDocumentDateFormat__mdt> getDocumentDateFormats(
    Set<String> p_masterLabels
  ) {
    return [
      SELECT Id, MasterLabel, Channels__c, DateFirst__c, MonthFirst__c
      FROM KaptioDocumentDateFormat__mdt
      WHERE MasterLabel IN :p_masterLabels
      WITH SECURITY_ENFORCED
    ];
  }

  /**
   * @description - Query KaptioDocumentSetting__mdt
   * @author Kaptio Developer | 01-11-2022
   * @return List<KaptioDocumentSetting__mdt>
   **/
  private static List<KaptioDocumentSetting__mdt> getDocumentSettings() {
    return [
      SELECT
        DeveloperName,
        Channels__c,
        Instagram__c,
        Facebook__c,
        Twitter__c,
        PrivacyPolicy__c,
        TermsOfUse__c,
        ContactUs__c,
        WebsiteFeedback__c,
        LogoURL__c,
        LogoPDFURL__c,
        LogoInvoiceURL__c,
        DocumentType__c,
        LogoHeight__c,
        LogoWidth__c,
        LogoInvoiceHeight__c,
        LogoInvoiceWidth__c,
        LogoPDFHeight__c,
        LogoPDFWidth__c,
        NavigationType__c,
        Color100__c,
        Color200__c,
        Color300__c,
        Color400__c,
        Color500__c,
        Color600__c,
        Color700__c,
        Color800__c
      FROM KaptioDocumentSetting__mdt
      WITH SECURITY_ENFORCED
      ORDER BY ID DESC
    ];
  }

  public static Boolean hasColorScheme(KaptioDocumentSetting__mdt kds) {
    String result = '';
    result =
      kds.Color100__c +
      kds.Color200__c +
      kds.Color300__c +
      kds.Color400__c +
      kds.Color500__c +
      kds.Color600__c +
      kds.Color700__c +
      kds.Color800__c;
    result = result.trim();

    if (String.isEmpty(result)) {
      return false;
    }
    return true;
  }

  public static String getColorSchemeString(KaptioDocumentSetting__mdt kds) {
    String root = '';
    if (hasColorScheme(kds)) {
      root = ':root { ';
      ColorScheme colorScheme = new ColorScheme(kds);
      for (String color : colorScheme.color) {
        root += color;
      }
      root += ' }';
    }

    return root;
  }

  public static String removeDeniedTagsFromContent(String p_body) {
    if (String.isNotEmpty(p_body)) {
      return p_body.replaceAll(
          '<script\\b[^<]*(?:(?!<\\/script>)<[^<]*)*<\\/script>',
          ''
        )
        .replaceAll('</*(head|body|html|link|!DOCTYPE HTML)[^>]*>', '');
    }
    return p_body;
  }

  public with sharing class FlightLegDto implements Comparable {
    public String Id { get; set; }
    public String flightNumber { get; set; }
    public String departureAirportName { get; set; }
    public String arrivalAirportName { get; set; }
    public String airlineName { get; set; }
    public String operatedBy { get; set; }
    public String operatedByName { get; set; }
    public Date departureDate { get; set; }
    public String departureTime { get; set; }
    public Date arrivalDate { get; set; }
    public String arrivalTime { get; set; }
    public String travelClass { get; set; }
    public String pnr { get; set; }
    public String arrivalAirportRecordType { get; set; }
    public String arrivalAirport { get; set; }
    public String itineraryItem { get; set; }
    public String arrivalTerminal { get; set; }
    public String departureTerminal { get; set; }

    public FlightLegDto(KaptioTravel__ItineraryFlightleg__c flightleg) {
      this.Id = flightleg.Id;
      this.flightNumber = flightLeg.KaptioTravel__FlightNumber__c;
      this.departureAirportName = flightLeg.KaptioTravel__DepartureAirportName__c;
      this.arrivalAirportName = flightLeg.KaptioTravel__ArrivalAirportName__c;
      this.airlineName = flightLeg.KaptioTravel__Airline__r.Name;
      this.operatedBy = flightLeg.KaptioTravel__OperatedBy__c;
      this.operatedByName = flightLeg.KaptioTravel__OperatedBy__r.Name;
      this.departureDate = flightLeg.KaptioTravel__DepartureDate__c;
      this.departureTime = flightLeg.KaptioTravel__DepartureTime__c;
      this.arrivalDate = flightLeg.KaptioTravel__ArrivalDate__c;
      this.arrivalTime = flightLeg.KaptioTravel__ArrivalTime__c;
      this.travelClass = flightLeg.KaptioTravel__TravelClass__c;
      this.pnr = flightLeg.KaptioTravel__PNR__c;
      this.arrivalAirportRecordType = flightLeg.KaptioTravel__ArrivalAirport__r.RecordType.DeveloperName;
      this.arrivalAirport = flightLeg.KaptioTravel__ArrivalAirport__c;
      this.itineraryItem = flightLeg.KaptioTravel__ItineraryItem__c;
      this.arrivalTerminal = '';
      this.departureTerminal = '';
    }

    public FlightLegDto(KaptioTravel__PNRFlightSegment__c flightleg) {
      String departureTimeString, arrivalTimeString;
      if (flightLeg.KaptioTravel__DepartureTime__c != null)
        departureTimeString = String.valueOf(
            flightLeg.KaptioTravel__DepartureTime__c
          )
          .left(5);
      if (flightLeg.KaptioTravel__ArrivalTime__c != null)
        arrivalTimeString = String.valueOf(
            flightLeg.KaptioTravel__ArrivalTime__c
          )
          .left(5);

      this.Id = flightLeg.Id;
      this.flightNumber = flightLeg.KaptioTravel__FlightNumber__c;
      this.departureAirportName = flightLeg.KaptioTravel__DepartureAirport__r.Name;
      this.arrivalAirportName = flightLeg.KaptioTravel__ArrivalAirport__r.Name;
      this.airlineName = flightLeg.KaptioTravel__Airline__r.Name;
      this.operatedBy = flightLeg.KaptioTravel__OperatedBy__c;
      this.operatedByName = flightLeg.KaptioTravel__OperatedBy__r.Name;
      this.departureDate = flightLeg.KaptioTravel__DepartureDate__c;
      this.departureTime = departureTimeString;
      this.arrivalDate = flightLeg.KaptioTravel__ArrivalDate__c;
      this.arrivalTime = arrivalTimeString;
      this.travelClass = flightLeg.KaptioTravel__TravelClass__c;
      this.pnr = flightLeg.KaptioTravel__VendorLocator__c;
      this.arrivalAirportRecordType = flightLeg.KaptioTravel__ArrivalAirport__r.RecordType.DeveloperName;
      this.arrivalAirport = flightLeg.KaptioTravel__ArrivalAirport__c;
      this.itineraryItem = flightLeg.KaptioTravel__ItineraryItem__c;
      this.arrivalTerminal = flightLeg.KaptioTravel__ArrivalTerminal__c;
      this.departureTerminal = flightLeg.KaptioTravel__DepartureTerminal__c;
    }

    public Integer compareTo(Object compareTo) {
      FlightLegDto compareToEmp = (FlightLegDto) compareTo;
      if (departureDate == compareToEmp.departureDate) {
        if (departureTime == compareToEmp.departureTime)
          return 0;

        if (departureTime > compareToEmp.departureTime)
          return 1;

        return -1;
      }
      if (departureDate > compareToEmp.departureDate)
        return 1;

      return -1;
    }
  }

  public with sharing class LogoDto {
    public string logoUrl { get; set; }
    public string logoWidth { get; set; }
    public string logoHeight { get; set; }
  }

  public with sharing class ColorScheme {
    public List<String> color { get; set; }

    public ColorScheme(KaptioDocumentSetting__mdt kds) {
      color = new List<String>();

      for (Integer i = 1; i <= 8; i++) {
        String rootvalue = '--color-' + i + '00: ';
        String fieldname = 'Color' + i + '00__c';
        String fieldvalue = String.valueOf(kds.get(fieldname));

        fieldvalue = String.isNotBlank(fieldvalue)
          ? fieldvalue
          : this.getDefaultColor(i);

        color.add(rootvalue + fieldvalue + ';');
      }
    }

    public String getDefaultColor(Integer i) {
      switch on i {
        when 1 {
          return '#f3f6f6';
        }
        when 2 {
          return '#dae0e4';
        }
        when 3 {
          return '#646464';
        }
        when 4 {
          return '#056F82';
        }
        when 5 {
          return '#385450';
        }
        when 6 {
          return '#343434';
        }
        when 7 {
          return '#3c3c3c';
        }
        when 8 {
          return '#1d1d1d';
        }
      }

      return '';
    }
  }
}