namespace :brickset do
  task :import_all_set_data => :environment do
    import_all_set_data
  end

  task :import_set_data_updates => :environment do
    import_set_data_updates
  end

  def import_all_set_data
    ImportAllSetDataFromBricksetJob.perform_later
  end

  def import_set_data_updates
    ImportSetDataUpdatesFromBricksetJob.perform_later
  end
end
