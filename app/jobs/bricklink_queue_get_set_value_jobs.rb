class BricklinkQueueGetSetValueJobs < ActiveJob::Base
  queue_as :bricklink

  def perform
    bricklink_queue_get_set_value_jobs
  end

  def bricklink_queue_get_set_value_jobs
    ls = LegoSet.select(:id).where('year >= ?', 2013).order({year: "desc", number: "asc", number_variant: "asc"})
    
    ls.each do |s|
      BricklinkGetSetValueJob.perform_later(s.id)
    end

  end
end
