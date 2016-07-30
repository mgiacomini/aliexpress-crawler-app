class AddErrorsToProductType < ActiveRecord::Migration
  def change
    add_column :product_types, :errors, :integer, default: 0
  end
end
