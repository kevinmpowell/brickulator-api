# app/lib/ebay_service.rb
require 'nokogiri'
require 'open-uri'

class BricklinkService
  BASE_URL = 'https://www.bricklink.com/catalogPG.asp?S='
  BASE_PART_OUT_URL = 'https://www.bricklink.com/catalogPOV.asp?itemType=S&itemNo='

  def self.c_to_f string
    # Currency string to float
    string.gsub(/~|US|,|\$|[[:space:]]/, "").to_f.round(2)
  end


  def self.get_values_for_set s
    set_number = "#{s.number}-#{s.number_variant}"
    bricklink_values = {}
    url = "#{BASE_URL}#{set_number}"
    # puts url
    doc = Nokogiri::HTML(open(url))
    set_listings = doc.css("table.fv tr:nth-child(4)")

    # NEW Complete Sets
    new_set_data = BricklinkService.get_complete_set_new_values(set_listings)
    bricklink_values = bricklink_values.merge(new_set_data)
    # USED Complete Sets
    used_set_data = BricklinkService.get_complete_set_used_values(set_listings)
    bricklink_values = bricklink_values.merge(used_set_data)

    # NEW Last 6 months sold
    new_set_sold_data = BricklinkService.get_complete_set_last_six_months_sales_new_values(set_listings)
    bricklink_values = bricklink_values.merge(new_set_sold_data)

    # USED Last 6 months sold
    used_set_sold_data = BricklinkService.get_complete_set_last_six_months_sales_used_values(set_listings)
    bricklink_values = bricklink_values.merge(used_set_sold_data)

    used_part_out_data = BricklinkService.get_part_out_values(s, "used")
    bricklink_values = bricklink_values.merge(used_part_out_data)
    
    new_part_out_data = BricklinkService.get_part_out_values(s, "new")
    bricklink_values = bricklink_values.merge(new_part_out_data)

    bricklink_values
  end

  def self.get_part_out_values s, condition="new", minifigs="whole", include_instructions=true, include_box=true, include_extra_parts=true
    data = {}
    condition_query_param = condition == "new" ? "N" : "U"
    minifigs = minifigs == "whole" ? "M" : "P"
    include_instructions = include_instructions ? "Y" : "N"
    include_box = include_box ? "Y" : "N"
    include_extra_parts = include_extra_parts ? "Y" : "N"

    url = "#{BASE_PART_OUT_URL}#{s.number}&itemSeq=#{s.number_variant}&itemQty=1&breakType=#{minifigs}&itemCondition=#{condition_query_param}&incInstr=#{include_instructions}&incBox=#{include_box}&incParts=#{include_extra_parts}"
    doc = Nokogiri::HTML(open(url))
    sales_row = doc.css("#id-main-legacy-table table tr:nth-child(3)")
    data["part_out_value_last_six_months_#{condition}"] = BricklinkService.c_to_f(sales_row.css("td:first-child font[size='3'] b").text)
    data["part_out_value_current_#{condition}"] = BricklinkService.c_to_f(sales_row.css("td:last-child font[size='3'] b").text)
    data
  end

  def self.get_complete_set_new_values set_listings
    data = {}
    current_new_listing_rows = set_listings.css("td:nth-child(3) table:nth-child(3) table tr")
    new_set_prices = []
    current_new_listing_rows.drop(1).each do |r|
      first_column = r.css("td:first-child")
      break if !first_column.attribute("colspan").nil? && first_column.attribute("colspan").value.to_i == 3        

      qty = r.css("td:nth-child(2)").text.to_i
      value = BricklinkService.c_to_f(r.css("td:last-child").text)
      qty.times do 
        new_set_prices << value
      end
    end
    # new_set_prices
    data[:complete_set_new_listings_count] = 0
    unless new_set_prices.empty?
      data[:complete_set_new_listings_count] = new_set_prices.count
      data[:complete_set_new_avg_price] = new_set_prices.mean.round(2)
      data[:complete_set_new_median_price] = new_set_prices.median.round(2)
      data[:complete_set_new_high_price] = new_set_prices.max
      data[:complete_set_new_low_price] = new_set_prices.min
    end
    data
  end

  def self.get_complete_set_last_six_months_sales_new_values set_listings
    data = {}
    sold_new_listing_tables = set_listings.css("td:nth-child(1) table")
    new_set_sold_prices = []

    sold_new_listing_tables.each do |table|
      first_cell = table.css("td:first-child").first
      next if (!first_cell.attribute("colspan").nil? && first_cell.attribute("colspan").value.to_i == 3) || table.attribute("cellpadding").value.to_i == 0
      sold_listing_rows = table.css("table tr")
      sold_listing_rows.drop(1).each do |r|
        first_column = r.css("td:first-child")
        break if !first_column.attribute("colspan").nil? && first_column.attribute("colspan").value.to_i == 3        
        qty = r.css("td:nth-child(2)").text.to_i
        value = BricklinkService.c_to_f(r.css("td:last-child").text)
        qty.times do 
          new_set_sold_prices << value
        end
      end
    end

    data[:complete_set_completed_listing_new_listings_count] = 0
    unless new_set_sold_prices.empty?
      data[:complete_set_completed_listing_new_listings_count] = new_set_sold_prices.count
      data[:complete_set_completed_listing_new_avg_price] = new_set_sold_prices.mean.round(2)
      data[:complete_set_completed_listing_new_median_price] = new_set_sold_prices.median.round(2)
      data[:complete_set_completed_listing_new_high_price] = new_set_sold_prices.max
      data[:complete_set_completed_listing_new_low_price] = new_set_sold_prices.min
    end
    data
  end

  def self.get_complete_set_last_six_months_sales_used_values set_listings
    data = {}
    sold_used_listing_tables = set_listings.css("td:nth-child(2) table")
    used_set_sold_prices = []

    sold_used_listing_tables.each do |table|
      first_cell = table.css("td:first-child").first
      next if (!first_cell.attribute("colspan").nil? && first_cell.attribute("colspan").value.to_i == 3) || table.attribute("cellpadding").value.to_i == 0
      sold_listing_rows = table.css("table tr")
      sold_listing_rows.drop(1).each do |r|
        first_column = r.css("td:first-child")
        break if !first_column.attribute("colspan").nil? && first_column.attribute("colspan").value.to_i == 3        
        qty = r.css("td:nth-child(2)").text.to_i
        value = BricklinkService.c_to_f(r.css("td:last-child").text)
        qty.times do 
          used_set_sold_prices << value
        end
      end
    end

    data[:complete_set_completed_listing_used_listings_count] = 0
    unless used_set_sold_prices.empty?
      data[:complete_set_completed_listing_used_listings_count] = used_set_sold_prices.count
      data[:complete_set_completed_listing_used_avg_price] = used_set_sold_prices.mean.round(2)
      data[:complete_set_completed_listing_used_median_price] = used_set_sold_prices.median.round(2)
      data[:complete_set_completed_listing_used_high_price] = used_set_sold_prices.max
      data[:complete_set_completed_listing_used_low_price] = used_set_sold_prices.min
    end
    data
  end

  def self.get_complete_set_used_values set_listings
    data = {}
    current_new_listing_rows = set_listings.css("td:nth-child(4) table:nth-child(3) table tr")
    used_set_prices = []
    current_new_listing_rows.drop(1).each do |r|
      first_column = r.css("td:first-child")
      break if !first_column.attribute("colspan").nil? && first_column.attribute("colspan").value.to_i == 3        

      qty = r.css("td:nth-child(2)").text.to_i
      value = BricklinkService.c_to_f(r.css("td:last-child").text)
      qty.times do 
        used_set_prices << value
      end
    end
    # used_set_prices
    data[:complete_set_used_listings_count] = 0
    unless used_set_prices.empty?
      data[:complete_set_used_listings_count] = used_set_prices.count
      data[:complete_set_used_avg_price] = used_set_prices.mean.round(2)
      data[:complete_set_used_median_price] = used_set_prices.median.round(2)
      data[:complete_set_used_high_price] = used_set_prices.max
      data[:complete_set_used_low_price] = used_set_prices.min
    end
    data
  end
end
