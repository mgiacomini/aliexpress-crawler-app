class AddProductErrorsToProductType < ActiveRecord::Migration
  def change
    add_column :product_types, :product_errors, :integer
  end
end
