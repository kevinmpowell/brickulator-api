class AddMissingBrickOwlUrlsToSetsJob < ActiveJob::Base
  queue_as :default

  def perform
    add_missing_brick_owl_urls_to_sets
  end

  def add_missing_brick_owl_urls_to_sets
    ls = LegoSet.select(:id, :packaging_type, :number, :number_variant).where({brick_owl_url: nil}).where.not({packaging_type: ['{Not specified}', 'Blister pack', 'Other', 'None (loose parts)']})
    
    ls.each do |s|
      number_with_variant = s.number
      number_with_variant = "#{number_with_variant}-#{s.number_variant}" unless s.number_variant.nil?
      urls = BrickOwlService.find_brick_owl_urls_by_set_number(number_with_variant)
      
      if !urls.empty?
        update_lego_set_with_brick_owl_url(urls, s)
      else
        puts "NO BRICK OWL URLS FOUND FOR #{number_with_variant}"
      end
    
    end

  end

  def update_lego_set_with_brick_owl_url urls, s
    urls.each do |url|  
      puts "Attempting to match #{s.number}-#{s.number_variant} to #{url}"
      matches = url.scan(BrickOwlService::SET_NUMBER_URL_REGEX)
      
      if !matches.empty?
        matches = matches.first # For some reason the resulting matches are in an outer array, remove it
        number = matches[0]
        number_variant = matches[1] unless matches[1].nil?
        
        puts number
        puts s.number
        if number == s.number || number == s.number.gsub(/\D/, '') || number == s.number.downcase
          if s.number_variant.nil? || s.number_variant == "1" || s.number_variant == number_variant
            s = LegoSet.find(s.id)
            s.update_attributes({brick_owl_url: url})
            puts "SUCCESS: #{s.number}-#{s.number_variant} Brick owl url added: #{url}"
          end
        end

      end

    end

  end


end
