require 'rails_helper'

RSpec.describe LegoSet, type: :model do
  # Association test
  # ensure Todo model has a 1:m relationship with the Item model
  it { should have_many(:ebay_sales).dependent(:destroy) }
  it { should have_many(:brick_owl_values).dependent(:destroy) }
  # Validation tests
  # ensure columns title and created_by are present before saving
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:number) }
  it { should validate_uniqueness_of(:number).scoped_to(:number_variant) }
end
