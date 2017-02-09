class AddAndRemoveFieldsFromCrawlers < ActiveRecord::Migration
  def change
    add_column :crawlers, :max_amount_of_orders, :integer, default: 200
    add_column :crawlers, :orders_starting_from_page, :integer, default: 1
    remove_column :crawlers, :orders_offset
  end
end
