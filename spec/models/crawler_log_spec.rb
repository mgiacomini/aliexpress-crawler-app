require 'rails_helper'

RSpec.describe CrawlerLog, type: :model do
  it { should belong_to(:crawler) }
end
