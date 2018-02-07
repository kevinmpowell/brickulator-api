class OpenExchangeRatesGetCurrentExchangeRatesJob < ActiveJob::Base
  queue_as :default

  def perform
    exchange_rates = OpenExchangeRatesService.get_exchange_rates
    ExchangeRate.create({rates: exchange_rates, retrieved_at: Time.now})
  end
end
