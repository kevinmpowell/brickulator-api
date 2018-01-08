class BrickOwlGetSetValueJob < ActiveJob::Base
  queue_as :default

  def perform id
    get_brick_owl_values_for_set
  end

  def get_brick_owl_values_for_set set_id
    s = LegoSet.find(id)
    
    unless ls.nil?
      puts "Getting Brick Owl Values for #{s.number}-#{s.number_variant}"
      brick_owl_values = BrickOwlService.get_values_for_set(s)
      if brick_owl_values.empty?
        puts "No BO data to save for #{s.number}-#{s.number_variant}"
      else
        brick_owl_values[:lego_set_id] = s.id
        brick_owl_values[:retrieved_at] = Time.now
        BrickOwlValue.create(brick_owl_values)
      end
    end

  end
end
