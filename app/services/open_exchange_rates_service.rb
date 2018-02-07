# app/lib/brickset_service.rb
require 'net/http'

class OpenExchangeRatesService
  APP_ID = ENV['OPEN_EXCHANGE_RATES_APP_ID']
  BASE_URL = "https://openexchangerates.org/api/"

  def self.get_exchange_rates
    uri = URI.parse("#{BASE_URL}latest.json?app_id=#{APP_ID}&base=USD")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  end
end
