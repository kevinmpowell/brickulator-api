# A utility for signing an url using OAuth in a way that's convenient for debugging
# Note: the standard Ruby OAuth lib is here http://github.com/mojodna/oauth
# License: http://gist.github.com/375593
# Usage: see example.rb below

require 'uri'
require 'openssl'
require 'base64'
require 'net/http'

class OauthUtil
  
  attr_accessor :consumer_key, :consumer_secret, :token, :token_secret, :req_method, 
                :sig_method, :oauth_version, :callback_url, :params, :req_url, :base_str
  
  def initialize
    @consumer_key = ENV['BRICKLINK_CONSUMER_KEY']
    @consumer_secret = ENV['BRICKLINK_CONSUMER_SECRET']
    @token = ENV['BRICKLINK_TOKEN_VALUE'] # These are IP Address specific, authorization will start to fail if IP changes
    @token_secret = ENV['BRICKLINK_TOKEN_SECRET'] # These are IP Address specific, authorization will start to fail if IP changes
    @req_method = 'GET'
    @sig_method = 'HMAC-SHA1'
    @oauth_version = '1.0'
    @callback_url = ''
  end
  
  # openssl::random_bytes returns non-word chars, which need to be removed. using alt method to get length
  # ref http://snippets.dzone.com/posts/show/491
  def nonce
    Array.new( 5 ) { rand(256) }.pack('C*').unpack('H*').first
  end
  
  def percent_encode( string )
    # ref http://snippets.dzone.com/posts/show/1260
    return URI.escape( string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]") ).gsub('*', '%2A')
  end
  
  # @ref http://oauth.net/core/1.0/#rfc.section.9.2
  def signature
    key = percent_encode( @consumer_secret ) + '&' + percent_encode( @token_secret )
    # ref: http://blog.nathanielbibler.com/post/63031273/openssl-hmac-vs-ruby-hmac-benchmarks
    digest = OpenSSL::Digest::SHA1.new
    hmac = OpenSSL::HMAC.digest( digest, key, @base_str )
    # ref http://groups.google.com/group/oauth-ruby/browse_thread/thread/9110ed8c8f3cae81
    Base64.encode64( hmac ).chomp.gsub( /\n/, '' )
  end
  
  # sort (very important as it affects the signature), concat, and percent encode
  # @ref http://oauth.net/core/1.0/#rfc.section.9.1.1
  # @ref http://oauth.net/core/1.0/#9.2.1
  # @ref http://oauth.net/core/1.0/#rfc.section.A.5.1
  def query_string
    pairs = []
    @params.sort.each { | key, val | 
      pairs.push( "#{ percent_encode( key ) }=#{ percent_encode( val.to_s ) }" )
    }
    pairs.join '&'
  end
  
  # organize params & create signature
  def auth_values_as_query_string( parsed_url )
    
    @params = {
      'oauth_version' => @oauth_version,
      'oauth_consumer_key' => @consumer_key,
      'oauth_token' => @token,
      'oauth_timestamp' => Time.now.to_i.to_s,
      'oauth_nonce' => nonce,
      'oauth_signature_method' => @sig_method,
    }

    # if url has query, merge key/values into params obj overwriting defaults
    if parsed_url.query
      CGI.parse( parsed_url.query ).each do |k,v|
        if v.is_a?(Array) && v.count == 1
          @params[k] = v.first
        else
          @params[k] = v
        end
      end
    end
    
    # @ref http://oauth.net/core/1.0/#rfc.section.9.1.2
    @req_url = parsed_url.scheme + '://' + parsed_url.host + parsed_url.path
    
    # create base str. make it an object attr for ez debugging
    # ref http://oauth.net/core/1.0/#anchor14
    @base_str = [ 
      @req_method, 
      percent_encode( req_url ), 
      
      # normalization is just x-www-form-urlencoded
      percent_encode( query_string ) 
      
    ].join( '&' )

    # add signature
    @params[ 'oauth_signature' ] = signature
    
    percent_encode(@params.to_json)
    # return self
  end
end


# app/lib/ebay_service.rb
# require 'nokogiri'
# require 'open-uri'

