namespace :brickset do
  task :import_set_data => :environment do
    import_set_data
  end

  def import_set_data
    ImportSetDataFromBricksetJob.perform_later
  end
end
