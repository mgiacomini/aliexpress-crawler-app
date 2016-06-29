class ProductType < ActiveRecord::Base
  belongs_to :product

  def mobile_link
    link = self.aliexpress_link.gsub("?","/").gsub("_","/").split("/")
    link = link.select{|s| s.include?(".html")}.first
    "https://m.aliexpress.com/item/#{link}"
  end
end
