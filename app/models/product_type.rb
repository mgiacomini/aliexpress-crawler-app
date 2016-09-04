class ProductType < ActiveRecord::Base
  belongs_to :product

  def parsed_link
    "http://pt.aliexpress.com/item/#{link_item}/#{link_id}"
  end

  def link_id
    process_link[:id]
  end

  def link_item
    process_link[:item]
  end

  def process_link
    link = self.aliexpress_link.gsub("?","/").gsub("_","/").split("/")
    id = link.select{|s| s.include?(".html")}.first
    item = link.select{|s| s.include?("-")}.first

    {id: id,item: item}
  end

  def self.clear_errors(order_items)
    order_items.each do |item|
      item[:product_type].update(product_errors: 0)
    end
  end

  def add_error
    self.update(product_errors: self.product_errors+=1)
  end
end
