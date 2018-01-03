# app/lib/rebrickable_service.rb
require 'net/http'

class RebrickableService
  # secret to encode and decode token
  API_KEY = ENV['REBRICKABLE_API_KEY']
  SETS_ENDPOINT = 'https://rebrickable.com/api/v3/lego/sets/'

  def self.get_sets(page=1)
    uri = URI.parse("#{SETS_ENDPOINT}?key=#{API_KEY}&page=#{page}")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body) #TODO: Put some error handling here if the response is invalid
  end

  def self.transform_set_data_to_attributes(s)
    {
      title: s["name"],
      number: s["set_num"],
      year: s["year"],
      part_count: s["num_parts"]
    }
  end
end




# Shortcut
#response = Net::HTTP.post_form(uri, {"user[name]" => "testusername", "user[email]" => "testemail@yahoo.com"})

# Full control
