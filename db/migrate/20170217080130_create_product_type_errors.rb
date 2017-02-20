class CreateProductTypeErrors < ActiveRecord::Migration
  def change
    create_table :product_type_errors do |t|
      t.references :product_type, index: true, foreign_key: true
      t.text :message

      t.timestamps null: false
    end
  end
end
