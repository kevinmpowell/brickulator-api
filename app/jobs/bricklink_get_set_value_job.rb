class BricklinkGetSetValueJob < ActiveJob::Base
  queue_as :bricklink

  def perform set_id
    get_bricklink_values_for_set(set_id)
  end

  def get_bricklink_values_for_set set_id
    s = LegoSet.find(set_id)
    
    unless s.nil?
      begin
        bricklink_values = BricklinkService.get_values_for_set(s)
        if !bricklink_values.empty?
          bricklink_values[:lego_set_id] = s.id
          bricklink_values[:retrieved_at] = Time.now
          BricklinkValue.create(bricklink_values)
        end
      rescue Exception => e
        Rails.logger.warn "Bricklink Value job failed for set number: #{s.number}-#{s.number_variant} id: #{s.id}"
        raise e
      end
    end

  end
end
