class AddBrickOwlUrlsToSetRecordsJob < ActiveJob::Base
  queue_as :default

  def perform
    add_all_brick_owl_urls_to_set_records
  end

  def add_all_brick_owl_urls_to_set_records
    set_urls = BrickOwlService.get_all_set_urls
    set_urls.each do |url|
      matches = url.scan(BrickOwlService::SET_NUMBER_URL_REGEX)
      matches = matches.first unless matches.nil? # For some reason the resulting matches are in an outer array, remove it
      search_attributes = {
        number: matches.first
      }
      if !matches.last.nil?
        # There is a variant number
        search_attributes[:number_variant] = matches.last
      end

      set = LegoSet.where(search_attributes).first
      if set.nil? 
        puts "NOT FOUND: Cannot find set with set number: #{matches.first}"
      else
        set.update_attributes({brick_owl_url: url})
        puts "#{matches.first} brick owl url: #{url}"
      end
    end
  end
end
