namespace :open_exchange_rates do
  task :get_exchange_rates => :environment do
    OpenExchangeRatesGetCurrentExchangeRatesJob.perform_later
  end
end
