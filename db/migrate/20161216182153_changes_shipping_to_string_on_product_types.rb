class ChangesShippingToStringOnProductTypes < ActiveRecord::Migration
  def change
    change_column :product_types, :shipping, :string, default: ''
  end
end
