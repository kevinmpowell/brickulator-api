class EbayQueueGetSetValueJobs < ActiveJob::Base
  queue_as :ebay

  def perform
    ebay_queue_get_set_value_jobs
  end

  def ebay_queue_get_set_value_jobs
    ls = LegoSet.select(:id).where('year >= ?', 2013).order({year: "desc", number: "asc", number_variant: "asc"})
    
    ls.each do |s|
      EbayGetSetValueJob.perform_later(s.id)
    end

  end
end
