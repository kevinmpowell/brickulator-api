class BrickOwlGetSetValueJob < ActiveJob::Base
  queue_as :brick_owl

  def perform set_id
    get_brick_owl_values_for_set(set_id)
  end

  def get_brick_owl_values_for_set set_id
    s = LegoSet.find(set_id)
    
    unless s.nil?
      begin
        brick_owl_values = BrickOwlService.get_values_for_set(s)
        if !brick_owl_values.empty?
          brick_owl_values[:lego_set_id] = s.id
          brick_owl_values[:retrieved_at] = Time.now
          BrickOwlValue.create(brick_owl_values)
        end
      rescue Exception => e
        Rails.logger.warn "BO Value job failed for set number: #{s.number}-#{s.number_variant} id: #{s.id}"
        raise e
      end
    end

  end
end