class BricklinkService
  BASE_URL = 'https://www.bricklink.com/catalogPG.asp?S='
  BASE_PART_OUT_URL = 'https://www.bricklink.com/catalogPOV.asp?itemType=S&itemNo='

  def self.c_to_f string
    # Currency string to float
    string.gsub(/~|US|,|\$|[[:space:]]/, "").to_f.round(2)
  end

  def self.get_set_listings set_number='75192-1', condition="new", guide_type="stock"
    condition = condition != "new" ? "U" : "N"
    guide_type = guide_type != "stock" ? "sold" : "stock"
    o = OauthUtil.new

    url = "https://api.bricklink.com/api/store/v1/items/set/#{set_number}/price?new_or_used=#{condition}&guide_type=#{guide_type}";

    parsed_url = URI.parse( url )
    uri = URI.parse("#{url}&Authorization=#{ o.auth_values_as_query_string(parsed_url) }")
    # puts uri.to_s
    response = Net::HTTP.get_response(uri)
    # print response.read_body

    # Net::HTTP.start( parsed_url.host ) { | http |
    #   # o.sign(parsed_url).query_string
    #   request_url = "#{ parsed_url.path }?Authorization=#{ o.auth_values_as_query_string(parsed_url) }"
    #   # puts request_url
    #   req = Net::HTTP::Get.new request_url
    #   response = http.request(req)
    #   print response.read_body
    # }

    # oauth_consumer_key = '4B6681933E744F38929A359C28D5B8D0' # Dummy consumer key, change to yours
    # oauth_nonce = Random.rand(100000).to_s
    # oauth_signature_method = 'HMAC-SHA1'
    # oauth_timestamp = Time.now.to_i.to_s
    # oauth_version = '1.0'

    # url =  "https://api.bricklink.com/api/store/v1/items/set/#{set_number}/price?direction=in&Authorization"

    # parameters = 'oauth_consumer_key=' +
    #               oauth_consumer_key +
    #               '&oauth_nonce=' +
    #               oauth_nonce +
    #               '&oauth_signature_method=' +
    #               oauth_signature_method +
    #               '&oauth_timestamp=' +
    #               oauth_timestamp +
    #               '&oauth_version=' +
    #               oauth_version

    # base_string = 'GET&' + CGI.escape(url) + '&' + CGI.escape(parameters)

    # ## Cryptographic hash function used to generate oauth_signature
    # # by passing the secret key and base string. Note that & has
    # # been appended to the secret key. Don't forget this!
    # #
    # # This line of code is from a SO topic
    # # (http://stackoverflow.com/questions/4084979/ruby-way-to-generate-a-hmac-sha1-signature-for-oauth)
    # # with minor modifications.
    # secret_key = '255E40F67C824E2B8BA90F5E3598BCB0&' # Dummy shared secret, change to yours
    # oauth_signature = CGI.escape(Base64.encode64("#{OpenSSL::HMAC.digest('sha1',secret_key, base_string)}").chomp)

    # testable_url = url + '?' + parameters + '&oauth_signature=' + oauth_signature
    # p testable_url
    set_listings = JSON.parse(response.body)["data"]
    if set_listings.nil?
      nil
    else
      set_listings["price_detail"] 
    end
  end


  def self.get_values_for_set s
    set_number = "#{s.number.strip}-#{s.number_variant.strip}"
    bricklink_values = {}
    # url = "#{BASE_URL}#{set_number}"
    # puts url
    # doc = Nokogiri::HTML(open(url))
    # set_listings = doc.css("table.fv tr:nth-child(4)")

    # NEW Complete Sets
    new_set_data = BricklinkService.get_complete_set_new_values(set_number)
    bricklink_values = bricklink_values.merge(new_set_data)
    # USED Complete Sets
    used_set_data = BricklinkService.get_complete_set_used_values(set_number)
    bricklink_values = bricklink_values.merge(used_set_data)
    # used_set_data = BricklinkService.get_set_listings("used", "stock")
    # bricklink_values = bricklink_values.merge(used_set_data)

    # NEW Last 6 months sold
    new_set_sold_data = BricklinkService.get_complete_set_last_six_months_sales_new_values(set_number)
    bricklink_values = bricklink_values.merge(new_set_sold_data)

    # USED Last 6 months sold
    used_set_sold_data = BricklinkService.get_complete_set_last_six_months_sales_used_values(set_number)
    bricklink_values = bricklink_values.merge(used_set_sold_data)

    # used_part_out_data = BricklinkService.get_part_out_values(s, "used")
    # bricklink_values = bricklink_values.merge(used_part_out_data)
    
    # new_part_out_data = BricklinkService.get_part_out_values(s, "new")
    # bricklink_values = bricklink_values.merge(new_part_out_data)

    bricklink_values
  end

  # def self.get_part_out_values s, condition="new", minifigs="whole", include_instructions=true, include_box=true, include_extra_parts=true
  #   data = {}
  #   condition_query_param = condition == "new" ? "N" : "U"
  #   minifigs = minifigs == "whole" ? "M" : "P"
  #   include_instructions = include_instructions ? "Y" : "N"
  #   include_box = include_box ? "Y" : "N"
  #   include_extra_parts = include_extra_parts ? "Y" : "N"

  #   url = "#{BASE_PART_OUT_URL}#{s.number}&itemSeq=#{s.number_variant}&itemQty=1&breakType=#{minifigs}&itemCondition=#{condition_query_param}&incInstr=#{include_instructions}&incBox=#{include_box}&incParts=#{include_extra_parts}"
  #   doc = Nokogiri::HTML(open(url))
  #   sales_row = doc.css("#id-main-legacy-table table tr:nth-child(3)")
  #   data["part_out_value_last_six_months_#{condition}"] = BricklinkService.c_to_f(sales_row.css("td:first-child font[size='3'] b").text)
  #   data["part_out_value_current_#{condition}"] = BricklinkService.c_to_f(sales_row.css("td:last-child font[size='3'] b").text)
  #   data
  # end

  def self.get_complete_set_new_values set_number
    data = {}
    new_set_prices = []
    current_new_listings = BricklinkService.get_set_listings(set_number, "new", "stock")
    unless current_new_listings.nil? || current_new_listings.empty?
      current_new_listings.each do |l|
        price = BricklinkService.c_to_f(l["unit_price"])
        l["quantity"].times do 
          new_set_prices << price
        end
      end
    end
    # new_set_prices
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

  def self.get_complete_set_used_values set_number
    data = {}
    used_set_prices = []
    current_used_listings = BricklinkService.get_set_listings(set_number, "used", "stock")
    unless current_used_listings.nil? || current_used_listings.empty?
      current_used_listings.each do |l|
        price = BricklinkService.c_to_f(l["unit_price"])
        l["quantity"].times do 
          used_set_prices << price
        end
      end
    end
    # used_set_prices
    if used_set_prices.empty?
      data[:complete_set_used_listings_count] = 0
    else
      data[:complete_set_used_listings_count] = used_set_prices.count
      data[:complete_set_used_avg_price] = used_set_prices.mean.round(2)
      data[:complete_set_used_median_price] = used_set_prices.median.round(2)
      data[:complete_set_used_high_price] = used_set_prices.max
      data[:complete_set_used_low_price] = used_set_prices.min
    end
    data
  end

  def self.get_complete_set_last_six_months_sales_new_values set_number
    data = {}
    new_set_prices = []
    current_new_listings = BricklinkService.get_set_listings(set_number, "new", "sold")
    unless current_new_listings.nil? || current_new_listings.empty?
      current_new_listings.each do |l|
        price = BricklinkService.c_to_f(l["unit_price"])
        l["quantity"].times do 
          new_set_prices << price
        end
      end
    end
    # new_set_prices
    if new_set_prices.empty?
      data[:complete_set_completed_listing_new_listings_count] = 0
    else
      data[:complete_set_completed_listing_new_listings_count] = new_set_prices.count
      data[:complete_set_completed_listing_new_avg_price] = new_set_prices.mean.round(2)
      data[:complete_set_completed_listing_new_median_price] = new_set_prices.median.round(2)
      data[:complete_set_completed_listing_new_high_price] = new_set_prices.max
      data[:complete_set_completed_listing_new_low_price] = new_set_prices.min
    end
    data
  end

  def self.get_complete_set_last_six_months_sales_used_values set_number
    data = {}
    used_set_prices = []
    current_used_listings = BricklinkService.get_set_listings(set_number, "used", "sold")
    unless current_used_listings.nil? || current_used_listings.empty?
      current_used_listings.each do |l|
        price = BricklinkService.c_to_f(l["unit_price"])
        l["quantity"].times do 
          used_set_prices << price
        end
      end
    end
    # used_set_prices
    if used_set_prices.empty?
      data[:complete_set_completed_listing_used_listings_count] = 0
    else
      data[:complete_set_completed_listing_used_listings_count] = used_set_prices.count
      data[:complete_set_completed_listing_used_avg_price] = used_set_prices.mean.round(2)
      data[:complete_set_completed_listing_used_median_price] = used_set_prices.median.round(2)
      data[:complete_set_completed_listing_used_high_price] = used_set_prices.max
      data[:complete_set_completed_listing_used_low_price] = used_set_prices.min
    end
    data
  end

  # def self.get_complete_set_last_six_months_sales_used_values set_listings
  #   data = {}
  #   sold_used_listing_tables = set_listings.css("td:nth-child(2) table")
  #   used_set_sold_prices = []

  #   sold_used_listing_tables.each do |table|
  #     first_cell = table.css("td:first-child").first
  #     next if (!first_cell.attribute("colspan").nil? && first_cell.attribute("colspan").value.to_i == 3) || table.attribute("cellpadding").value.to_i == 0
  #     sold_listing_rows = table.css("table tr")
  #     sold_listing_rows.drop(1).each do |r|
  #       first_column = r.css("td:first-child")
  #       break if !first_column.attribute("colspan").nil? && first_column.attribute("colspan").value.to_i == 3        
  #       qty = r.css("td:nth-child(2)").text.to_i
  #       value = BricklinkService.c_to_f(r.css("td:last-child").text)
  #       qty.times do 
  #         used_set_sold_prices << value
  #       end
  #     end
  #   end

  #   data[:complete_set_completed_listing_used_listings_count] = 0
  #   unless used_set_sold_prices.empty?
  #     data[:complete_set_completed_listing_used_listings_count] = used_set_sold_prices.count
  #     data[:complete_set_completed_listing_used_avg_price] = used_set_sold_prices.mean.round(2)
  #     data[:complete_set_completed_listing_used_median_price] = used_set_sold_prices.median.round(2)
  #     data[:complete_set_completed_listing_used_high_price] = used_set_sold_prices.max
  #     data[:complete_set_completed_listing_used_low_price] = used_set_sold_prices.min
  #   end
  #   data
  # end

  # def self.get_complete_set_used_values set_listings
  #   data = {}
  #   current_new_listing_rows = set_listings.css("td:nth-child(4) table:nth-child(3) table tr")
  #   used_set_prices = []
  #   current_new_listing_rows.drop(1).each do |r|
  #     first_column = r.css("td:first-child")
  #     break if !first_column.attribute("colspan").nil? && first_column.attribute("colspan").value.to_i == 3        

  #     qty = r.css("td:nth-child(2)").text.to_i
  #     value = BricklinkService.c_to_f(r.css("td:last-child").text)
  #     qty.times do 
  #       used_set_prices << value
  #     end
  #   end
  #   # used_set_prices
  #   data[:complete_set_used_listings_count] = 0
  #   unless used_set_prices.empty?
  #     data[:complete_set_used_listings_count] = used_set_prices.count
  #     data[:complete_set_used_avg_price] = used_set_prices.mean.round(2)
  #     data[:complete_set_used_median_price] = used_set_prices.median.round(2)
  #     data[:complete_set_used_high_price] = used_set_prices.max
  #     data[:complete_set_used_low_price] = used_set_prices.min
  #   end
  #   data
  # end
end
