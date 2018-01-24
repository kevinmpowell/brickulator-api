namespace :brickset do
  task :import_all_set_data => :environment do
    ImportAllSetDataFromBricksetJob.perform_later
  end

  task :import_set_data_updates => :environment do
    ImportSetDataUpdatesFromBricksetJob.perform_later
  end
end
