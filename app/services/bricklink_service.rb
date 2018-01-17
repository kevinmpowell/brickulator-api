# app/lib/ebay_service.rb
require 'nokogiri'
require 'open-uri'

class BricklinkService
  BASE_URL = 'https://www.bricklink.com/catalogPG.asp?S='

  def self.c_to_f string
    # Currency string to float
    puts string.gsub(/~|US|,|\$/, "")
    string.gsub(/~|US|,|\$/, "").to_f.round(2)
  end


  def self.heartbeat set_number
    url = "#{BASE_URL}#{set_number}"
    puts url
    doc = Nokogiri::HTML(open(url))
    set_listings = doc.css("table.fv tr:nth-child(4)")
    current_new_listing_rows = set_listings.css("td:nth-child(3) table:nth-child(3) table tr")
    # puts current_new_listing_rows

    new_set_prices = []
    current_new_listing_rows.drop(1).each do |r|
      first_column = r.css("td:first-child")
      if !first_column.attribute("colspan").nil? && first_column.attribute("colspan") == 3
        break
      else
        qty = r.css("td:nth-child(2)").text.to_i
        # puts r.css("td:last-child").text
        value = BricklinkService.c_to_f(r.css("td:last-child").text)
        qty.times do 
          new_set_prices << value
        end
      end
    end
    puts new_set_prices.sort.to_yaml
    # puts parsed_values.to_yaml
    # puts table
    # sets = Hash.from_xml(response.body)
    # puts sets.to_yaml
  end
end
