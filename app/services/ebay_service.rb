# app/lib/ebay_service.rb
require 'net/http'
require 'nokogiri'
require 'open-uri'

class EbayService
  APP_ID = ENV['EBAY_APP_ID']
  LEGO_EBAY_CATEGORY_SEARCH_URL = "https://www.ebay.com/sch/19006/i.html?"
  LEGO_COMPLETE_SET_CATEGORY_ID = 19006
  USED_CONDITION_ID = 3000
  NEW_CONDITION_ID = 1000

  def self.c_to_f string
    # Currency string to float
    string.gsub(/~|US|,|\$|[[:space:]]/, "").to_f.round(2)
  end

  # def self.heartbeat condition="used", part_number="75192"
  #   condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
  #   uri = URI.parse("http://svcs.ebay.com/services/search/FindingService/v1?
  #                     OPERATION-NAME=findCompletedItems&
  #                     SERVICE-VERSION=1.7.0&
  #                     SECURITY-APPNAME=#{APP_ID}&
  #                     RESPONSE-DATA-FORMAT=XML&
  #                     REST-PAYLOAD&
  #                     categoryId=#{LEGO_COMPLETE_SET_CATEGORY_ID}&
  #                     keywords=Lego+#{part_number}&
  #                     itemFilter(0).name=Condition&
  #                     itemFilter(0).value=#{condition}&
  #                     itemFilter(1).name=SoldItemsOnly&
  #                     itemFilter(1).value=true&
  #                     sortOrder=PricePlusShippingLowest&
  #                     paginationInput.entriesPerPage=100".gsub(/\s+/, ""))
  #   response = Net::HTTP.get_response(uri)
  #   sets = Hash.from_xml(response.body)
  #   puts sets.to_yaml
  # end

  # def self.get_completed_set_values_uri set_number, page_number=1, condition=nil
  #   api_uri = "http://svcs.ebay.com/services/search/FindingService/v1?
  #                     OPERATION-NAME=findCompletedItems&
  #                     SERVICE-VERSION=1.7.0&
  #                     SECURITY-APPNAME=#{APP_ID}&
  #                     RESPONSE-DATA-FORMAT=XML&
  #                     REST-PAYLOAD&
  #                     categoryId=#{LEGO_COMPLETE_SET_CATEGORY_ID}&
  #                     keywords=Lego+#{set_number}&
  #                     itemFilter(0).name=SoldItemsOnly&
  #                     itemFilter(0).value=true&
  #                     sortOrder=PricePlusShippingLowest&
  #                     paginationInput.entriesPerPage=100&
  #                     sortOrder=EndTimeSoonest&
  #                     paginationInput.pageNumber=#{page_number}"
  #   if !condition.nil?
  #     # If condition is passed in filter the results from the API based on condition
  #     condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
  #     api_url = api_url + "&itemFilter(1).name=Condition
  #                          &itemFilter(1).value=#{condition}"
  #   end
  #   uri = URI.parse(api_uri.gsub(/\s+/, ""))
  # end

  def self.get_current_set_values_uri set_number, condition="used"
    condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
    "#{LEGO_EBAY_CATEGORY_SEARCH_URL}LH_ItemCondition=#{condition}&_nkw=Lego+#{set_number}"
  end

  def self.get_completed_set_values_uri set_number, condition="used"
    condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
    "#{LEGO_EBAY_CATEGORY_SEARCH_URL}LH_ItemCondition=#{condition}&LH_Complete=1&LH_Sold=1&_nkw=Lego+#{set_number}"
  end

  def self.get_values_for_set s
    set_number = s.number_variant.to_i == 1 ? s.number : "#{s.number}-#{s.number_variant}"
    ebay_values = {}

    # Complete Set, Completed Listing Values
    completed_listing_values = get_completed_listing_values_for_set(set_number)
    ebay_values = ebay_values.merge(completed_listing_values)

    # Current Listing Values
    current_listing_values = get_current_listing_values_for_set(set_number)
    ebay_values = ebay_values.merge(current_listing_values)

    ebay_values
  end

  def self.get_current_listing_values_for_set set_number
    data = {}
    used_listings_uri = get_current_set_values_uri(set_number, "used")
    new_listings_uri = get_current_set_values_uri(set_number, "new")

    used_listings_doc = Nokogiri::HTML(open(used_listings_uri))
    used_set_prices = EbayService.extract_prices_from_ebay_html_listings(used_listings_doc)

    if used_set_prices.empty?
      data[:complete_set_used_listings_count] = 0
    else
      data[:complete_set_used_listings_count] = used_set_prices.count
      data[:complete_set_used_avg_price] = used_set_prices.mean.round(2)
      data[:complete_set_used_median_price] = used_set_prices.median.round(2)
      data[:complete_set_used_high_price] = used_set_prices.max
      data[:complete_set_used_low_price] = used_set_prices.min
    end

    new_listings_doc = Nokogiri::HTML(open(new_listings_uri))
    new_set_prices = EbayService.extract_prices_from_ebay_html_listings(new_listings_doc)

    if new_set_prices.empty?
      data[:complete_set_new_listings_count] = 0
    else
      data[:complete_set_new_listings_count] = new_set_prices.count
      data[:complete_set_new_avg_price] = new_set_prices.mean.round(2)
      data[:complete_set_new_median_price] = new_set_prices.median.round(2)
      data[:complete_set_new_high_price] = new_set_prices.max
      data[:complete_set_new_low_price] = new_set_prices.min
    end

    data
  end

  def self.get_completed_listing_values_for_set set_number
    data = {}
    used_listings_uri = get_completed_set_values_uri(set_number, "used")
    new_listings_uri = get_completed_set_values_uri(set_number, "new")

    used_listings_doc = Nokogiri::HTML(open(used_listings_uri))
    used_set_prices = EbayService.extract_prices_from_ebay_html_listings(used_listings_doc)

    if used_set_prices.empty?
      data[:complete_set_used_listings_count] = 0
    else
      data[:complete_set_completed_listing_used_listings_count] = used_set_prices.count
      data[:complete_set_completed_listing_used_avg_price] = used_set_prices.mean.round(2)
      data[:complete_set_completed_listing_used_median_price] = used_set_prices.median.round(2)
      data[:complete_set_completed_listing_used_high_price] = used_set_prices.max
      data[:complete_set_completed_listing_used_low_price] = used_set_prices.min
    end

    new_listings_doc = Nokogiri::HTML(open(new_listings_uri))
    new_set_prices = EbayService.extract_prices_from_ebay_html_listings(new_listings_doc)

    if new_set_prices.empty?
      data[:complete_set_new_listings_count] = 0
    else
      data[:complete_set_completed_listing_new_listings_count] = new_set_prices.count
      data[:complete_set_completed_listing_new_avg_price] = new_set_prices.mean.round(2)
      data[:complete_set_completed_listing_new_median_price] = new_set_prices.median.round(2)
      data[:complete_set_completed_listing_new_high_price] = new_set_prices.max
      data[:complete_set_completed_listing_new_low_price] = new_set_prices.min
    end

    data
  end

  def self.extract_prices_from_ebay_html_listings doc
    prices = []
    listings = doc.css("li[listingid]")
    prev_list_item_number = 0
    unless listings.empty?
      listings.each do |l|
        list_item_number = l['r'].to_i
        if list_item_number > prev_list_item_number
          # Each list item in the search results has a custom attribute called "r", like <li r="1">, <li r="2"> etc.
          # On completed listing searches there are two sets of list items, the completed listings, and promotional current listings
          # The completed listings are first, followed by the promotional current listings, when the promotional current listings are shown the r attribute starts over with r="1"
          # This keeps track of the previous "r" attribute and makes sure to go through the whole list, if the number starts over, we know we're past the completed listings and we can break out of the loop
          prev_list_item_number = list_item_number
          prices << EbayService.c_to_f(l.css(".lvprice .bold").text)
        else
          break
        end
      end
      # prices = listings.map{ |l| EbayService.c_to_f(l.css(".lvprice .bold").text) }
    end

    prices
  end

  # Not using API, scraping instead
  # def self.recursively_get_completed_items_paginated_search_results set_number, page_number=1, sold_within=3.months.ago
  #   result_items = []
  #   uri = get_completed_set_values_uri(set_number, page_number)
  #   response = Net::HTTP.get_response(uri)
  #   search_results = Hash.from_xml(response.body)['findCompletedItemsResponse']
  #   if search_results['searchResult']['count'].to_i == 1
  #     # If just one result is returned, it's not in an array so treat it differently
  #     listing = search_results['searchResult']['item']
  #     result_items << listing if listing['listingInfo']['endTime'] >= sold_within
  #   elsif search_results['searchResult']['count'].to_i > 1
  #     # Array of search results, iterate over it
  #     result_items = search_results['searchResult']['item'].select{ |l| l['listingInfo']['endTime'] >= sold_within }
  #   end

  #   if result_items.empty? || result_items.last['listingInfo']['endTime'] < sold_within
  #     result_items # If the last of the results on this page is older than the sold_within range, bail out and return the items
  #   else
  #     pagination_data = search_results['paginationOutput']
  #     if pagination_data['pageNumber'] < pagination_data['totalPages']
  #       new_page = page_number + 1
  #       result_items + recursively_get_completed_items_paginated_search_results(set_number, new_page)
  #     else
  #       result_items
  #     end
  #   end
  # end

  # def self.get_completed_listing_values_for_set set_number
  #   data = {}

  #   # TODO: To reduce API calls - query without condition specified, get used & new results mixed and filter out the results when returned
  #   all_set_results = recursively_get_completed_items_paginated_search_results(set_number)
  #   used_set_results = all_set_results.select{ |l| !l['condition'].nil? && l['condition']['conditionId'].to_i == USED_CONDITION_ID }
  #   new_set_results = all_set_results.select{ |l| !l['condition'].nil? && l['condition']['conditionId'].to_i == NEW_CONDITION_ID }

  #   used_set_prices = used_set_results.map{ |s| s['sellingStatus']['currentPrice'].to_f }.sort
  #   used_set_time_on_market = used_set_results.map{ |s| TimeDifference.between(DateTime.parse(s['listingInfo']['endTime']), DateTime.parse(s['listingInfo']['startTime'])).in_days }.sort

  #   new_set_prices = new_set_results.map{ |s| s['sellingStatus']['currentPrice'].to_f }.sort
  #   new_set_time_on_market = new_set_results.map{ |s| TimeDifference.between(DateTime.parse(s['listingInfo']['endTime']), DateTime.parse(s['listingInfo']['startTime'])).in_days }.sort

  #   unless used_set_prices.empty?
  #     # TODO, discard high and low end for better stats?
  #     data[:complete_set_completed_listing_used_listings_count] = used_set_prices.count
  #     data[:complete_set_completed_listing_used_avg_price] = used_set_prices.mean.round(2)
  #     data[:complete_set_completed_listing_used_median_price] = used_set_prices.median.round(2)
  #     data[:complete_set_completed_listing_used_high_price] = used_set_prices.max
  #     data[:complete_set_completed_listing_used_low_price] = used_set_prices.min
  #     data[:complete_set_completed_listing_used_time_on_market_low] = used_set_time_on_market.min
  #     data[:complete_set_completed_listing_used_time_on_market_high] = used_set_time_on_market.max
  #     data[:complete_set_completed_listing_used_time_on_market_avg] = used_set_time_on_market.mean.round(1)
  #     data[:complete_set_completed_listing_used_time_on_market_median] = used_set_time_on_market.median.round(1)
  #   end

  #   unless new_set_prices.empty?
  #     # TODO, discard high and low end for better stats?
  #     data[:complete_set_completed_listing_new_listings_count] = new_set_prices.count
  #     data[:complete_set_completed_listing_new_avg_price] = new_set_prices.mean.round(2)
  #     data[:complete_set_completed_listing_new_median_price] = new_set_prices.median.round(2)
  #     data[:complete_set_completed_listing_new_high_price] = new_set_prices.max
  #     data[:complete_set_completed_listing_new_low_price] = new_set_prices.min
  #     data[:complete_set_completed_listing_new_time_on_market_low] = new_set_time_on_market.min
  #     data[:complete_set_completed_listing_new_time_on_market_high] = new_set_time_on_market.max
  #     data[:complete_set_completed_listing_new_time_on_market_avg] = new_set_time_on_market.mean.round(1)
  #     data[:complete_set_completed_listing_new_time_on_market_median] = new_set_time_on_market.median.round(1)
  #   end

  #   data
  # end
end
