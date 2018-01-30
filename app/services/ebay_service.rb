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

  def self.get_completed_set_values_uri set_number, page_number=1, condition=nil
    api_uri = "http://svcs.ebay.com/services/search/FindingService/v1?
                      OPERATION-NAME=findCompletedItems&
                      SERVICE-VERSION=1.7.0&
                      SECURITY-APPNAME=#{APP_ID}&
                      RESPONSE-DATA-FORMAT=XML&
                      REST-PAYLOAD&
                      categoryId=#{LEGO_COMPLETE_SET_CATEGORY_ID}&
                      keywords=Lego+#{set_number}&
                      itemFilter(0).name=SoldItemsOnly&
                      itemFilter(0).value=true&
                      sortOrder=PricePlusShippingLowest&
                      paginationInput.entriesPerPage=100&
                      sortOrder=EndTimeSoonest&
                      paginationInput.pageNumber=#{page_number}"
    if !condition.nil?
      # If condition is passed in filter the results from the API based on condition
      condition = condition == "used" ? USED_CONDITION_ID : NEW_CONDITION_ID
      api_url = api_url + "&itemFilter(1).name=Condition
                           &itemFilter(1).value=#{condition}"
    end
    uri = URI.parse(api_uri.gsub(/\s+/, ""))
  end 

  def self.get_values_for_set s
    set_number = s.number_variant.to_i == 1 ? s.number : "#{s.number}-#{s.number_variant}"
    ebay_values = {}

    # Complete Set, Completed Listing Values
    completed_listing_values = get_completed_listing_values_for_set(set_number)
    ebay_values = ebay_values.merge(completed_listing_values)
    ebay_values
  end

  def self.recursively_get_completed_items_paginated_search_results set_number, page_number=1, sold_within=3.months.ago
    result_items = []
    uri = get_completed_set_values_uri(set_number, page_number)
    response = Net::HTTP.get_response(uri)
    search_results = Hash.from_xml(response.body)['findCompletedItemsResponse']
    if search_results['searchResult']['count'].to_i == 1
      # If just one result is returned, it's not in an array so treat it differently
      listing = search_results['searchResult']['item']
      result_items << listing if listing['listingInfo']['endTime'] >= sold_within
    elsif search_results['searchResult']['count'].to_i > 1
      # Array of search results, iterate over it
      result_items = search_results['searchResult']['item'].select{ |l| l['listingInfo']['endTime'] >= sold_within }
    end

    if result_items.empty? || result_items.last['listingInfo']['endTime'] < sold_within
      result_items # If the last of the results on this page is older than the sold_within range, bail out and return the items
    else
      pagination_data = search_results['paginationOutput']
      if pagination_data['pageNumber'] < pagination_data['totalPages']
        new_page = page_number + 1
        result_items + recursively_get_completed_items_paginated_search_results(set_number, new_page)
      else
        result_items
      end
    end
  end

  def self.get_completed_listing_values_for_set set_number
    data = {}

    # TODO: To reduce API calls - query without condition specified, get used & new results mixed and filter out the results when returned
    all_set_results = recursively_get_completed_items_paginated_search_results(set_number)
    used_set_results = all_set_results.select{ |l| !l['condition'].nil? && l['condition']['conditionId'].to_i == USED_CONDITION_ID }
    new_set_results = all_set_results.select{ |l| !l['condition'].nil? && l['condition']['conditionId'].to_i == NEW_CONDITION_ID }

    used_set_prices = used_set_results.map{ |s| s['sellingStatus']['currentPrice'].to_f }.sort
    used_set_time_on_market = used_set_results.map{ |s| TimeDifference.between(DateTime.parse(s['listingInfo']['endTime']), DateTime.parse(s['listingInfo']['startTime'])).in_days }.sort

    new_set_prices = new_set_results.map{ |s| s['sellingStatus']['currentPrice'].to_f }.sort
    new_set_time_on_market = new_set_results.map{ |s| TimeDifference.between(DateTime.parse(s['listingInfo']['endTime']), DateTime.parse(s['listingInfo']['startTime'])).in_days }.sort

    unless used_set_prices.empty?
      # TODO, discard high and low end for better stats?
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
      # TODO, discard high and low end for better stats?
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
