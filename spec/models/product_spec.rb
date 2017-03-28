require 'rails_helper'

RSpec.describe Product, type: :model do
  it { should have_many(:product_types).dependent(:destroy) }
  it { should belong_to(:wordpress) }
end
