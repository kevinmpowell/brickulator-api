require 'rails_helper'

RSpec.describe BrickOwlValue, type: :model do
  it { should validate_presence_of(:retrieved_at) }
end
