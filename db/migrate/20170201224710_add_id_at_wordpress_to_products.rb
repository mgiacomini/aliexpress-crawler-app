class AddIdAtWordpressToProducts < ActiveRecord::Migration
  def change
    add_column :products, :id_at_wordpress, :integer
    remove_column :products, :store
  end
end
