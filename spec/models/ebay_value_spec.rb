require 'rails_helper'

RSpec.describe EbayValue, type: :model do
  # Association test
  # ensure an item record belongs to a single todo record
  it { should belong_to(:lego_set) }
  # Validation test
  # ensure column name is present before saving
  it { should validate_presence_of(:retrieved_at) }
end
