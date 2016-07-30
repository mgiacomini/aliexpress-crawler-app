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

  def add_error
    self.update(product_errors: self.product_errors+=1)
  end

  def self.clear_errors product_type
    product_type.update(product_errors: 0)
  end
end
