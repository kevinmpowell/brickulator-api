class BrickOwlValue < ApplicationRecord
  belongs_to :lego_set

  validates_presence_of :retrieved_at
end
