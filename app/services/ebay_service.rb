# app/lib/ebay_service.rb
require 'net/http'

class EbayService
  APP_ID = ENV['EBAY_APP_ID']
  BASE_URL = "https://brickset.com/api/v2.asmx/"
  LEGO_COMPLETE_SET_CATEGORY_ID = 19006
  USED_CONDITION_ID = 3000
  NEW_CONDITION_ID = 1000

  def self.heartbeat condition="used", part_number="75192"
    condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
    uri = URI.parse("http://svcs.ebay.com/services/search/FindingService/v1?
                      OPERATION-NAME=findCompletedItems&
                      SERVICE-VERSION=1.7.0&
                      SECURITY-APPNAME=#{APP_ID}&
                      RESPONSE-DATA-FORMAT=XML&
                      REST-PAYLOAD&
                      categoryId=#{LEGO_COMPLETE_SET_CATEGORY_ID}&
                      keywords=Lego+#{part_number}&
                      itemFilter(0).name=Condition&
                      itemFilter(0).value=#{condition}&
                      itemFilter(1).name=SoldItemsOnly&
                      itemFilter(1).value=true&
                      sortOrder=PricePlusShippingLowest&
                      paginationInput.entriesPerPage=100".gsub(/\s+/, ""))
    response = Net::HTTP.get_response(uri)
    sets = Hash.from_xml(response.body)
    puts sets.to_yaml
  end

  def self.get_completed_set_values_uri set_number, condition, page_number=1
    condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
    uri = URI.parse("http://svcs.ebay.com/services/search/FindingService/v1?
                      OPERATION-NAME=findCompletedItems&
                      SERVICE-VERSION=1.7.0&
                      SECURITY-APPNAME=#{APP_ID}&
                      RESPONSE-DATA-FORMAT=XML&
                      REST-PAYLOAD&
                      categoryId=#{LEGO_COMPLETE_SET_CATEGORY_ID}&
                      keywords=Lego+#{set_number}&
                      itemFilter(0).name=Condition&
                      itemFilter(0).value=#{condition}&
                      itemFilter(1).name=SoldItemsOnly&
                      itemFilter(1).value=true&
                      sortOrder=PricePlusShippingLowest&
                      paginationInput.entriesPerPage=100&
                      sortOrder=EndTimeSoonest&
                      paginationInput.pageNumber=#{page_number}".gsub(/\s+/, ""))
  end 

  def self.get_values_for_set s
    set_number = s.number_variant.to_i == 1 ? s.number : "#{s.number}-#{s.number_variant}"
    ebay_values = {}

    # Complete Set, Completed Listing Values
    completed_listing_values = get_completed_listing_values_for_set(set_number)
    ebay_values = ebay_values.merge(completed_listing_values)

    ebay_values
  end

  def self.recursively_get_completed_items_paginated_search_results set_number, condition, page_number=1, sold_within=1.week.ago
    uri = get_completed_set_values_uri(set_number, condition, page_number)
    response = Net::HTTP.get_response(uri)
    search_results = Hash.from_xml(response.body)['findCompletedItemsResponse']
    result_items = search_results['searchResult']['item'].select{ |l| l['listingInfo']['endTime'] >= sold_within }

    if result_items.empty? || result_items.last['listingInfo']['endTime'] < sold_within
      result_items # If the last of the results on this page is older than the sold_within range, bail out and return the items
    else
      pagination_data = search_results['paginationOutput']
      if pagination_data['pageNumber'] < pagination_data['totalPages']
        new_page = page_number + 1
        result_items + recursively_get_completed_items_paginated_search_results(set_number, condition, new_page)
      else
        result_items
      end
    end
  end

  def self.get_completed_listing_values_for_set set_number
    data = {}

    used_set_results = recursively_get_completed_items_paginated_search_results(set_number, "used")
    used_set_prices = used_set_results.map{ |s| s['sellingStatus']['currentPrice'].to_f }.sort
    used_set_time_on_market = used_set_results.map{ |s| TimeDifference.between(DateTime.parse(s['listingInfo']['endTime']), DateTime.parse(s['listingInfo']['startTime'])).in_days }.sort

    new_set_results = recursively_get_completed_items_paginated_search_results(set_number, "new")
    new_set_prices = new_set_results.map{ |s| s['sellingStatus']['currentPrice'].to_f }.sort
    new_set_time_on_market = new_set_results.map{ |s| TimeDifference.between(DateTime.parse(s['listingInfo']['endTime']), DateTime.parse(s['listingInfo']['startTime'])).in_days }.sort

    unless used_set_prices.empty?
      # TODO, discard high and low end?
      data[:complete_set_completed_listing_used_listings_count] = used_set_prices.count
      data[:complete_set_completed_listing_used_avg_price] = used_set_prices.mean.round(2)
      data[:complete_set_completed_listing_used_median_price] = used_set_prices.median.round(2)
      data[:complete_set_completed_listing_used_high_price] = used_set_prices.max
      data[:complete_set_completed_listing_used_low_price] = used_set_prices.min
      data[:complete_set_completed_listing_used_time_on_market_low] = used_set_time_on_market.min
      data[:complete_set_completed_listing_used_time_on_market_high] = used_set_time_on_market.max
      data[:complete_set_completed_listing_used_time_on_market_avg] = used_set_time_on_market.mean.round(1)
      data[:complete_set_completed_listing_used_time_on_market_median] = used_set_time_on_market.median.round(1)
    end

    unless new_set_prices.empty?
      # TODO, discard high and low end?
      data[:complete_set_completed_listing_new_listings_count] = new_set_prices.count
      data[:complete_set_completed_listing_new_avg_price] = new_set_prices.mean.round(2)
      data[:complete_set_completed_listing_new_median_price] = new_set_prices.median.round(2)
      data[:complete_set_completed_listing_new_high_price] = new_set_prices.max
      data[:complete_set_completed_listing_new_low_price] = new_set_prices.min
      data[:complete_set_completed_listing_new_time_on_market_low] = new_set_time_on_market.min
      data[:complete_set_completed_listing_new_time_on_market_high] = new_set_time_on_market.max
      data[:complete_set_completed_listing_new_time_on_market_avg] = new_set_time_on_market.mean.round(1)
      data[:complete_set_completed_listing_new_time_on_market_median] = new_set_time_on_market.median.round(1)
    end

    data
  end
end

# USED SETS RESPONSE
# findCompletedItemsResponse:
#   xmlns: http://www.ebay.com/marketplace/search/v1/services
#   ack: Success
#   version: 1.13.0
#   timestamp: '2018-01-13T01:19:51.511Z'
#   searchResult:
#     count: '35'
#     item:
#     - itemId: '202059104272'
#       title: LEGO Star Wars UCS Millennium Falcon 75192 VIP Poster & Brochure
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mqgdSN17vbeO8RX63rJUryQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-VIP-Poster-Brochure-/202059104272
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '30041'
#       location: Cumming,GA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '4.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '20.0'
#         convertedCurrentPrice: '20.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-09-19T01:03:20.000Z'
#         endTime: '2017-12-23T22:27:03.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162682488130'
#       title: Lego Star Wars UCS Millenium Falcon 75192 Poster MINT
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mT5SG97Plh6Ldu3jhJvkpTg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millenium-Falcon-75192-Poster-MINT-/162682488130
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '77040'
#       location: Houston,TX,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '28.0'
#         convertedCurrentPrice: '28.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-09-21T23:42:14.000Z'
#         endTime: '2017-12-10T05:44:21.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '332455557109'
#       title: LEGO Lot of 7 Star Wars & Super Heroe Sets, 2 Books, 75192 Brochure,
#         NO Minifigs
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mQytbieEKNJyqyGrDiJOVaQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Lot-7-Star-Wars-Super-Heroe-Sets-2-Books-75192-Brochure-NO-Minifigs-/332455557109
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '28607'
#       location: Boone,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '8.5'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '27.0'
#         convertedCurrentPrice: '27.0'
#         bidCount: '8'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-19T23:17:20.000Z'
#         endTime: '2017-11-26T23:17:20.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '8'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '292386647244'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mWuWWit1sxWnhPXRicKo7jQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-/292386647244
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '07760'
#       location: Rumson,NJ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '25.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '800.0'
#         convertedCurrentPrice: '800.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-28T03:15:01.000Z'
#         endTime: '2017-12-28T04:44:00.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182931603255'
#       title: LEGO Star Wars Millennium Falcon 75192 Ultimate Collectors Series UCS
#         NEW Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mg1B2pP5ov1Ocb-4mC37eMQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-Series-UCS-NEW-Sealed-/182931603255
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '85053'
#       location: Phoenix,AZ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '4'
#       sellingStatus:
#         currentPrice: '900.0'
#         convertedCurrentPrice: '900.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-28T05:46:21.000Z'
#         endTime: '2017-11-28T14:36:46.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122834319502'
#       title: Lego Stars Wars 75192 UCS Millennium Falcon Complete Set with Minifigs
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mpxolJFIjSJCYdZXDUBs26w/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Stars-Wars-75192-UCS-Millennium-Falcon-Complete-Set-Minifigs-/122834319502
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '60516'
#       location: Downers Grove,IL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '900.0'
#         convertedCurrentPrice: '900.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-29T02:43:08.000Z'
#         endTime: '2017-11-29T17:01:35.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182991825510'
#       title: Lego Star Wars Millennium Falcon UCS 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/m4FglumShpfIb80TOMopSFw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-UCS-75192-/182991825510
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '19807'
#       location: Wilmington,DE,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '900.0'
#         convertedCurrentPrice: '900.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-31T20:14:25.000Z'
#         endTime: '2018-01-01T18:17:02.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '142630492979'
#       title: LEGO Star Wars UCS Millennium Falcon 75192 Ultimate Collectors Series
#         - USED
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/ma0VkoRp4TtGIuFx6b-0RYA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-Ultimate-Collectors-Series-USED-/142630492979
#       productId: '70327387'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '60091'
#       location: Wilmette,IL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '910.0'
#         convertedCurrentPrice: '910.0'
#         bidCount: '7'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-19T21:22:54.000Z'
#         endTime: '2017-12-26T21:22:54.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '37'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '322961199270'
#       title: Lego Star Wars Millennium Falcon UCS 75192 FREE SHIPPING (+ 75085)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mb54XTzf_B2vUWcwJXK5TWg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-UCS-75192-FREE-SHIPPING-75085-/322961199270
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '20002'
#       location: Washington,District Of Columbia,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '940.0'
#         convertedCurrentPrice: '940.0'
#         bidCount: '20'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-26T20:45:29.000Z'
#         endTime: '2018-01-02T20:45:29.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '78'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162805573351'
#       title: 2017 LEGO Star Wars Millennium Falcon UCS 75192 *PREOWNED READY TO SHIP!*
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mCA0DmonTPCPPyiRj20pzJQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/2017-LEGO-Star-Wars-Millennium-Falcon-UCS-75192-PREOWNED-READY-SHIP-/162805573351
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '17046'
#       location: Lebanon,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '60.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '900.0'
#         convertedCurrentPrice: '900.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-15T12:51:04.000Z'
#         endTime: '2017-12-19T02:27:34.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182969416388'
#       title: LEGO Star Wars Ultimate Collector's Series Millennium Falcon 2017 (75192)
#         - Used
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mALwTM_hEYUiV-wIkmORUgg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Ultimate-Collectors-Series-Millennium-Falcon-2017-75192-Used-/182969416388
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '60051'
#       location: McHenry,IL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-17T23:23:35.000Z'
#         endTime: '2017-12-23T17:38:13.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '11'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122871935775'
#       title: 1st Edition Lego 10179 UCS Millennium Falcon Rare & Complete! 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mX-pcvr6C0rnZoRC4vxBoyA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/1st-Edition-Lego-10179-UCS-Millennium-Falcon-Rare-Complete-75192-/122871935775
#       productId: '70327387'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '89121'
#       location: Las Vegas,NV,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-21T02:52:22.000Z'
#         endTime: '2017-12-26T02:52:22.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '10'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152857503457'
#       title: LEGO STAR WARS UCS MILLENNIUM FALCON 75192 *IN HAND AND READY TO SHIP*
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/meKcsv-EPfJYbiUhlbCkXlA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-UCS-MILLENNIUM-FALCON-75192-IN-HAND-AND-READY-SHIP-/152857503457
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '52722'
#       location: Bettendorf,IA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         bidCount: '10'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-07T23:15:17.000Z'
#         endTime: '2018-01-12T23:15:17.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '56'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182895024451'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON- NO MINI FIGURES, PORGS, OR
#         MYNOCK
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mY-MVtilm-9-za_ItmzLhCw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-NO-MINI-FIGURES-PORGS-MYNOCK-/182895024451
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '28117'
#       location: Mooresville,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '75.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '949.99'
#         convertedCurrentPrice: '949.99'
#         bidCount: '39'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-13T01:03:42.000Z'
#         endTime: '2017-11-20T01:03:42.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '53'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '391910005488'
#       title: Lego Star Wars Millennium Falcon UCS 75192 FREE SHIPPING
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mnWJVKeRtBHkCFHA-FJdfTw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-UCS-75192-FREE-SHIPPING-/391910005488
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1025.0'
#         convertedCurrentPrice: '1025.0'
#         bidCount: '18'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-19T22:46:42.000Z'
#         endTime: '2017-10-29T22:46:42.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '88'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222718547165'
#       title: 2017 Lego Star Wars Millennium Falcon 75192 *BUILT ONCE  READY TO SHIP*
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mjVJ7_0baVtFj1y0hJhqRgA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/2017-Lego-Star-Wars-Millennium-Falcon-75192-BUILT-ONCE-READY-SHIP-/222718547165
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '75189'
#       location: Royse City,TX,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '140.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '900.0'
#         convertedCurrentPrice: '900.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-13T23:06:55.000Z'
#         endTime: '2017-11-17T15:38:13.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182840397004'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON- NO MINI FIGURES, PORGS, OR
#         MYNOCK
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mY-MVtilm-9-za_ItmzLhCw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-NO-MINI-FIGURES-PORGS-MYNOCK-/182840397004
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '28117'
#       location: Mooresville,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '50.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '995.0'
#         convertedCurrentPrice: '995.0'
#         bidCount: '31'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-19T01:05:22.000Z'
#         endTime: '2017-10-29T01:05:22.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '38'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272908159224'
#       title: Lego Star Wars Millennium Falcon UCS 75192 Pre-owned
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mdbdkRN1BPetTIGdFDkLxtg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-UCS-75192-Pre-owned-/272908159224
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '94546'
#       location: Castro Valley,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1050.0'
#         convertedCurrentPrice: '1050.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-30T19:42:02.000Z'
#         endTime: '2017-11-03T04:25:41.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '302538620830'
#       title: 'LEGO STAR WARS 75192 UCS MILLENNIUM FALCON ALL MINI FIGURES COMPLETE
#         SET '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mvuCuwlUbRM622OxCTUwCyg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-ALL-MINI-FIGURES-COMPLETE-SET-/302538620830
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '99026'
#       location: Nine Mile Falls,WA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1050.0'
#         convertedCurrentPrice: '1050.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-21T23:42:32.000Z'
#         endTime: '2017-11-23T18:40:23.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '122829031807'
#       title: 'LEGO® Star Wars Millennium Falcon UCS 75192 USED. IN HAND!! '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mOStjqO2mozzRtD6NScvveA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-UCS-75192-USED-HAND-/122829031807
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '60005'
#       location: Arlington Heights,IL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '100.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '950.0'
#         convertedCurrentPrice: '950.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-25T21:50:07.000Z'
#         endTime: '2017-11-27T14:22:57.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182864283731'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON- NO MINI FIGURES, PORGS, OR
#         MYNOCK
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mY-MVtilm-9-za_ItmzLhCw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-NO-MINI-FIGURES-PORGS-MYNOCK-/182864283731
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '28117'
#       location: Mooresville,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '50.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1025.0'
#         convertedCurrentPrice: '1025.0'
#         bidCount: '37'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-30T00:02:38.000Z'
#         endTime: '2017-11-09T00:02:38.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '35'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272933314039'
#       title: Lego Star Wars UCS Set 75192 Millennium Falcon *READY TO SHIP*
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m665n_coqzxwJiGwAuTUYbQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Set-75192-Millennium-Falcon-READY-SHIP-/272933314039
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '10025'
#       location: New York,NY,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '79.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '999.0'
#         convertedCurrentPrice: '999.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-14T20:16:51.000Z'
#         endTime: '2017-11-15T17:43:47.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152804849808'
#       title: 2017 LEGO Star Wars Millennium Falcon UCS 75192 *PREOWNED READY TO SHIP!*
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mtI25b0ZoObaecpRlzvVooA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/2017-LEGO-Star-Wars-Millennium-Falcon-UCS-75192-PREOWNED-READY-SHIP-/152804849808
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '22101'
#       location: McLean,VA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '70.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1029.0'
#         convertedCurrentPrice: '1029.0'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-27T14:59:01.000Z'
#         endTime: '2017-11-28T21:20:20.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '13'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '253165067877'
#       title: LEGO Star Wars Millennium Falcon 75192 UCS New Sealed Box in Hand Ready
#         to Ship
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mOZWQhHnz0kzSl0xmVxufdg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-UCS-New-Sealed-Box-Hand-Ready-Ship-/253165067877
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '03079'
#       location: Salem,NH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FlatDomesticCalculatedInternational
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1150.0'
#         convertedCurrentPrice: '1150.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-09-20T16:45:08.000Z'
#         endTime: '2017-11-30T16:07:43.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '162710709644'
#       title: 2017 Lego Star Wars Millennium Falcon 75192 *BUILT ONCE  READY TO SHIP*
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mYQ7H0_WRMoazuTuGSEKTQA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/2017-Lego-Star-Wars-Millennium-Falcon-75192-BUILT-ONCE-READY-SHIP-/162710709644
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '85286'
#       location: Chandler,AZ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '160.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '0'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-12T22:52:30.000Z'
#         endTime: '2017-10-29T16:16:25.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272921725808'
#       title: Lego Star Wars UCS Set Lot 75192 Millennium Falcon 75060 Boba Fett Slave
#         I 100%
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mhEcwEf0jqRN4G2kD7AHoEQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Set-Lot-75192-Millennium-Falcon-75060-Boba-Fett-Slave-100-/272921725808
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '10025'
#       location: New York,NY,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '120.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1075.0'
#         convertedCurrentPrice: '1075.0'
#         bidCount: '43'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-09T03:11:06.000Z'
#         endTime: '2017-11-14T03:11:06.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '59'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '253275025134'
#       title: 'Lego Black VIP Card #59 of 100 from 75192 Midnight Leicester Square
#         Launch'
#       globalId: EBAY-AU
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mWQFAjCs9az74sBlNLiMnKw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Black-VIP-Card-59-100-75192-Midnight-Leicester-Square-Launch-/253275025134
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '2155'
#       location: Australia
#       country: AU
#       shippingInfo:
#         shippingType: Calculated
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1500.0'
#         convertedCurrentPrice: '1181.03'
#         bidCount: '6'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-24T04:13:21.000Z'
#         endTime: '2017-11-27T04:13:21.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '11'
#       returnsAccepted: 'false'
#       galleryPlusPictureURL: http://galleryplus.ebayimg.com/ws/web/253275025134_1_0_1.jpg
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272907141527'
#       title: Lego Star Wars Millennium Falcon UCS 75192 Pre-owned
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mdbdkRN1BPetTIGdFDkLxtg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-UCS-75192-Pre-owned-/272907141527
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '94546'
#       location: Castro Valley,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1250.0'
#         convertedCurrentPrice: '1250.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-30T01:35:56.000Z'
#         endTime: '2017-10-30T09:17:35.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272907165608'
#       title: Lego Star Wars UCS Set Lot 75192 Millennium Falcon 75060 Boba Fett Slave
#         I 100%
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mhEcwEf0jqRN4G2kD7AHoEQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Set-Lot-75192-Millennium-Falcon-75060-Boba-Fett-Slave-100-/272907165608
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '10025'
#       location: New York,NY,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '120.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '4'
#       sellingStatus:
#         currentPrice: '1175.0'
#         convertedCurrentPrice: '1175.0'
#         bidCount: '28'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-30T02:06:52.000Z'
#         endTime: '2017-11-09T02:06:52.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '46'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '182817253866'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON- NO MINI FIGURES, PORGS, OR
#         MYNOCK
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mY-MVtilm-9-za_ItmzLhCw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-NO-MINI-FIGURES-PORGS-MYNOCK-/182817253866
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '28117'
#       location: Mooresville,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '50.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1275.0'
#         convertedCurrentPrice: '1275.0'
#         bidCount: '25'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-09T00:17:15.000Z'
#         endTime: '2017-10-19T00:17:15.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '38'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272947056927'
#       title: STAR WARS LEGO UCS DEATH STAR DOCKING BAY 327 MOC 10179 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m_HaM3mZu6lBvQ-HO8PEcUw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/STAR-WARS-LEGO-UCS-DEATH-STAR-DOCKING-BAY-327-MOC-10179-75192-/272947056927
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '80003'
#       location: Arvada,CO,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '2050.0'
#         convertedCurrentPrice: '2050.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-20T23:55:39.000Z'
#         endTime: '2018-01-08T20:48:54.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '38'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222679601889'
#       title: LEGO Star Wars Ultimate Collector's Millennium Falcon (10179) & (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mkg8lgV2RrbUaGWvTE7sBVw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Ultimate-Collectors-Millennium-Falcon-10179-75192-/222679601889
#       productId: '70327387'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '06078'
#       location: Suffield,CT,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '300.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1999.99'
#         convertedCurrentPrice: '1999.99'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-16T01:00:02.000Z'
#         endTime: '2017-10-23T01:00:02.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '8'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '292366259751'
#       title: Lego Stars Wars 75192 UCS Millennium Falcon 100% Complete Set w/ Box
#         & Minifigs
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m8MMoZsJLcw_0z02ydGLlqw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Stars-Wars-75192-UCS-Millennium-Falcon-100-Complete-Set-w-Box-Minifigs-/292366259751
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '94109'
#       location: San Francisco,CA,USA
#       country: US
#       shippingInfo:
#         shippingType: Calculated
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '0'
#       sellingStatus:
#         currentPrice: '910.0'
#         convertedCurrentPrice: '910.0'
#         bidCount: '11'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-11T02:19:22.000Z'
#         endTime: '2017-12-18T02:19:22.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '25'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '322870106267'
#       title: Lego 75192 Millenium Falcon
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m3jX19X6G1B_MSmB3evtfug/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-75192-Millenium-Falcon-/322870106267
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '80228'
#       location: Denver,CO,USA
#       country: US
#       shippingInfo:
#         shippingType: Calculated
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1100.0'
#         convertedCurrentPrice: '1100.0'
#         bidCount: '6'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-08T03:30:37.000Z'
#         endTime: '2017-11-15T03:30:37.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '11'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272948701985'
#       title: LEGO Star Wars Millennium Falcon 75192 Ultimate Collectors *IN HAND*
#         New
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mYRq-vowm4mEhFnIlRQ5OhA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-IN-HAND-New-/272948701985
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '98513'
#       location: Olympia,WA,USA
#       country: US
#       shippingInfo:
#         shippingType: Calculated
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1299.0'
#         convertedCurrentPrice: '1299.0'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-21T23:13:00.000Z'
#         endTime: '2017-11-24T23:13:00.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '3000'
#         conditionDisplayName: Used
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#   paginationOutput:
#     pageNumber: '1'
#     entriesPerPage: '100'
#     totalPages: '1'
#     totalEntries: '35'







# ##########################
# NEW SETS RESPONSE
# findCompletedItemsResponse:
#   xmlns: http://www.ebay.com/marketplace/search/v1/services
#   ack: Success
#   version: 1.13.0
#   timestamp: '2018-01-13T01:22:25.641Z'
#   searchResult:
#     count: '100'
#     item:
#     - itemId: '222705102514'
#       title: Lego Star Wars UCS Millenium Falcon 75192 Promo Brochure/Booklet
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mnWeMuUFDHyw7IozRdJ6-gA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millenium-Falcon-75192-Promo-Brochure-Booklet-/222705102514
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '44067'
#       location: Northfield,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '5.5'
#         convertedCurrentPrice: '5.5'
#         bidCount: '2'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-03T15:18:55.000Z'
#         endTime: '2017-11-08T15:18:55.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '172954634140'
#       title: LEGO Millenium Falcon 75192 Promo/Brochure booklet + BONUS!
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mwXESai7bshdYLIeoeXim4Q/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Millenium-Falcon-75192-Promo-Brochure-booklet-BONUS-/172954634140
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '55901'
#       location: Rochester,MN,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '2.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '7.0'
#         convertedCurrentPrice: '7.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-30T10:11:36.000Z'
#         endTime: '2017-11-16T13:56:14.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263278819394'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263278819394
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-24T13:57:06.000Z'
#         endTime: '2017-10-29T13:57:06.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '17'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263286196033'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263286196033
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-29T14:00:29.000Z'
#         endTime: '2017-11-01T14:00:29.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263298590032'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263298590032
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-04T20:01:12.000Z'
#         endTime: '2017-11-07T20:01:12.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263313912158'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263313912158
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-10T22:20:33.000Z'
#         endTime: '2017-11-13T22:20:33.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263322689183'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263322689183
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-14T14:18:56.000Z'
#         endTime: '2017-11-17T14:18:56.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263329601755'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263329601755
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-17T14:22:39.000Z'
#         endTime: '2017-11-20T14:22:39.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263334808826'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263334808826
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-20T14:34:13.000Z'
#         endTime: '2017-11-25T14:34:13.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263344312946'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263344312946
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-25T16:55:20.000Z'
#         endTime: '2017-11-28T16:55:20.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263375473152'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263375473152
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.49'
#         convertedCurrentPrice: '9.96'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-08T16:30:18.000Z'
#         endTime: '2017-12-11T16:30:18.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '172929787202'
#       title: LEGO Millenium Falcon Promo/Brochure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mwXESai7bshdYLIeoeXim4Q/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Millenium-Falcon-Promo-Brochure-75192-/172929787202
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '55901'
#       location: Rochester,MN,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '9.99'
#         convertedCurrentPrice: '9.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-16T12:49:58.000Z'
#         endTime: '2017-10-25T13:05:19.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263270534492'
#       title: INSTRUCTIONS to Build a Vertical Stand for LEGO 75192 UCS Millennium
#         Falcon
#       globalId: EBAY-ENCA
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mHIFHEh1w_XXO8V9fFHkonQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/INSTRUCTIONS-Build-Vertical-Stand-LEGO-75192-UCS-Millennium-Falcon-/263270534492
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: J1L1M2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.99'
#         convertedCurrentPrice: '10.36'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-19T13:51:39.000Z'
#         endTime: '2017-10-24T13:51:39.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '332406252635'
#       title: LEGO Star Wars UCS Millennium Falcon 75192 VIP Poster Day 3
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mlc7pyZvtjC5eXA7EHuEL3g/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-VIP-Poster-Day-3-/332406252635
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '02861'
#       location: Pawtucket,RI,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '4.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '7.18'
#         convertedCurrentPrice: '7.18'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-09T05:57:46.000Z'
#         endTime: '2017-10-16T05:57:46.000Z'
#         listingType: Auction
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '282669275812'
#       title: 'LEGO Star Wars UCS Millennium Falcon 75192 VIP Poster Day 3 - Force
#         Friday 2017 '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mivmRuuA0n7IlF2MJgwafsQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-VIP-Poster-Day-3-Force-Friday-2017-/282669275812
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '02347'
#       location: Lakeville,MA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '11.95'
#         convertedCurrentPrice: '11.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-09-25T21:35:51.000Z'
#         endTime: '2018-01-03T00:25:04.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '7'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '152773861411'
#       title: Lego Star Wars 75192 Ultimate Collector's UCS Millennium Falcon Brochure/Booklet
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mAphGQQofvfwv_0Vzzhi9wQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-75192-Ultimate-Collectors-UCS-Millennium-Falcon-Brochure-Booklet-/152773861411
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '27609'
#       location: Raleigh,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '12.5'
#         convertedCurrentPrice: '12.5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-04T19:38:07.000Z'
#         endTime: '2017-11-11T15:24:41.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '222748004457'
#       title: 'LEGO Star Wars UCS Millennium Falcon 75192 Promotion Poster #2 Force
#         Friday 2017'
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/m2dTjeolhyriGb5FOO2KNQg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-Promotion-Poster-2-Force-Friday-2017-/222748004457
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: L3R9J9
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '3.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '10.99'
#         convertedCurrentPrice: '10.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-08T12:29:34.000Z'
#         endTime: '2017-12-09T01:30:41.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '322929320575'
#       title: 'LEGO Star Wars UCS Millennium Falcon 75192 Promotion Poster #3 Force
#         Friday 2017'
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mqQb-7ARg6E8PNuLSTzoIuQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-Promotion-Poster-3-Force-Friday-2017-/322929320575
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: L3R9J9
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '3.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '10.99'
#         convertedCurrentPrice: '10.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-08T12:30:38.000Z'
#         endTime: '2017-12-24T15:27:11.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222680930335'
#       title: 'Legos Star Wars Force Friday Millenium Falcon UCS 75192 Promotional
#         Poster #2'
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mEpp-bFzkOunRW2DPE_KJ2A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Legos-Star-Wars-Force-Friday-Millenium-Falcon-UCS-75192-Promotional-Poster-2-/222680930335
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '08540'
#       location: Princeton,NJ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '3.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '12.99'
#         convertedCurrentPrice: '12.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-17T01:54:31.000Z'
#         endTime: '2017-10-17T23:34:42.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '312038623567'
#       title: LEGO 40298 Star Wars DJ Code Breaker Minifigure Polybag USA Seller In-hand
#         75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m5x9MPO_QOD33cAfpwmqWrw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-40298-Star-Wars-DJ-Code-Breaker-Minifigure-Polybag-USA-Seller-In-hand-75192-/312038623567
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '23456'
#       location: Virginia Beach,VA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '15.99'
#         convertedCurrentPrice: '15.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-04T11:26:50.000Z'
#         endTime: '2018-01-07T11:26:50.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '391959188534'
#       title: LEGO 40298 Star Wars DJ Code Breaker Minifigure Polybag USA Seller In-hand
#         75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mF25O1NhE0PSS5id1Y-Bb-w/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-40298-Star-Wars-DJ-Code-Breaker-Minifigure-Polybag-USA-Seller-In-hand-75192-/391959188534
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '95014'
#       location: Cupertino,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '16.0'
#         convertedCurrentPrice: '16.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-10T17:30:03.000Z'
#         endTime: '2018-01-11T00:49:54.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263292595732'
#       title: Lego Star Wars UCS Millennium Falcon Brochure *Lot Of 5*  75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mUWyPqG_6G8hu8iB0SsE5Jg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millennium-Falcon-Brochure-Lot-5-75192-/263292595732
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '19082'
#       location: Upper Darby,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '16.51'
#         convertedCurrentPrice: '16.51'
#         bidCount: '5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-02T03:06:47.000Z'
#         endTime: '2017-11-09T03:06:47.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '10'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '322873230548'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON BOOKLET-RARE-SIGNED LEICE
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/m-GPMxuFKMbajNRDa5yGfyw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-BOOKLET-RARE-SIGNED-LEICE-/322873230548
#       paymentMethod: PayPal
#       autoPay: 'true'
#       location: China
#       country: CN
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '16.87'
#         convertedCurrentPrice: '16.87'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-10T08:08:28.000Z'
#         endTime: '2017-11-12T10:52:52.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152783542951'
#       title: Lego Star Wars 75192 Ultimate Collector's UCS Millennium Falcon Brochure/Booklet
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mAphGQQofvfwv_0Vzzhi9wQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-75192-Ultimate-Collectors-UCS-Millennium-Falcon-Brochure-Booklet-/152783542951
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '27609'
#       location: Raleigh,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '16.99'
#         convertedCurrentPrice: '16.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-11T16:18:48.000Z'
#         endTime: '2017-11-19T04:59:34.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '152806407966'
#       title: Lego Star Wars 75192 Ultimate Collector's UCS Millennium Falcon Brochure/Booklet
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mAphGQQofvfwv_0Vzzhi9wQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-75192-Ultimate-Collectors-UCS-Millennium-Falcon-Brochure-Booklet-/152806407966
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '27609'
#       location: Raleigh,NC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '16.99'
#         convertedCurrentPrice: '16.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-28T18:16:44.000Z'
#         endTime: '2017-12-28T18:16:44.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '302582788456'
#       title: Lego Star Wars 75192 Ultimate Collector's UCS Millennium Falcon Brochure/Booklet
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mPbQoygiIwpowOsfW2Ugglw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-75192-Ultimate-Collectors-UCS-Millennium-Falcon-Brochure-Booklet-/302582788456
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '55068'
#       location: Rosemount,MN,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '3.95'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '13.99'
#         convertedCurrentPrice: '13.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-29T13:53:54.000Z'
#         endTime: '2018-01-05T18:05:49.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162833827954'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162833827954
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-03T14:39:59.000Z'
#         endTime: '2018-01-03T19:50:33.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162834251208'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162834251208
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-03T19:55:06.000Z'
#         endTime: '2018-01-03T23:35:37.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162834730606'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162834730606
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-04T01:22:51.000Z'
#         endTime: '2018-01-04T04:06:39.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162834896498'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162834896498
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-04T05:09:12.000Z'
#         endTime: '2018-01-04T08:45:16.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162835306549'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162835306549
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-04T12:31:38.000Z'
#         endTime: '2018-01-04T13:25:17.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162835398717'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162835398717
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-04T13:35:51.000Z'
#         endTime: '2018-01-05T03:29:36.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162837420861'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162837420861
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-05T18:50:08.000Z'
#         endTime: '2018-01-05T18:54:10.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162837438466'
#       title: Lego Star Wars Millennium Falcon Han Solo Minifigure 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-Han-Solo-Minifigure-75192-/162837438466
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '17.95'
#         convertedCurrentPrice: '17.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-05T19:02:21.000Z'
#         endTime: '2018-01-08T04:02:03.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '173043452279'
#       title: LEGO STAR WARS UCS MILLENNIUM FALCON 75192 PROMO BROCHURE BOOKLET
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mW70GwFNs3OO_O5sy-hE6dg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-UCS-MILLENNIUM-FALCON-75192-PROMO-BROCHURE-BOOKLET-/173043452279
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '93310'
#       location: France
#       country: FR
#       shippingInfo:
#         shippingServiceCost: '8.5'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '9.99'
#         convertedCurrentPrice: '9.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-21T01:41:35.000Z'
#         endTime: '2018-01-07T06:44:31.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '332453679077'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON BOOKLET-RARE-SIGNED LEICE
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/m-GPMxuFKMbajNRDa5yGfyw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-BOOKLET-RARE-SIGNED-LEICE-/332453679077
#       paymentMethod: PayPal
#       autoPay: 'true'
#       location: China
#       country: CN
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '19.78'
#         convertedCurrentPrice: '19.78'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-18T15:02:13.000Z'
#         endTime: '2017-11-19T00:23:22.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '253256054269'
#       title: Lego 75192 Millenium Falcon Pamphlet Brochure - FREE SHIPPING - Force
#         Friday
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mrNt-i4QGC_QQAR63IO-3ag/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-75192-Millenium-Falcon-Pamphlet-Brochure-FREE-SHIPPING-Force-Friday-/253256054269
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '32830'
#       location: Orlando,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '20.0'
#         convertedCurrentPrice: '20.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-12T23:33:41.000Z'
#         endTime: '2017-12-04T04:36:23.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263212536462'
#       title: Lego UCS Millennium Falcon 75192 Buildable Porg Figure, New & In Hand!
#         Free Ship
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mDIT5CwAjgJxp1BfcMBd1Pw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-UCS-Millennium-Falcon-75192-Buildable-Porg-Figure-New-Hand-Free-Ship-/263212536462
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '18042'
#       location: Easton,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '20.0'
#         convertedCurrentPrice: '20.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-09-17T10:03:00.000Z'
#         endTime: '2017-12-12T05:34:09.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '253200548277'
#       title: Lego Star Wars UCS Millennium Falcon Brochure *Lot Of 5*  75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/pict/2532005482774040_1.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millennium-Falcon-Brochure-Lot-5-75192-/253200548277
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '19082'
#       location: Upper Darby,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '20.57'
#         convertedCurrentPrice: '20.57'
#         bidCount: '7'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-10T03:36:27.000Z'
#         endTime: '2017-10-17T03:36:27.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '13'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '322800357615'
#       title: Lego Star Wars 75192 UCS Millennium Falcon Brochure New
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mrHgvM_oc3FFmYsTay0Bvxg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-75192-UCS-Millennium-Falcon-Brochure-New-/322800357615
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '29707'
#       location: Fort Mill,SC,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '3.5'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '20.0'
#         convertedCurrentPrice: '20.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-03T02:37:38.000Z'
#         endTime: '2017-12-23T02:43:20.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162826334493'
#       title: LEGO STAR WARS MINFIGURE MINFIG HAN SOLO MILLENNIUM FALCON 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-MINFIGURE-MINFIG-HAN-SOLO-MILLENNIUM-FALCON-75192-/162826334493
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '25.0'
#         convertedCurrentPrice: '25.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-29T16:22:15.000Z'
#         endTime: '2017-12-29T20:15:04.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162828504070'
#       title: LEGO STAR WARS MINFIGURE MINFIG HAN SOLO MILLENNIUM FALCON 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mG1zeCL58rbV2CRdRRlbsZA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-MINFIGURE-MINFIG-HAN-SOLO-MILLENNIUM-FALCON-75192-/162828504070
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '33021'
#       location: Hollywood,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '25.0'
#         convertedCurrentPrice: '25.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-30T23:40:35.000Z'
#         endTime: '2018-01-02T05:11:34.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263279596093'
#       title: Lego Star Wars UCS Millennium Falcon Brochure *Lot Of 5*  75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mUWyPqG_6G8hu8iB0SsE5Jg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millennium-Falcon-Brochure-Lot-5-75192-/263279596093
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '19082'
#       location: Upper Darby,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '26.0'
#         convertedCurrentPrice: '26.0'
#         bidCount: '10'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-25T02:39:14.000Z'
#         endTime: '2017-11-01T02:39:14.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '12'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '263266705189'
#       title: Lego Star Wars UCS Millennium Falcon Brochure *Lot Of 5*  75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mUWyPqG_6G8hu8iB0SsE5Jg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millennium-Falcon-Brochure-Lot-5-75192-/263266705189
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '19082'
#       location: Upper Darby,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '28.52'
#         convertedCurrentPrice: '28.52'
#         bidCount: '8'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-17T05:00:02.000Z'
#         endTime: '2017-10-24T05:00:02.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '12'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'true'
#     - itemId: '173073785919'
#       title: LEGO 40298 Star Wars DJ *Lot Of 2* Minifigure Polybag USA Seller In-hand
#         75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m-iW7o7AlDD533pY9itIE8Q/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-40298-Star-Wars-DJ-Lot-2-Minifigure-Polybag-USA-Seller-In-hand-75192-/173073785919
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '60614'
#       location: Chicago,IL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '28.95'
#         convertedCurrentPrice: '28.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-03T21:13:44.000Z'
#         endTime: '2018-01-10T21:02:15.000Z'
#         listingType: StoreInventory
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122797021417'
#       title: Lego Porg Figure UCS Millennium Falcon 75192, New, Ready to ship
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/m-dTJjErWVWrEs8oR0wth9g/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Porg-Figure-UCS-Millennium-Falcon-75192-New-Ready-ship-/122797021417
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '30553'
#       location: Lavonia,GA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '37.5'
#         convertedCurrentPrice: '37.5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-07T17:28:23.000Z'
#         endTime: '2017-11-15T12:46:04.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '112566891823'
#       title: LEGO UCS MILLENNIUM FALCON 75192 CLASSIC CREW C-3PO MINI FIG- NEW AND
#         IN-HAND
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m77iOEFFKftoQLEyWay_c4A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-UCS-MILLENNIUM-FALCON-75192-CLASSIC-CREW-C-3PO-MINI-FIG-NEW-AND-IN-HAND-/112566891823
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '18042'
#       location: Easton,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '42.0'
#         convertedCurrentPrice: '42.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-09-17T10:00:10.000Z'
#         endTime: '2017-11-28T21:28:07.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '302498522179'
#       title: Star Wars Lego - 7151 Sith Infiltrator Sealed Bags- NEW- From 1999!
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mOiTgwnPJT4orBD-7-fiKXQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Star-Wars-Lego-7151-Sith-Infiltrator-Sealed-Bags-NEW-1999-/302498522179
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '98668'
#       location: Vancouver,WA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '49.95'
#         convertedCurrentPrice: '49.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-23T14:47:20.000Z'
#         endTime: '2017-10-29T16:55:36.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '282697659662'
#       title: 'LEGO 75192 Millenium Falcon signed booklet '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mdfe0ImVgOpWGeIrSz2tX0Q/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-75192-Millenium-Falcon-signed-booklet-/282697659662
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: Norway
#       country: 'NO'
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '58.0'
#         convertedCurrentPrice: '58.0'
#         bidCount: '31'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-17T08:00:56.000Z'
#         endTime: '2017-10-22T08:00:56.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '11'
#       returnsAccepted: 'false'
#       galleryPlusPictureURL: http://galleryplus.ebayimg.com/ws/web/282697659662_1_0_1.jpg
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '172949920499'
#       title: Lego Star Wars UCS Millennium Falcon Brochure *Lot Of 25* Full Sealed
#         Pack 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/molvlQhacLcIDBmDvVV6oGA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millennium-Falcon-Brochure-Lot-25-Full-Sealed-Pack-75192-/172949920499
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '60614'
#       location: Chicago,IL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '78.0'
#         convertedCurrentPrice: '78.0'
#         bidCount: '9'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-27T02:31:58.000Z'
#         endTime: '2017-11-03T02:31:58.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '11'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '253296986272'
#       title: Lego 75192 Millennium Falcon Manual only  - NO LEGO PIECES
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/m87GgVWpohqsaKi4gCZ1qlw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-75192-Millennium-Falcon-Manual-only-NO-LEGO-PIECES-/253296986272
#       paymentMethod:
#       - CashOnPickup
#       - PayPal
#       autoPay: 'false'
#       postalCode: '07726'
#       location: Englishtown,NJ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '25.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '100.0'
#         convertedCurrentPrice: '100.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-06T01:35:55.000Z'
#         endTime: '2017-12-27T19:40:06.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '292345241599'
#       title: lego star wars millennium falcon 75192 instructions
#       globalId: EBAY-AU
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mE0KztDpDosaEEUOSF9_gcQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/lego-star-wars-millennium-falcon-75192-instructions-/292345241599
#       paymentMethod:
#       - CIPInCheckoutEnabled
#       - PayPal
#       - MoneyXferAccepted
#       autoPay: 'false'
#       postalCode: '2720'
#       location: Australia
#       country: AU
#       shippingInfo:
#         shippingServiceCost: '27.56'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '180.0'
#         convertedCurrentPrice: '141.72'
#         bidCount: '1'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-26T01:23:01.000Z'
#         endTime: '2017-12-02T13:23:02.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       galleryPlusPictureURL: http://galleryplus.ebayimg.com/ws/web/292345241599_1_0_1.jpg
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '173000256139'
#       title: LEGO STAR WARS 75192 UCS MILLENNIUM FALCON- NO MINI FIGURES, PORGS, OR
#         MYNOCK
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/maKeZLmAqKJtBUbuaMGJo4Q/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-75192-UCS-MILLENNIUM-FALCON-NO-MINI-FIGURES-PORGS-MYNOCK-/173000256139
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '02135'
#       location: Brighton,MA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '10.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '250.0'
#         convertedCurrentPrice: '250.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-26T17:19:47.000Z'
#         endTime: '2017-11-26T17:26:08.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122873650868'
#       title: NEW LEGO ULTIMATE COLLECTORS SERIES STAR WARS 10227 B-WING STARFIGHTER
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mgs8Q7ktZ4o1pw0zBZJGGcg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/NEW-LEGO-ULTIMATE-COLLECTORS-SERIES-STAR-WARS-10227-B-WING-STARFIGHTER-/122873650868
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '91331'
#       location: Pacoima,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '300.0'
#         convertedCurrentPrice: '300.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-21T22:05:55.000Z'
#         endTime: '2017-12-25T17:50:05.000Z'
#         listingType: StoreInventory
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222721614560'
#       title: Lego 75192 Star Wars Ultimate Collector's Millennium Falcon ✔️ FREE SHIPPING
#         ✔️
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mbsdcw6LIrsQ6pORJSAt7ww/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-75192-Star-Wars-Ultimate-Collectors-Millennium-Falcon-FREE-SHIPPING-/222721614560
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: China
#       country: CN
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '499.99'
#         convertedCurrentPrice: '499.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-16T11:50:18.000Z'
#         endTime: '2017-11-19T15:07:07.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '8'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222725621045'
#       title: Lego 75192 Star Wars Ultimate Collector's Millennium Falcon ✔️ FREE SHIPPING
#         ✔️
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mbsdcw6LIrsQ6pORJSAt7ww/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-75192-Star-Wars-Ultimate-Collectors-Millennium-Falcon-FREE-SHIPPING-/222725621045
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: China
#       country: CN
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '499.99'
#         convertedCurrentPrice: '499.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-19T18:44:39.000Z'
#         endTime: '2017-11-20T15:19:45.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '9'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '232553840735'
#       title: LEGO CLONE STAR WARS Millennium Falcon 75192 Ultimate Collectors Series
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/micWVA7d70PyYLeVvHA4D4Q/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-CLONE-STAR-WARS-Millennium-Falcon-75192-Ultimate-Collectors-Series-/232553840735
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '32136'
#       location: Flagler Beach,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '30.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '475.0'
#         convertedCurrentPrice: '475.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-07T20:43:29.000Z'
#         endTime: '2017-11-07T23:43:07.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272997394569'
#       title: Lego Millennium Falcon (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mopLE0LF6-MN1O4BaYSbkMw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Millennium-Falcon-75192-/272997394569
#       paymentMethod: PayPal
#       autoPay: 'true'
#       location: Morocco
#       country: MA
#       shippingInfo:
#         shippingServiceCost: '300.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '280.0'
#         convertedCurrentPrice: '280.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-27T02:14:25.000Z'
#         endTime: '2017-12-27T21:27:32.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '7'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '332503728612'
#       title: Star Wars Lego Millennium Falcon Figure Building Bricks 8445pcs 75192
#         Huge Scale
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mjdVJ2XorcGsQbbXnwuedlA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Star-Wars-Lego-Millennium-Falcon-Figure-Building-Bricks-8445pcs-75192-Huge-Scale-/332503728612
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '91350'
#       location: Hong Kong
#       country: HK
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '595.95'
#         convertedCurrentPrice: '595.95'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-31T04:48:05.000Z'
#         endTime: '2018-01-07T17:48:49.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '20'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122754729811'
#       title: LEGO Star Wars UCS Millennium Falcon (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mA_IPc-xgRicjikuPOs2SXg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-/122754729811
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: Morocco
#       country: MA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '750.0'
#         convertedCurrentPrice: '750.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-15T07:03:42.000Z'
#         endTime: '2017-10-15T08:31:12.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152827410325'
#       title: 'Lego-Millennium-Falcon-75192 '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mP73fjinF5dq5lymTWvg57A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Millennium-Falcon-75192-/152827410325
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: Hong Kong
#       country: HK
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '780.0'
#         convertedCurrentPrice: '780.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-14T09:46:29.000Z'
#         endTime: '2017-12-14T17:23:23.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '192395971591'
#       title: LEGO Millenium Falcon UCS 75192 (Custom Lego) (Please Read Product Description)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mYxWsKu7gBAyhM4QwbfwihA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Millenium-Falcon-UCS-75192-Custom-Lego-Please-Read-Product-Description-/192395971591
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '97317'
#       location: Salem,OR,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '799.99'
#         convertedCurrentPrice: '799.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-12T23:14:00.000Z'
#         endTime: '2017-12-13T23:33:10.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '192397082487'
#       title: LEGO Millenium Falcon UCS 75192 (Custom Lego) (Please Read Product Description)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mYxWsKu7gBAyhM4QwbfwihA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Millenium-Falcon-UCS-75192-Custom-Lego-Please-Read-Product-Description-/192397082487
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '97317'
#       location: Salem,OR,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '799.99'
#         convertedCurrentPrice: '799.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-14T00:48:34.000Z'
#         endTime: '2017-12-25T21:48:45.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '12'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122755552797'
#       title: LEGO Star Wars UCS Millennium Falcon (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mA_IPc-xgRicjikuPOs2SXg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millennium-Falcon-75192-/122755552797
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: Morocco
#       country: MA
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '800.0'
#         convertedCurrentPrice: '800.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-16T00:46:18.000Z'
#         endTime: '2017-10-16T01:06:38.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152825816127'
#       title: Lego Millennium Falcon (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mP73fjinF5dq5lymTWvg57A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Millennium-Falcon-75192-/152825816127
#       paymentMethod:
#       - PayPal
#       - VisaMC
#       - AmEx
#       - Discover
#       autoPay: 'false'
#       location: Hong Kong
#       country: HK
#       shippingInfo:
#         shippingServiceCost: '770.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '30.0'
#         convertedCurrentPrice: '30.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-13T07:21:56.000Z'
#         endTime: '2017-12-13T18:14:55.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152828530701'
#       title: Lego-Millennium-Falcon-75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mP73fjinF5dq5lymTWvg57A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Millennium-Falcon-75192-/152828530701
#       paymentMethod: PayPal
#       autoPay: 'false'
#       location: Hong Kong
#       country: HK
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '800.0'
#         convertedCurrentPrice: '800.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-15T07:22:19.000Z'
#         endTime: '2017-12-15T17:03:28.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272995648882'
#       title: Lego Millennium Falcon (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mP73fjinF5dq5lymTWvg57A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Millennium-Falcon-75192-/272995648882
#       paymentMethod: PayPal
#       autoPay: 'true'
#       location: Morocco
#       country: MA
#       shippingInfo:
#         shippingServiceCost: '600.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '200.0'
#         convertedCurrentPrice: '200.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-25T09:52:09.000Z'
#         endTime: '2017-12-25T12:14:43.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222758476994'
#       title: LEGO Star Wars Millennium Falcon 75192 Ultimate Collectors Series RARE
#         NIB
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mLuNJLvfV0_45VBx6TPBTfw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-Series-RARE-NIB-/222758476994
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '96819'
#       location: Honolulu,HI,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '920.0'
#         convertedCurrentPrice: '920.0'
#         bidCount: '10'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-16T18:34:48.000Z'
#         endTime: '2017-12-23T18:34:48.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '25'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152845947908'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192) SEALED BOX RARE HARD TO
#         FIND
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mFgkBEe0Zxn42ne-ViIYccw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-SEALED-BOX-RARE-HARD-FIND-/152845947908
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '44077'
#       location: Painesville,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '949.99'
#         convertedCurrentPrice: '949.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-29T13:47:04.000Z'
#         endTime: '2017-12-29T15:15:03.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152846927757'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192) SEALED BOX RARE HARD TO
#         FIND
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mFgkBEe0Zxn42ne-ViIYccw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-SEALED-BOX-RARE-HARD-FIND-/152846927757
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '44077'
#       location: Painesville,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '949.99'
#         convertedCurrentPrice: '949.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-30T10:06:34.000Z'
#         endTime: '2017-12-30T18:14:01.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '8'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152848888013'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192) SEALED BOX RARE HARD TO
#         FIND
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mFgkBEe0Zxn42ne-ViIYccw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-SEALED-BOX-RARE-HARD-FIND-/152848888013
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '44077'
#       location: Painesville,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '949.99'
#         convertedCurrentPrice: '949.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-01T08:13:42.000Z'
#         endTime: '2018-01-01T16:22:03.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '162809638317'
#       title: LEGOStar Wars Ultimate Collector Series Millennium Falcon 75192 New,
#         Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mGk-RznPAg_b6rIQv2HRNEw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGOStar-Wars-Ultimate-Collector-Series-Millennium-Falcon-75192-New-Sealed-/162809638317
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '07090'
#       location: Westfield,NJ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '951.0'
#         convertedCurrentPrice: '951.0'
#         bidCount: '5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-18T03:29:10.000Z'
#         endTime: '2017-12-25T03:29:10.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '19'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '232583270897'
#       title: LEGO SW Millennium Falcon 75192 Ultimate Collectors Series New Sealed
#         MIB $1095
#       globalId: EBAY-US
#       subtitle: Star Wars Lego Falcon SALE
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mC2bGNzmanXjobm31wqSZ3A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-SW-Millennium-Falcon-75192-Ultimate-Collectors-Series-New-Sealed-MIB-1095-/232583270897
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '77442'
#       location: Garwood,TX,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '73.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '895.0'
#         convertedCurrentPrice: '895.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-02T16:45:40.000Z'
#         endTime: '2017-12-02T19:32:52.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'true'
#       galleryPlusPictureURL: http://galleryplus.ebayimg.com/ws/web/232583270897_1_0_1.jpg
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '112695823990'
#       title: LEGO Star Wars Millennium Falcon 75192 Ultimate Collectors Series, New,
#         Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mgn0K219VrnqzPLxXzl2ydg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-Series-New-Sealed-/112695823990
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '01983'
#       location: Topsfield,MA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '970.0'
#         convertedCurrentPrice: '970.0'
#         bidCount: '2'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-17T16:20:27.000Z'
#         endTime: '2017-12-24T16:20:27.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '322961072497'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mviRhucpc9VQYrsaNpfOzLg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-/322961072497
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '95391'
#       location: Tracy,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '970.0'
#         convertedCurrentPrice: '970.0'
#         bidCount: '5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-26T19:09:45.000Z'
#         endTime: '2018-01-02T19:09:45.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '282803413615'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m3C1a32hdN5AeLsXtH_xE1g/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-/282803413615
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '33541'
#       location: Zephyrhills,FL,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '970.0'
#         convertedCurrentPrice: '970.0'
#         bidCount: '5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-09T19:58:17.000Z'
#         endTime: '2018-01-10T15:34:28.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '292302783341'
#       title: New LEGO Star Wars Millennium Falcon 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mbXD8nstf_tv2VWxpiMHnXQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/New-LEGO-Star-Wars-Millennium-Falcon-75192-/292302783341
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '98109'
#       location: Seattle,WA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '971.0'
#         convertedCurrentPrice: '971.0'
#         bidCount: '20'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-10-22T11:16:40.000Z'
#         endTime: '2017-10-23T10:33:57.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '19'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '282793181290'
#       title: Lego Star Wars UCS Millennium Falcon 75192 NEW Sealed - SHIPS SAME DAY
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mU_cGXIjKZRrd31JV8TXBxQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-UCS-Millennium-Falcon-75192-NEW-Sealed-SHIPS-SAME-DAY-/282793181290
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '91977'
#       location: Spring Valley,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '0'
#       sellingStatus:
#         currentPrice: '972.66'
#         convertedCurrentPrice: '972.66'
#         bidCount: '5'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-01T19:28:14.000Z'
#         endTime: '2018-01-02T19:28:14.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '14'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '263414195023'
#       title: LEGO MILLENNIUM FALCON 75192 ULTIMATE COLLECTOR SERIES NEW IN BOX READY
#         TO SHIP
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mltEYhA3L3eQzytN5HXULcQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-MILLENNIUM-FALCON-75192-ULTIMATE-COLLECTOR-SERIES-NEW-BOX-READY-SHIP-/263414195023
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '48073'
#       location: Royal Oak,MI,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '977.0'
#         convertedCurrentPrice: '977.0'
#         bidCount: '3'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-01T17:16:21.000Z'
#         endTime: '2018-01-08T17:16:21.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '4'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222776370782'
#       title: Lego Set 75192 Star Wars Millennium Falcon UCS NIB Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mLdyEj7WZrC8IrD_KRJvSgw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Set-75192-Star-Wars-Millennium-Falcon-UCS-NIB-Sealed-/222776370782
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '30028'
#       location: Cumming,GA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '990.0'
#         convertedCurrentPrice: '990.0'
#         bidCount: '2'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-31T12:23:35.000Z'
#         endTime: '2018-01-05T00:23:35.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '192422628894'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/m1xi6ztc4EqG8Hoq50bvFqQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-/192422628894
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '17013'
#       location: Carlisle,PA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '997.0'
#         convertedCurrentPrice: '997.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-09T17:08:59.000Z'
#         endTime: '2018-01-12T03:10:00.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '6'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152849323567'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192) SEALED BOX RARE HARD TO
#         FIND
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mFgkBEe0Zxn42ne-ViIYccw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-SEALED-BOX-RARE-HARD-FIND-/152849323567
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '44077'
#       location: Painesville,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '999.99'
#         convertedCurrentPrice: '999.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-01T16:39:51.000Z'
#         endTime: '2018-01-01T17:38:15.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152850012294'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192) SEALED BOX RARE HARD TO
#         FIND
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/mFgkBEe0Zxn42ne-ViIYccw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-SEALED-BOX-RARE-HARD-FIND-/152850012294
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '44077'
#       location: Painesville,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '5'
#       sellingStatus:
#         currentPrice: '999.99'
#         convertedCurrentPrice: '999.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-02T05:31:37.000Z'
#         endTime: '2018-01-02T17:34:15.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '5'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122888522469'
#       title: LEGO UCS Millennium Falcon 75192 Ultimate Collectors Edition PRE-ORDER
#         Free Ship
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mzr2imgQPR2o3Iov1deTZGw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-UCS-Millennium-Falcon-75192-Ultimate-Collectors-Edition-PRE-ORDER-Free-Ship-/122888522469
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '92782'
#       location: Tustin,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '999.99'
#         convertedCurrentPrice: '999.99'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-31T02:03:30.000Z'
#         endTime: '2018-01-10T03:37:41.000Z'
#         listingType: StoreInventory
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '272915712508'
#       title: LEGO Star Wars Millennium Falcon UCS 75192 - IN HAND! FREE SHIPPING
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mgtyJycHKeOzLZQq5sU07Zg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-UCS-75192-HAND-FREE-SHIPPING-/272915712508
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '46544'
#       location: Mishawaka,IN,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-05T13:08:26.000Z'
#         endTime: '2017-11-05T13:50:51.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '1'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '112687445844'
#       title: LEGO Star Wars Millennium Falcon 75192 Ultimate Collectors Series UCS
#         NEW Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mInvF4MWx-bN3VCSOVFTQCQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-Series-UCS-NEW-Sealed-/112687445844
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '94127'
#       location: San Francisco,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-12T20:09:38.000Z'
#         endTime: '2017-12-23T00:22:04.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '282779100353'
#       title: 'Brand New! Sealed! LEGO Star Wars Millennium Falcon 75192 Same Day Shipping! '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mWHLvRf-tIY_o2n_yyyoJ5A/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Brand-New-Sealed-LEGO-Star-Wars-Millennium-Falcon-75192-Same-Day-Shipping-/282779100353
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '30022'
#       location: Alpharetta,GA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         bidCount: '8'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-20T04:41:20.000Z'
#         endTime: '2017-12-23T04:41:20.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '18'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122875033863'
#       title: LEGO Star Wars Millennium Falcon 75192 Ultimate Collectors Series UCS
#         NEW Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/m06xh4n_ghTM7BJPCjxsTsA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-Series-UCS-NEW-Sealed-/122875033863
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '22042'
#       location: Falls Church,VA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-23T06:54:34.000Z'
#         endTime: '2017-12-23T11:14:11.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '273010105976'
#       title: Lego Star Wars Millennium Falcon 75192 Ultimate Collectors Brand New
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/m57UWKb2KHpkR3bCenKrgKw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millennium-Falcon-75192-Ultimate-Collectors-Brand-New-/273010105976
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '50323'
#       location: Urbandale,IA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-04T05:48:35.000Z'
#         endTime: '2018-01-04T16:02:15.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'true'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '322979453124'
#       title: LEGO Star Wars Millennium Falcon 2017 UCS (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mopLE0LF6-MN1O4BaYSbkMw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-UCS-75192-/322979453124
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '92126'
#       location: San Diego,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-05T01:17:51.000Z'
#         endTime: '2018-01-05T04:20:44.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222706895774'
#       title: star wars millennium falcon lego 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs3.ebaystatic.com/m/m4vRvE_aJ4zIJXW5VEgiYaw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/star-wars-millennium-falcon-lego-75192-/222706895774
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '85255'
#       location: Scottsdale,AZ,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '2'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2017-11-05T04:15:51.000Z'
#         endTime: '2018-01-07T02:53:32.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '3'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '152854032101'
#       title: Lego Star Wars Millenium Falcon Ultimate Collector Series UCS 75192 Free
#         Ship
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/ml2Q9GCIiwtrzHOc3itnFUQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-Millenium-Falcon-Ultimate-Collector-Series-UCS-75192-Free-Ship-/152854032101
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '94040'
#       location: Mountain View,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1000.0'
#         convertedCurrentPrice: '1000.0'
#         bidCount: '49'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-05T08:23:56.000Z'
#         endTime: '2018-01-12T08:23:56.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '56'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '222758791744'
#       title: LEGO Ultimate Collectors (UCS) Millennium Falcon Brand New Unopened 75192
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/mkR2ZNbpW6rsgM9yqCeByng/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Ultimate-Collectors-UCS-Millennium-Falcon-Brand-New-Unopened-75192-/222758791744
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '44115'
#       location: Cleveland,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '75.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '930.0'
#         convertedCurrentPrice: '930.0'
#         bidCount: '7'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-17T12:50:57.000Z'
#         endTime: '2017-12-20T00:50:54.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '21'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '282797485555'
#       title: LEGO Star Wars UCS Millenium Falcon 75192 Brand New. Sold out everywhere
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mFRLy4bxKlSFcbyG-pRrwiw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-UCS-Millenium-Falcon-75192-Brand-New-Sold-out-everywhere-/282797485555
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: '92630'
#       location: Lake Forest,CA,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '50.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '960.0'
#         convertedCurrentPrice: '960.0'
#         bidCount: '10'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-05T08:27:57.000Z'
#         endTime: '2018-01-11T20:27:57.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '27'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '173063615369'
#       title: LEGO Star Wars Ultimate Collector Series Millennium Falcon 2017 (75192)
#         - NIB
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mFiHIpYTSt4eucvPDflx3sg/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Ultimate-Collector-Series-Millennium-Falcon-2017-75192-NIB-/173063615369
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '80015'
#       location: Aurora,CO,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '49.95'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '965.0'
#         convertedCurrentPrice: '965.0'
#         bidCount: '2'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-30T03:06:52.000Z'
#         endTime: '2018-01-02T03:06:52.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '10'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '192423409385'
#       title: LEGO Star Wars Millennium Falcon 2017 (75192)
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mCfUxYxg5ONroj1uSK1fWgA/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Star-Wars-Millennium-Falcon-2017-75192-/192423409385
#       productId: '241203516'
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '40601'
#       location: Frankfort,KY,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '25.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '999.0'
#         convertedCurrentPrice: '999.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'true'
#         buyItNowAvailable: 'false'
#         startTime: '2018-01-10T12:47:42.000Z'
#         endTime: '2018-01-10T14:34:48.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#         watchCount: '2'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '112678764719'
#       title: LEGO STAR WARS Millennium Falcon 75192 Ultimate Collectors Series New
#         Sealed
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs4.ebaystatic.com/m/mZZYFSJHw_y0pihhcHF-QgQ/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-STAR-WARS-Millennium-Falcon-75192-Ultimate-Collectors-Series-New-Sealed-/112678764719
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '48197'
#       location: Ypsilanti,MI,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1025.0'
#         convertedCurrentPrice: '1025.0'
#         bidCount: '7'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-08T00:16:11.000Z'
#         endTime: '2017-12-13T00:16:11.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '17'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '173030006029'
#       title: LEGO Ultimate Collectors Series Millennium Falcon 75192 NEW and ready
#         for XMAS
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mh8VkzJSUoCq2yFPTIhccCw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/LEGO-Ultimate-Collectors-Series-Millennium-Falcon-75192-NEW-and-ready-XMAS-/173030006029
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '45162'
#       location: Pleasant Plain,OH,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: Free
#         shipToLocations: Worldwide
#         expeditedShipping: 'true'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '3'
#       sellingStatus:
#         currentPrice: '1025.0'
#         convertedCurrentPrice: '1025.0'
#         bidCount: '29'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-13T01:04:22.000Z'
#         endTime: '2017-12-16T01:04:22.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '39'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '112682613364'
#       title: Lego Star Wars 75192 UCS Millennium Falcon...THE must have set for the
#         Holidays!
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs1.ebaystatic.com/m/m1dDdH6VkLsxyJA9eP1wS7g/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Star-Wars-75192-UCS-Millennium-Falcon-THE-must-have-set-Holidays-/112682613364
#       paymentMethod: PayPal
#       autoPay: 'false'
#       postalCode: '80504'
#       location: Longmont,CO,USA
#       country: US
#       shippingInfo:
#         shippingServiceCost: '0.0'
#         shippingType: FreePickup
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '1025.0'
#         convertedCurrentPrice: '1025.0'
#         bidCount: '48'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-10T03:23:57.000Z'
#         endTime: '2017-12-17T03:23:57.000Z'
#         listingType: Auction
#         gift: 'false'
#         watchCount: '12'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#     - itemId: '122873272529'
#       title: 'Lego Millenium Falcon UCS 75192 Brand New Still in Outer Box '
#       globalId: EBAY-US
#       primaryCategory:
#         categoryId: '19006'
#         categoryName: LEGO Complete Sets & Packs
#       galleryURL: http://thumbs2.ebaystatic.com/m/mpY6T1nWEnTYMdV10OUWNOw/140.jpg
#       viewItemURL: http://www.ebay.com/itm/Lego-Millenium-Falcon-UCS-75192-Brand-New-Still-Outer-Box-/122873272529
#       paymentMethod: PayPal
#       autoPay: 'true'
#       postalCode: H9X1V2
#       location: Canada
#       country: CA
#       shippingInfo:
#         shippingServiceCost: '100.0'
#         shippingType: Flat
#         shipToLocations: Worldwide
#         expeditedShipping: 'false'
#         oneDayShippingAvailable: 'false'
#         handlingTime: '1'
#       sellingStatus:
#         currentPrice: '925.0'  # - This is the sold price
#         convertedCurrentPrice: '925.0'
#         sellingState: EndedWithSales
#       listingInfo:
#         bestOfferEnabled: 'false'
#         buyItNowAvailable: 'false'
#         startTime: '2017-12-21T18:11:43.000Z'
#         endTime: '2017-12-21T20:05:35.000Z'
#         listingType: FixedPrice
#         gift: 'false'
#       returnsAccepted: 'false'
#       condition:
#         conditionId: '1000'
#         conditionDisplayName: New
#       isMultiVariationListing: 'false'
#       topRatedListing: 'false'
#   paginationOutput:
#     pageNumber: '1'
#     entriesPerPage: '100'
#     totalPages: '9'
#     totalEntries: '874'
#  => nil
