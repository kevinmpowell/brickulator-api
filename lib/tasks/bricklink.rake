namespace :bricklink do
  task :get_all_set_values => :environment do
    BricklinkQueueGetSetValueJobs.perform_later
  end
end
