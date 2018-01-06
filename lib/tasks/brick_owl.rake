namespace :brick_owl do
  task :add_brick_owl_urls_to_sets => :environment do
    add_brick_owl_urls_to_sets
  end
  
  task :add_missing_brick_owl_urls_to_sets => :environment do
    add_missing_brick_owl_urls_to_sets
  end

  task :get_all_set_values_from_brick_owl => :environment do
    get_all_set_values_from_brick_owl
  end

  def add_brick_owl_urls_to_sets
    AddBrickOwlUrlsToSetRecordsJob.perform_later
  end

  def add_missing_brick_owl_urls_to_sets
    AddMissingBrickOwlUrlsToSetsJob.perform_later
  end

  def get_all_set_values_from_brick_owl
    GetAllSetValuesFromBrickOwlJob.perform_later
  end
end
