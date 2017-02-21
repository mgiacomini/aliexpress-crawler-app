class AddOccurrencesToProductTypeErrors < ActiveRecord::Migration
  def change
    add_column :product_type_errors, :occurrences, :integer, default: 0
  end
end
