require 'rails_helper'

RSpec.describe Crawler, type: :model do
  it { should have_many(:crawler_logs).dependent(:destroy) }
  it { should have_many(:orders).dependent(:destroy) }
  it { should validate_presence_of(:aliexpress_id) }
  it { should validate_presence_of(:wordpress_id) }
  it { should belong_to(:wordpress) }
  it { should belong_to(:aliexpress) }
end
