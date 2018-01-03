class LegoSet < ApplicationRecord
  has_many :ebay_sales, dependent: :destroy
  has_many :brick_owl_values, dependent: :destroy

  validates_presence_of :title, :number
  validates_uniqueness_of :number, scope: :number_variant
end
