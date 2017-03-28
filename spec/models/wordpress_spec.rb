require 'rails_helper'

RSpec.describe Wordpress, type: :model do
  it { should have_many(:crawlers).dependent(:destroy) }
  it { should have_many(:products).dependent(:destroy) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:consumer_key) }
  it { should validate_presence_of(:consumer_secret) }
end
