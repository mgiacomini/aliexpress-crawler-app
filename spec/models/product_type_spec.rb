require 'rails_helper'

RSpec.describe ProductType, type: :model do
  it { should have_many(:product_type_errors) }
  it { should belong_to(:product) }
end
