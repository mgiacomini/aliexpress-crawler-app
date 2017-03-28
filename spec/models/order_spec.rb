require 'rails_helper'

RSpec.describe Order, type: :model do

  it { should belong_to(:crawler) }
  it { should validate_presence_of(:wordpress_reference) }
  it { should validate_presence_of(:status) }
  it { should define_enum_for(:status) }

end
