class RemoveColumnsFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :option_1, :integer
    remove_column :products, :option_2, :integer
    remove_column :products, :option_3, :integer
    remove_column :products, :shipping, :integer
    remove_column :products, :aliexpress_link, :integer
    remove_column :products, :type, :integer
  end
end
