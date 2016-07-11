class ProductType < ActiveRecord::Base
  belongs_to :product

  def mobile_link
    link = self.aliexpress_link.gsub("?","/").gsub("_","/").split("/")
    link = link.select{|s| s.include?(".html")}.first
    "https://m.aliexpress.com/item/#{link}"
  end

  def type
    link = self.aliexpress_link.gsub("?","/").split("/")
    link = link.select{|s| s.include?(".html")}.first
    if link.include?("_")
      "mobile"
    else
      "desktop"
    end
  end
end
