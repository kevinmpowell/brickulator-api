class LegoSet < ApplicationRecord
  has_many :ebay_sales, dependent: :destroy

  validates_presence_of :title, :number
end
