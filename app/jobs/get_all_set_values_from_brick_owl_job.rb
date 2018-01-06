class GetAllSetValuesFromBrickOwlJob < ActiveJob::Base
  queue_as :default

  def perform
    get_all_set_values_from_brick_owl
  end

  def get_all_set_values_from_brick_owl
    ls = LegoSet.where.not({brick_owl_url: nil}).order({year: "desc", number: "asc", number_variant: "asc"})
    
    ls.each do |s|
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
