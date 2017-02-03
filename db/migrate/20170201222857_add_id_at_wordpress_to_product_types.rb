class AddIdAtWordpressToProductTypes < ActiveRecord::Migration
  def change
    add_column :product_types, :id_at_wordpress, :integer
  end
end
