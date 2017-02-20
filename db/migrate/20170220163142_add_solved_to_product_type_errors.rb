class AddSolvedToProductTypeErrors < ActiveRecord::Migration
  def change
    add_column :product_type_errors, :solved, :boolean, default: false
  end
end
