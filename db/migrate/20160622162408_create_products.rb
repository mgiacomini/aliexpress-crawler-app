class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :link
      t.integer :wordpress_id
      t.string :aliexpress_link
      t.integer :option_1, default: 1
      t.integer :option_2, default: 1
      t.integer :option_3, default: 1
      t.integer :shipping, default: 1

      t.timestamps null: false
    end
  end
end
