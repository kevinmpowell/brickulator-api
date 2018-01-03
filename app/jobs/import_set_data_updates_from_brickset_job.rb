class ImportSetDataUpdatesFromBricksetJob < ActiveJob::Base
  queue_as :default

  def perform
    import_set_data_updates_from_brickset
  end

  def import_set_data_updates_from_brickset
    set_data = BricksetService.get_all_sets_updated_in_the_last_x_hours(ENV['BRICKSET_NIGHTLY_UPDATE_WINDOW_HOURS'])
    if set_data.nil?
      puts "ERROR: No set updates pulled"
    else
      set_data.each do |s|
        lego_set_attributes = BricksetService.transform_set_data_to_attributes(s)
        set = LegoSet.where(number: lego_set_attributes[:number]).first_or_initialize
        set.attributes = lego_set_attributes
        set.save
      end
    end
  end
end
