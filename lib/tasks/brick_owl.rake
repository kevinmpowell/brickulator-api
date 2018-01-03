namespace :brick_owl do
  task :add_brick_owl_urls_to_sets => :environment do
    add_brick_owl_urls_to_sets
  end

  def add_brick_owl_urls_to_sets
    AddBrickOwlUrlsToSetRecordsJob.perform_later
  end
end
