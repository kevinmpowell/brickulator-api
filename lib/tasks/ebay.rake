namespace :ebay do
  task :get_all_set_values => :environment do
    EbayQueueGetSetValueJobs.perform_later
  end
end
