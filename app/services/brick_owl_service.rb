# app/lib/brick_owl_service.rb
require 'nokogiri'
require 'open-uri'

class BrickOwlService
  BRICK_OWL_BASE_URL = "https://www.brickowl.com"
  SET_CATALOG_ROOT_URL = "#{BRICK_OWL_BASE_URL}/catalog/lego-sets"
  QUERY_URL = "#{BRICK_OWL_BASE_URL}/search/catalog?query="
  INVENTORY_PAGE_URL_SUFFIX = "/inventory"
  SET_NUMBER_URL_REGEX = /-((?:sdcc)*\d+)(?:-(\d+))*$/

  def self.c_to_f string
    # Currency string to float
    string.gsub(/US|\$/, "").to_f.round(2)
  end

  def self.get_values_for_set s
    brick_owl_values = {}

    # Complete Set Values
    url = "#{BRICK_OWL_BASE_URL}#{s.brick_owl_url}"
    doc = Nokogiri::HTML(open(url))
    complete_set_data = get_complete_set_data(doc)
    brick_owl_values = brick_owl_values.merge(complete_set_data)

    # Part Out Values
    inventory_url = "#{url}#{INVENTORY_PAGE_URL_SUFFIX}"
    part_out_data = get_part_out_values(inventory_url)
    brick_owl_values = brick_owl_values.merge(part_out_data)


    parts_links = doc.css(".associated-buttons a")
    parts_urls = parts_links.reject{ |l| l["href"] == s.brick_owl_url }.map{ |l| l["href"] }
    
    # Instructions Values
    instructions_url = parts_urls.find{ |url| url.include?('instructions') }
    if (instructions_url) 
      instructions_data = get_instructions_data("#{BRICK_OWL_BASE_URL}#{instructions_url}")
      brick_owl_values = brick_owl_values.merge(instructions_data)
    end

    # Packaging Values
    packaging_url = parts_urls.find{ |url| url.include?('packaging') }
    if (packaging_url) 
      packaging_data = get_packaging_data("#{BRICK_OWL_BASE_URL}#{packaging_url}")
      brick_owl_values = brick_owl_values.merge(packaging_data)
    end

    sticker_url = parts_urls.find{ |url| url.include?('sticker') }
    if (sticker_url) 
      sticker_data = get_sticker_data("#{BRICK_OWL_BASE_URL}#{sticker_url}")
      brick_owl_values = brick_owl_values.merge(sticker_data)
    end

    brick_owl_values
  end

  def self.get_sticker_data sticker_url
    data = {}
    doc = Nokogiri::HTML(open(sticker_url))
    prices = []

    listings = doc.css(".buy-table tbody tr")
    if !listings.nil?
      listings.each do |row|
        # Qty for sale is in the 4th column, need to spread prices out so mean and mode can be calculated correctly
        qty_available = row.css("td:nth-child(4)").first.text.to_i
        price = BrickOwlService.c_to_f(row.css("td:nth-child(5) .price").first.text)

        qty_available.times do
          prices << price
        end
      end

      unless prices.empty?
        data[:sticker_listings_count] = prices.count
        data[:sticker_avg_price] = prices.mean.round(2)
        data[:sticker_median_price] = prices.median.round(2)
        data[:sticker_high_price] = prices.max
        data[:sticker_low_price] = prices.min
      end
    end

    data
  end

  def self.get_packaging_data packaging_url
    data = {}
    doc = Nokogiri::HTML(open(packaging_url))
    prices = []

    listings = doc.css(".buy-table tbody tr")
    if !listings.nil?
      listings.each do |row|
        # Qty for sale is in the 4th column, need to spread prices out so mean and mode can be calculated correctly
        qty_available = row.css("td:nth-child(4)").first.text.to_i
        price = BrickOwlService.c_to_f(row.css("td:nth-child(5) .price").first.text)

        qty_available.times do
          prices << price
        end
      end

      unless prices.empty?
        data[:packaging_listings_count] = prices.count
        data[:packaging_avg_price] = prices.mean.round(2)
        data[:packaging_median_price] = prices.median.round(2)
        data[:packaging_high_price] = prices.max
        data[:packaging_low_price] = prices.min
      end
    end

    data
  end

  def self.get_instructions_data instructions_url
    data = {}
    doc = Nokogiri::HTML(open(instructions_url))
    prices = []

    listings = doc.css(".buy-table tbody tr")
    if !listings.nil?
      listings.each do |row|
        # Qty for sale is in the 4th column, need to spread prices out so mean and mode can be calculated correctly
        qty_available = row.css("td:nth-child(4)").first.text.to_i
        price = BrickOwlService.c_to_f(row.css("td:nth-child(5) .price").first.text)

        qty_available.times do
          prices << price
        end
      end

      unless prices.empty?
        data[:instructions_listings_count] = prices.count
        data[:instructions_avg_price] = prices.mean.round(2)
        data[:instructions_median_price] = prices.median.round(2)
        data[:instructions_high_price] = prices.max
        data[:instructions_low_price] = prices.min
      end
    end

    data
  end

  def self.get_part_out_values inventory_url
    data = {}
    doc = Nokogiri::HTML(open(inventory_url))
    part_out_values = doc.css(".inv-warn .price")
    # Currently (Dec 2017), there are four .inv-warn .price elements on the page, they are in order:
    # 1. Parts in new condition (current)
    # 2. Parts in used condition (current)
    # 3. Parts in new condition (past) - don't know what "past" means to Brick Owl yet
    # 4. Parts in used condition (past) - don't know what "past" means to Brick Owl yet
    # Relying on this HTML source order is super brittle, but will work until brickowl changes their site
    if !part_out_values.empty?
      data[:part_out_value_new] = BrickOwlService.c_to_f(part_out_values[0].text) unless part_out_values[0].nil?
      data[:part_out_value_used] = BrickOwlService.c_to_f(part_out_values[1].text) unless part_out_values[1].nil?
    end

    data
  end

  def self.get_complete_set_data doc
    data = {}
    new_set_prices = []
    used_set_prices = []

    listings = doc.css(".buy-table tbody tr")
    if !listings.nil?
      listings.each do |row|
        new_listing = row.css("td:nth-child(2)").first.text.downcase.include?("new")
        # Qty for sale is in the 4th column, need to spread prices out so mean and mode can be calculated correctly
        qty_available = row.css("td:nth-child(4)").first.text.to_i
        price = BrickOwlService.c_to_f(row.css("td:nth-child(5) .price").first.text)

        qty_available.times do
          if new_listing
            new_set_prices << price
          else
            used_set_prices << price
          end 
        end
      end

      unless new_set_prices.empty?
        data[:complete_set_new_listings_count] = new_set_prices.count
        data[:complete_set_new_avg_price] = new_set_prices.mean.round(2)
        data[:complete_set_new_median_price] = new_set_prices.median.round(2)
        data[:complete_set_new_high_price] = new_set_prices.max
        data[:complete_set_new_low_price] = new_set_prices.min
      end

      unless used_set_prices.empty?
        data[:complete_set_used_listings_count] = used_set_prices.count
        data[:complete_set_used_avg_price] = used_set_prices.mean.round(2)
        data[:complete_set_used_median_price] = used_set_prices.median.round(2)
        data[:complete_set_used_high_price] = used_set_prices.max
        data[:complete_set_used_low_price] = used_set_prices.min
      end
    end

    data
  end

  def self.get_new_set_data doc
    new_set_rows = doc.css("")
  end

  def self.find_brick_owl_urls_by_set_number number_with_variant
    url = "#{QUERY_URL}#{number_with_variant}"
    doc = Nokogiri::HTML(open(url))
    set_links = doc.css(".category-item-name a")
    if set_links.count < 60
      set_links.map{ |l| l["href"] }
    else
      []
    end
  end

  def self.get_all_set_urls
    catalog_theme_root_urls = self.get_catalog_urls_by_theme
    set_urls = []
    catalog_theme_root_urls.each do |root_url|
      set_urls = self.recursively_scrape_set_links("#{BRICK_OWL_BASE_URL}#{root_url}", set_urls)
    end
    set_urls
  end

  def self.get_catalog_urls_by_theme
    url = SET_CATALOG_ROOT_URL
    doc = Nokogiri::HTML(open(url))
    catalog_theme_links = doc.css("a[href^='/catalog/lego-sets/']")
    catalog_theme_root_urls = catalog_theme_links.map{ |l| l["href"] }.uniq
    catalog_theme_root_urls
  end

  def self.recursively_scrape_set_links url, set_urls
    doc = Nokogiri::HTML(open(url))
    set_links = doc.css(".category-item-name a")
    set_urls = set_urls + set_links.map{ |l| l["href"] }

    next_page_link = doc.css("a[title='Next']")
    if next_page_link.count == 0 #No more next page, return all the urls
      set_urls
    else
      next_page_url = BRICK_OWL_BASE_URL + next_page_link.first["href"]
      self.recursively_scrape_set_links(next_page_url, set_urls)
    end
  end
end
