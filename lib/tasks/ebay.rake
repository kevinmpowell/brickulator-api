namespace :ebay do
  task :get_all_set_values => :environment do
    get_all_set_values
  end

  def get_all_set_values
    EbayQueueGetSetValueJobs.perform_later
  end
end
