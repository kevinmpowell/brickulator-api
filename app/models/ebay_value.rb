class EbayValue < ApplicationRecord
  belongs_to :lego_set

  validates_presence_of :retrieved_at

  after_save :mark_most_recent

  def mark_most_recent
    lego_set.ebay_values.order(:retrieved_at => :desc).update_all({most_recent: false})
    lego_set.ebay_values.order(:retrieved_at => :desc).limit(1).update_all({most_recent: true})
  end
end
