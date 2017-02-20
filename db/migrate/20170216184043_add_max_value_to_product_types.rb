class AddMaxValueToProductTypes < ActiveRecord::Migration
  def change
    add_column :product_types, :max_value, :decimal
  end
end
