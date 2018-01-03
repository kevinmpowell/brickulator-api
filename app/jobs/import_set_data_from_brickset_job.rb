class ImportSetDataFromBricksetJob < ActiveJob::Base
  queue_as :default

  def perform
    import_set_data_from_brickset
  end

  def import_set_data_from_brickset
    set_data = BricksetService.get_sets
    set_data["ArrayOfSets"]["sets"].each do |s|
      lego_set_attributes = BricksetService.transform_set_data_to_attributes(s)
      set = LegoSet.where(number: lego_set_attributes[:number]).first_or_initialize
      set.attributes = lego_set_attributes
      set.save
    end
  end
end
