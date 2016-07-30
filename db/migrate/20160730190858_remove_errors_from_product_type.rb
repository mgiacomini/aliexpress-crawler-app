class RemoveErrorsFromProductType < ActiveRecord::Migration
  def change
    remove_column :product_types, :errors, :integer
  end
end
