class BrickOwlQueueGetSetValueJobs < ActiveJob::Base
  queue_as :default

  def perform
    brick_owl_queue_get_set_value_jobs
  end

  def brick_owl_queue_get_set_value_jobs
    ls = LegoSet.select(:id).where.not({brick_owl_url: nil}).where('year >= ?', 2013).order({year: "desc", number: "asc", number_variant: "asc"})
    
    ls.each do |s|
      BrickOwlGetSetValueJob.perform_later(s.id)
    end

  end
end
