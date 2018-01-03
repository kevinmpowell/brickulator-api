class ImportAllSetDataFromBricksetJob < ActiveJob::Base
  queue_as :default

  def perform
    import_all_set_data_from_brickset
  end

  def import_all_set_data_from_brickset
    recursively_import_set_data_from_brickset_for_year(2018, 0)
  end

  def recursively_import_set_data_from_brickset_for_year year, counter
    bail_out_after = 80
    if (counter < bail_out_after)
      set_data = BricksetService.get_sets_for_year(year)
      if set_data.nil?
        puts "ERROR: No set data pulled from Brickset for #{year}"
      else
        set_data.each do |s|
          lego_set_attributes = BricksetService.transform_set_data_to_attributes(s)
          set = LegoSet.where(number: lego_set_attributes[:number]).first_or_initialize
          set.attributes = lego_set_attributes
          set.save
        end
      end

      next_year = year - 1
      counter = counter + 1
      recursively_import_set_data_from_brickset_for_year(next_year, counter)
    end
  end
end
