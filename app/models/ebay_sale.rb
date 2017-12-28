class EbaySale < ApplicationRecord
  belongs_to :lego_set

  validates_presence_of :date
end
