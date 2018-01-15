class EbayGetSetValueJob < ActiveJob::Base
  queue_as :ebay

  def perform set_id
    get_ebay_values_for_set(set_id)
  end

  def get_ebay_values_for_set set_id
    s = LegoSet.find(set_id)
    
    unless s.nil?
      begin
        ebay_values = EbayService.get_values_for_set(s)
        if !ebay_values.empty?
          ebay_values[:lego_set_id] = s.id
          ebay_values[:retrieved_at] = Time.now
          EbayValue.create(ebay_values)
        end
      rescue Exception => e
        Rails.logger.warn "Ebay Value job failed for set number: #{s.number}-#{s.number_variant} id: #{s.id}"
        raise e
      end
    end

  end
end
