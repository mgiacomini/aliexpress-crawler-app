class CreateProductTypes < ActiveRecord::Migration
  def change
    create_table :product_types do |t|
      t.string :name
      t.string :aliexpress_link
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
