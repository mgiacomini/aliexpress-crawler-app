class ProductType < ActiveRecord::Base
  belongs_to :product

  def mobile_link
    link = self.aliexpress_link.gsub("?","/").gsub("_","/").split("/")
    id = link.select{|s| s.include?(".html")}.first
    item = link.select{|s| s.include?("-")}.first
    "https://m.aliexpress.com/item/#{link}"
  end

  def parsed_link
    link = self.aliexpress_link.gsub("?","/").gsub("_","/").split("/")
    id = link.select{|s| s.include?(".html")}.first
    item = link.select{|s| s.include?("-")}.first
    "http://pt.aliexpress.com/item/#{item}/#{id}"
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
