# app/lib/brickset_service.rb
require 'net/http'

class BricksetService
  API_KEY = ENV['BRICKSET_API_KEY']
  TWENTY_FOUR_HOURS_IN_MINUTES = 24*60
  THIRTY_DAYS_IN_MINUTES = TWENTY_FOUR_HOURS_IN_MINUTES * 30
  ONE_YEAR_IN_MINUTES = TWENTY_FOUR_HOURS_IN_MINUTES * 365

  def self.get_sets
    uri = URI.parse("https://brickset.com/api/v2.asmx/getRecentlyUpdatedSets?apiKey=#{API_KEY}&minutesAgo=#{TWENTY_FOUR_HOURS_IN_MINUTES * 2}")
    response = Net::HTTP.get_response(uri)
    sets = Hash.from_xml(response.body)
    sets
  end

  def self.transform_set_data_to_attributes(s)
    {
      title: s["name"],
      number: s["number"],
      year: s["year"],
      part_count: s["pieces"],
      msrp: s["USRetailPrice"].to_f
    }
  end
end
