class AddBrickOwlUrlsToSetRecordsJob < ActiveJob::Base
  queue_as :default

  def perform
    add_all_brick_owl_urls_to_set_records
  end

  def add_all_brick_owl_urls_to_set_records
    set_urls = BrickOwlService.get_all_set_urls
    set_urls.each do |url|
      url.scan(BrickOwlService::SET_NUMBER_URL_REGEX) do |set_number|
        set = LegoSet.where({number: set_number}).first
        # TODO: Need to split BrickOwl url into number and number_variant to get better matches
        if set.nil? 
          puts "NOT FOUND: Cannot find set with set number: #{set_number}"
        else
          set.update_attributes({brick_owl_url: url})
          puts "#{set_number} brick owl url: #{url}"
        end
      end
    end
  end
end
