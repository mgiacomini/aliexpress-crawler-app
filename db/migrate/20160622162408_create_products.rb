class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :link
      t.integer :wordpress_id
      t.string :aliexpress_link
      t.integer :option_1
      t.integer :option_2
      t.integer :option_3
      t.integer :shipping

      t.timestamps null: false
    end
  end
end
