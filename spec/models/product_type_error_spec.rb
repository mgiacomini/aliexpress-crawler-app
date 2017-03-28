require 'rails_helper'

RSpec.describe ProductTypeError, type: :model do
  it { should belong_to(:product_type) }
end
