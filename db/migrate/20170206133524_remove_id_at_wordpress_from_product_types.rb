class RemoveIdAtWordpressFromProductTypes < ActiveRecord::Migration
  def change
    remove_column :product_types, :id_at_wordpress, :string
  end
end
