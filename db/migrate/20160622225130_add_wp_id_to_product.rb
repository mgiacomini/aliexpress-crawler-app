class AddWpIdToProduct < ActiveRecord::Migration
  def change
    add_column :products, :wordpress_id, :integer
  end
end
