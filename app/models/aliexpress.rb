class Aliexpress < ActiveRecord::Base
  has_many :crawlers, dependent: :destroy
  validates :name, :email, :password, presence: true
  validates :name, :email, uniqueness: true
end
