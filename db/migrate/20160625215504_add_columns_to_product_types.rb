class AddColumnsToProductTypes < ActiveRecord::Migration
  def change
    add_column :product_types, :option_1, :integer
    add_column :product_types, :option_2, :integer
    add_column :product_types, :option_3, :integer
    add_column :product_types, :shipping, :integer
  end
end
