# app/lib/brick_owl_service.rb
require 'nokogiri'
require 'open-uri'

class BrickOwlService
  BRICK_OWL_BASE_URL = "https://www.brickowl.com"
  SET_CATALOG_ROOT_URL = "#{BRICK_OWL_BASE_URL}/catalog/lego-sets"
  INVENTORY_PAGE_URL_SUFFIX = "/inventory"
  SET_NUMBER_URL_REGEX = /-(\d+-*\d+)$/

  def self.spider_set_catalog
    set_urls = self.recursively_scrape_set_links(SET_CATALOG_ROOT_URL, [])
    set_urls.each do |url|
      url.scan(SET_NUMBER_URL_REGEX) do |set_number|
        set = LegoSet.where({number: set_number}).first
        if set.nil? 
          puts "NOT FOUND: Cannot find set with set number: #{set_number}"
        else
          set.update_attributes({brick_owl_url: url})
          puts "#{set_number} brick owl url: #{url}"
        end
      end
    end
  end

  def self.recursively_scrape_set_links url, set_urls
    doc = Nokogiri::HTML(open(url))
    set_links = doc.css(".category-item-name a")
    set_urls = set_urls + set_links.map{ |l| l["href"] }

    puts ("SETS FOUND: #{set_urls.count}")

    next_page_link = doc.css("a[title='Next']")
    if next_page_link.count == 0 #No more next page, return all the urls
      set_urls
    else
      next_page_url = BRICK_OWL_BASE_URL + next_page_link.first["href"]
      self.recursively_scrape_set_links(next_page_url, set_urls)
    end
  end

  def self.scrape_brick_owl_part_out_values
    sets = LegoSet.where("brick_owl_url IS NOT NULL")
    sets.each do |ls|
      retrieve_brick_owl_part_out_value(ls)
    end
  end

  def self.retrieve_brick_owl_part_out_value ls
    if !ls.brick_owl_url.nil?
      url = BRICK_OWL_BASE_URL + ls.brick_owl_url + INVENTORY_PAGE_URL_SUFFIX
      doc = Nokogiri::HTML(open(url))
      part_out_values = doc.css(".inv-warn .price")
      # Currently (Dec 2017), there are four .inv-warn .price elements on the page, they are in order:
      # 1. Parts in new condition (current)
      # 2. Parts in used condition (current)
      # 3. Parts in new condition (past) - don't know what "past" means to Brick Owl yet
      # 4. Parts in used condition (past) - don't know what "past" means to Brick Owl yet
      # Relying on this HTML source order is super brittle, but will work until brickowl changes their site
      if part_out_values.count > 0
        part_out_value_new = nil
        part_out_value_used = nil
        part_out_value_new = part_out_values[0].text.gsub(/US|\$/, "").to_f if !part_out_values[0].nil?
        part_out_value_used = part_out_values[1].text.gsub(/US|\$/, "").to_f if !part_out_values[1].nil?
        BrickOwlValue.create({
          retrieved_at: Time.now,
          part_out_value_new: part_out_value_new,
          part_out_value_used: part_out_value_used,
          lego_set_id: ls.id
        })
      end
    end
  end
end
