class Aliexpress < ActiveRecord::Base
  has_many :crawlers
  validates :name, :email, :password, presence: true
  validates :name, :email, uniqueness: true
end
