class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
end
