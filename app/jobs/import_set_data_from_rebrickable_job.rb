class ImportSetDataFromRebrickableJob < ActiveJob::Base
  queue_as :default

  # def perform
  #   import_set_data_from_rebrickable(1)
  # end

  # def import_set_data_from_rebrickable page=1
  #   set_data = RebrickableService.get_sets(page)
  #   set_data["results"].each do |s|
  #     lego_set_attributes = RebrickableService.transform_set_data_to_attributes(s)
  #     LegoSet.find_or_create_by(lego_set_attributes)
  #   end

  #   unless set_data["next"].nil?
  #     next_page = page + 1
  #     import_set_data_from_rebrickable(next_page)
  #   end
  # end
end
