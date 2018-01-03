# app/lib/brickset_service.rb
require 'net/http'

class BricksetService
  API_KEY = ENV['BRICKSET_API_KEY']

  def self.get_sets_for_year year=2018
    uri = URI.parse("https://brickset.com/api/v2.asmx/getSets?apiKey=aVIg-VKan-SSCw&userHash=&query=&theme=&subtheme=&setNumber=&owned=&wanted=&orderBy=&pageNumber=1&userName=&year=#{year}&pageSize=5000")
    response = Net::HTTP.get_response(uri)
    sets = Hash.from_xml(response.body)
    sets["ArrayOfSets"]["sets"]
  end

  def self.transform_set_data_to_attributes(s)
    {
      title: s["name"],
      number: s["number"],
      year: s["year"],
      part_count: s["pieces"],
      msrp: s["USRetailPrice"].to_f,
      number_variant: s["numberVariant"],
      brickset_url: s["bricksetURL"],
      minifig_count: s["minifigs"].to_i,
      released: s["released"].to_s == "true",
      packaging_type: s["packagingType"],
      instructions_count: s["instructionsCount"].to_i
    }
  end
end
