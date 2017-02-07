class AddOrdersOffsetToCrawler < ActiveRecord::Migration
  def change
    add_column :crawlers, :orders_offset, :integer, default: 0
  end
end
