namespace :brick_owl do
  task :add_brick_owl_urls_to_sets => :environment do
    AddBrickOwlUrlsToSetRecordsJob.perform_later
  end
  
  task :add_missing_brick_owl_urls_to_sets => :environment do
    AddMissingBrickOwlUrlsToSetsJob.perform_later
  end

  task :get_all_set_values => :environment do
    BrickOwlQueueGetSetValueJobs.perform_later
  end
end
